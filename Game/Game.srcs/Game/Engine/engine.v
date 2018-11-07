module m_engine
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
  /****************************************************************************/
  // Simulation
  /****************************************************************************/
  // reg CLK100MHZ = 0, r_display_clock = 0;
  // initial forever #1 CLK100MHZ = ~CLK100MHZ;
  // initial forever #2 r_display_clock = ~r_display_clock;
  //
  // assign w_display_clock = r_display_clock;
  /****************************************************************************/

  /****************************************************************************/
  // Display
  /****************************************************************************/
  wire        w_display_clock;
  wire [10:0] w_display_x;
  wire [10:0] w_display_y;
  wire        w_display_active;
  wire        w_display_reset;
  wire        w_display_frame;
  reg  [11:0] r_display_out;

  CLK40MHZ display_clock (w_display_clock, CLK100MHZ);
  assign w_display_reset = SW[15];
  always @ (posedge w_display_clock)
  begin
    if (w_display_active)
    begin
      VGA_R <= r_display_out[11:8];
      VGA_G <= r_display_out[7:4];
      VGA_B <= r_display_out[3:0];
    end
    else
    begin
      VGA_R <= 0;
      VGA_G <= 0;
      VGA_B <= 0;
    end
  end

  m_vga display
  (
    .iw_clock  (w_display_clock),
    .iw_rst    (w_display_reset),
    .ow_hs     (VGA_HS),
    .ow_vs     (VGA_VS),
    .ow_x      (w_display_x),
    .ow_y      (w_display_y),
    .ow_active (w_display_active),
    .ow_frame  (w_display_frame)
  );
  /****************************************************************************/

  /****************************************************************************/
  // VRAM
  /****************************************************************************/
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19;
  localparam VRAM_DATA_WIDTH = 4;

  reg  [VRAM_ADDR_WIDTH - 1:0] r_vram_address;
  wire [VRAM_DATA_WIDTH - 1:0] w_vram0_dataout, w_vram1_dataout;
  reg  [VRAM_DATA_WIDTH - 1:0] r_vram_datain;
  reg                          r_vram_write = 0;

  always @(posedge w_display_clock)
  begin
    r_vram_address <= w_display_y * DISPLAY_WIDTH + w_display_x;
    // Display content of active VRAM
    r_display_out = (r_vram_write) ? w_vram1_dataout : w_vram0_dataout;
  end

  // At the end of every frame switch buffers.
  always @(posedge w_display_frame)
    r_vram_write = ~r_vram_write;

  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH)
  )
  vram0
  (
    .iw_addr  (r_vram_address),
    .iw_clock (w_display_clock),
    .iw_write (r_vram_write),
    .or_data  (w_vram0_dataout),
    .iw_data  (r_vram_datain)
  );

  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH)
  )
  vram1
  (
    .iw_addr  (r_vram_address),
    .iw_clock (w_display_clock),
    .iw_write (!r_vram_write),
    .or_data  (w_vram1_dataout),
    .iw_data  (r_vram_datain)
  );
  /****************************************************************************/

  /****************************************************************************/
  // Game Logic
  /****************************************************************************/
  reg [10:0] r_player_x = 400, r_player_y = 300;
  wire w_player_draw;
  wire [VRAM_DATA_WIDTH - 1:0] w_player_dataout;

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
    .iw_pos_x  (r_player_x),
    .iw_pos_y  (r_player_y),
    .ow_draw   (w_player_draw),
    .or_data   (w_player_dataout)
  );

  reg [11:0] r_player_palette [0:255];
  initial
  begin
    $display("Loading sprite r_player_palette.");
    $readmemh("fighter_palette.mem", r_player_palette);
  end

  reg [20:0] r_i = 0;
  always @(posedge CLK100MHZ)
  begin
    // Player control
    r_i <= r_i + 1;
    if(r_i == 0)
    begin
      if (BTN[3] && r_player_x < DISPLAY_WIDTH - 32)
        r_player_x <= r_player_x + 1;
      if (BTN[2] && r_player_x > 0)
        r_player_x <= r_player_x - 1;
      if (BTN[4] && r_player_y < DISPLAY_HEIGHT - 32)
        r_player_y <= r_player_y + 1;
      if (BTN[1] && r_player_y > 0)
        r_player_y <= r_player_y - 1;
    end

    // Player draw
    if      (w_player_draw) r_vram_datain <= w_player_dataout;
    else                    r_vram_datain <= 12'b111111111111;
  end

  // RNG
  wire [15:0] w_random_16bit;
  wire        w_generate;
  m_rng_16bit rng (CLK100MHZ, w_random_16bit, w_generate);  

  // Enemy
  reg [11:0] r_enemy_color;
  reg [29:0] r_enemy_color_counter;

  always @(posedge CLK100MHZ)
  begin
    r_enemy_color_counter <= r_enemy_color_counter + 1;
    r_enemy_color <= w_random_16bit[11:0];
  end

  assign LED[11:0] = r_enemy_color;
  assign w_generate = (r_enemy_color_counter == 0);
  /****************************************************************************/
endmodule
