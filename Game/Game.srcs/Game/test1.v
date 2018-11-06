`default_nettype none

module test1
(
  input  wire        CLK100MHZ,
  input  wire [4:0]  BTN,
  input  wire [15:0] SW,
  output wire [6:0]  SG,
  output wire [7:0]  AN,
  output wire [15:0] LED,
  output wire        VGA_HS,
  output wire        VGA_VS,
  output reg  [3:0]  VGA_R,
  output reg  [3:0]  VGA_G,
  output reg  [3:0]  VGA_B
);
  wire w_vclk;
  CLK40MHZ clk (w_vclk, CLK100MHZ);

  wire [10:0] w_display_x;
  wire [10:0] w_display_y;
  wire        w_display_active;
  wire        w_display_reset;

  assign w_display_reset = 0;

  m_vga display
  (
    .iw_clock (w_vclk),
    .iw_rst   (w_display_reset),
    .ow_hs    (VGA_HS),
    .ow_vs    (VGA_VS),
    .ow_x     (w_display_x),
    .ow_y     (w_display_y),
    .ow_activ (w_display_active)
  );

  // VRAM
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19;
  localparam VRAM_DATA_WIDTH = 8;

  reg  [VRAM_ADDR_WIDTH - 1:0] r_vram_address;
  reg  [VRAM_DATA_WIDTH - 1:0] r_vram_datain;
  wire [VRAM_DATA_WIDTH - 1:0] w_vram_dataout;
  reg                          r_vram_write = 0;

  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH),
    .MEMFILE    ("")
  )
  vram0
  (
    .iw_addr  (r_vram_address),
    .iw_clock (CLK100MHZ),
    .iw_write (r_vram_write),
    .or_data  (w_vram_dataout),
    .iw_data  (r_vram_datain)
  );

  // Sprite data
  localparam SPRITE_SIZE = 32;
  localparam SPRITE_COUNT = 8;
  localparam SPRITE_DATA_WIDTH = 8;
  localparam SPRITE_DEPTH = SPRITE_SIZE * SPRITE_SIZE * SPRITE_COUNT;
  localparam SPRITE_ADDR_WIDTH = 13;

  reg  [SPRITE_DATA_WIDTH - 1:0] r_sprite_address;
  wire [SPRITE_DATA_WIDTH - 1:0] w_sprite_dataout;

  // Sprite memory
  m_sram
  #(
    .ADDR_WIDTH (SPRITE_ADDR_WIDTH),
    .DATA_WIDTH (SPRITE_DATA_WIDTH),
    .DEPTH      (SPRITE_DEPTH),
    .MEMFILE    ("sprites.mem")
  )
  vram
  (
    .iw_addr  (r_sprite_address),
    .iw_clock (CLK100MHZ),
    .iw_write (0),
    .or_data  (w_sprite_dataout),
    .iw_data  (0)
  );

  reg [11:0] r_sprite_palette [0:255];
  reg [11:0] r_vga_out;
  initial
  begin
    $display("Loading sprite r_sprite_palette.");
    $readmemh("sprites_palette.mem", r_sprite_palette);
  end

  // Sprites to load and positions for the player
  localparam SPRITE_BACKGROUND_INDEX  = 7;
  localparam SPRITE_PLAYER_INDEX      = 0;
  localparam SPRITE_BACKGROUND_OFFSET = SPRITE_BACKGROUND_INDEX * SPRITE_SIZE * SPRITE_SIZE;
  localparam SPRITE_PLAYER_OFFSET     = SPRITE_PLAYER_INDEX * SPRITE_SIZE * SPRITE_SIZE;
  localparam SPRITE_PLAYER_INIT_X     = DISPLAY_WIDTH - SPRITE_SIZE >> 1;
  localparam SPRITE_PLAYER_INIT_Y     = DISPLAY_HEIGHT - SPRITE_SIZE;

  // Draw to VRAM
  reg [10:0] r_vram_x = 0;
  reg [10:0] r_vram_y = 0;
  reg [10:0] r_player_x = SPRITE_PLAYER_INIT_X;
  reg [10:0] r_player_y = SPRITE_PLAYER_INIT_Y;

  // counter
  reg [3:0] r_count;

  always @ (posedge CLK100MHZ)
  begin
    r_vram_write = ~r_vram_write;
    r_count <= r_count + 1;
    // Draw background
    if (r_vram_write && (r_count < 5))
    begin
      r_sprite_address <= SPRITE_BACKGROUND_OFFSET + 8 * (w_display_y % SPRITE_SIZE) * SPRITE_SIZE + (w_display_x % SPRITE_SIZE);
      r_vram_datain <= w_sprite_dataout;
    end

    // // Draw player
    // if (r_vram_write && (r_count >= 5))
    // begin
    //   if ((w_display_x <= (r_player_x + SPRITE_SIZE)) && (w_display_x >= r_player_x) &&
    //       (w_display_y <= (r_player_y + SPRITE_SIZE)) && (w_display_y >= r_player_y))
    //   begin
    //     r_sprite_address <= SPRITE_PLAYER_OFFSET + 8 * (w_display_y % SPRITE_SIZE) * SPRITE_SIZE + (w_display_x % SPRITE_SIZE);
    //     r_vram_datain <= w_sprite_dataout;
    //   end
    // end

    // Player control
    if (BTN[4] && r_player_x < DISPLAY_WIDTH - SPRITE_SIZE)
      r_player_x <= r_player_x + 1;
    if (BTN[1] && r_player_x > 0)
      r_player_x <= r_player_x - 1;
    if (BTN[3] && r_player_y < DISPLAY_HEIGHT - SPRITE_SIZE)
      r_player_y <= r_player_y + 1;
    if (BTN[2] && r_player_y > 0)
      r_player_y <= r_player_y - 1;

    // VGA output
    r_vram_address <= w_display_y * DISPLAY_WIDTH + w_display_x;
    if (w_display_active && ~r_vram_write)
      r_vga_out <= r_sprite_palette[w_vram_dataout];
    else if (w_display_active && r_vram_write)
      r_vga_out <= r_vga_out;
    else
      r_vga_out <= 0;
    VGA_R <= r_vga_out[11:8];
    VGA_G <= r_vga_out[7:4];
    VGA_B <= r_vga_out[3:0];
  end
endmodule
