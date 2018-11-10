module m_entity
#(parameter
  ADDR_WIDTH  = 8,
  DATA_WIDTH  = 8,
  ENTITY_SIZE = 32,
  MEMFILE     = ""
)
(
  input  wire                    iw_clock,
  input  wire [9:0]             iw_draw_x,
  input  wire [9:0]             iw_draw_y,
  input  wire [9:0]             iw_pos_x,
  input  wire [9:0]             iw_pos_y,
  output wire                    ow_draw,
  output reg  [DATA_WIDTH - 1:0] or_data
);
  wire [ADDR_WIDTH - 1:0] w_address;
  wire [DATA_WIDTH - 1:0] w_data;

  m_sram
  #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (ENTITY_SIZE * ENTITY_SIZE),
    .MEMFILE    (MEMFILE)
  )
  data
  (
    .iw_clock   (iw_clock),
    .iw_addr    (w_address),
    .iw_write   (0),
    .or_data    (w_data),
    .iw_data    (0)
  );

  assign ow_draw = (((iw_pos_x <= iw_draw_x) && (iw_draw_x < iw_pos_x + ENTITY_SIZE)) &&
                    ((iw_pos_y <= iw_draw_y) && (iw_draw_y < iw_pos_y + ENTITY_SIZE)));
  assign w_address = (ow_draw) ? ((iw_draw_y - iw_pos_y) * ENTITY_SIZE + (iw_draw_x - iw_pos_x)) : 0;
  always @(posedge iw_clock) or_data <= w_data;
endmodule

/******************************************************************************/

module m_entity_test
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
  //reg CLK100MHZ = 0;
  CLK40MHZ clk (w_vclk, CLK100MHZ);

  //initial forever #2 w_vclk = ~w_vclk;
  //initial forever #1 CLK100MHZ = ~CLK100MHZ;

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
    .ow_active (w_display_active)
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
  vram
  (
    .iw_addr  (r_vram_address),
    .iw_clock (CLK100MHZ),
    .iw_write (r_vram_write),
    .or_data  (w_vram_dataout),
    .iw_data  (r_vram_datain)
  );

  reg [10:0] r_pos_x = 400, r_pos_y = 300;
  wire w_draw;
  wire [VRAM_DATA_WIDTH - 1:0] w_data;

  m_entity
  #(
    .ADDR_WIDTH  (VRAM_ADDR_WIDTH),
    .DATA_WIDTH  (VRAM_DATA_WIDTH),
    .ENTITY_SIZE (32),
    .MEMFILE("fighter.mem")
  )
  player
  (
    .iw_clock  (CLK100MHZ),
    .iw_draw_x (w_display_x),
    .iw_draw_y (w_display_y),
    .iw_pos_x  (r_pos_x),
    .iw_pos_y  (r_pos_y),
    .ow_draw   (w_draw),
    .or_data   (w_data)
  );

  reg [11:0] r_sprite_palette [0:255];
  reg [11:0] r_vga_out;
  initial
  begin
    $display("Loading sprite r_sprite_palette.");
    $readmemh("fighter_palette.mem", r_sprite_palette);
  end

  reg [20:0] r_i = 0;
  always @(posedge CLK100MHZ)
  begin
    r_i <= r_i + 1;
    if(r_i == 0)
    begin
      // Player control
      if (BTN[3] && r_pos_x < DISPLAY_WIDTH - 32)
        r_pos_x <= r_pos_x + 1;
      if (BTN[2] && r_pos_x > 0)
        r_pos_x <= r_pos_x - 1;
      if (BTN[4] && r_pos_y < DISPLAY_HEIGHT - 32)
        r_pos_y <= r_pos_y + 1;
      if (BTN[1] && r_pos_y > 0)
        r_pos_y <= r_pos_y - 1;
    end

    r_vram_address <= w_display_y * DISPLAY_WIDTH + w_display_x;

    // Draw Player
    if (w_draw)
    begin
      r_vram_write <= 1;
      r_vram_datain <= w_data;
    end
    else
      r_vram_write <= 0;

    // Draw from VRAM
    if (w_display_active)
      r_vga_out <= r_sprite_palette[w_vram_dataout];
    else
      r_vga_out <= 0;
    VGA_R <= r_vga_out[11:8];
    VGA_G <= r_vga_out[7:4];
    VGA_B <= r_vga_out[3:0];
  end
endmodule
