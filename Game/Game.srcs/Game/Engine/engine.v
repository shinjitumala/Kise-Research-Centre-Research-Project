module m_engine
(
  input  wire        iw_clock,
  input  wire [10:0] iw_player_x,
  input  wire [10:0] iw_player_y,
  output wire        ow_player_lose
)
  /*************************************/
  // Display
  /*************************************/
  wire        w_display_clock;
  wire [10:0] w_display_x;
  wire [10:0] w_display_y;
  wire        w_display_active;
  wire        w_display_reset;
  reg  [11:0] r_display_out;

  CLK40MHZ display_clock (w_display_clock, CLK100MHZ);
  assign w_display_reset = SW[15];
  always @ (posedge CLK100MHZ)
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
    .iw_clock (w_vclk),
    .iw_rst   (w_display_reset),
    .ow_hs    (VGA_HS),
    .ow_vs    (VGA_VS),
    .ow_x     (w_display_x),
    .ow_y     (w_display_y),
    .ow_activ (w_display_active)
  );
  /*************************************/

  /*************************************/
  // VRAM
  /*************************************/
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19;
  localparam VRAM_DATA_WIDTH = 8;

  reg  [VRAM_ADDR_WIDTH - 1:0] r_vram_address;
  wire [VRAM_DATA_WIDTH - 1:0] w_vram_dataout, w_vram_datain;
  wire                         w_vram_write;

  always @(posedge CLK100MHZ)
  begin
    r_vram_address <= w_display_y * DISPLAY_WIDTH + w_display_x;
    r_display_out <= w_vram_dataout;
  end

  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH),
    .MEMFILE    ("space.mem")
  )
  vram
  (
    .iw_addr  (r_vram_address),
    .iw_clock (CLK100MHZ),
    .iw_write (w_vram_write),
    .or_data  (w_vram_dataout),
    .iw_data  (w_vram_datain)
  );
  /*************************************/

  /*************************************/
  // Game Logic
  /*************************************/
  
endmodule
