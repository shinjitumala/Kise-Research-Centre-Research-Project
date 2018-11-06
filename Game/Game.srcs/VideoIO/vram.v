`default_nettype none

module m_sram
  #(parameter
    ADDR_WIDTH = 8,
    DATA_WIDTH = 8,
    DEPTH      = 256,
    MEMFILE    = ""
  )
  (
    input  wire                    iw_clock,
    input  wire [ADDR_WIDTH - 1:0] iw_addr,
    input  wire                    iw_write,
    input  wire [DATA_WIDTH - 1:0] iw_data,
    output reg  [DATA_WIDTH - 1:0] or_data
  );

  reg [DATA_WIDTH - 1:0] r_memory_array [0:DEPTH - 1];

  reg [ADDR_WIDTH - 1:0] r_addr;
  reg [DATA_WIDTH - 1:0] r_data;

  initial
  begin
    if (MEMFILE > 0)
    begin
      $display("Loading memory initial file '" + MEMFILE + "' into memory array.");
      $readmemh(MEMFILE, r_memory_array);
    end
  end

  always @(posedge iw_clock)
  begin
    r_data <= iw_data;
    r_addr <= iw_addr;
    if(iw_write)
    begin
      r_memory_array[r_addr] <= r_data;
    end
    else
    begin
      or_data <= r_memory_array[r_addr];
    end
  end
endmodule

/******************************************************************************/

module m_VRAMtest
  (
    input  wire        CLK100MHZ,
    input  wire [4:0]  BTN,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output reg  [3:0]  VGA_R,
    output reg  [3:0]  VGA_G,
    output reg  [3:0]  VGA_B
  );
  wire w_reset = BTN[0] || BTN[1] || BTN[2] || BTN[3] || BTN[4];

  wire w_clk;
  CLK40MHZ clk (w_clk, CLK100MHZ);

  wire [10:0] w_x;
  wire [10:0] w_y;
  wire       w_activ;

  m_vga display
  (
    .iw_clock (w_clk),
    .iw_rst   (w_reset),
    .ow_hs    (VGA_HS),
    .ow_vs    (VGA_VS),
    .ow_x     (w_x),
    .ow_y     (w_y),
    .ow_activ (w_activ)
  );

  // VRAM
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19;
  localparam VRAM_DATA_WIDTH = 8;

  reg  [VRAM_ADDR_WIDTH - 1:0] r_adress;
  wire [VRAM_DATA_WIDTH - 1:0] w_data;

  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH),
    .MEMFILE    ("sushi2.mem")
  )
  vram
  (
    .iw_addr  (r_adress),
    .iw_clock (CLK100MHZ),
    .iw_write (0),
    .or_data  (w_data),
    .iw_data  (0)
  );

  reg [11:0] r_palette [0:63];
  reg [11:0] r_rgb;
  initial
  begin
    $display("Loading palette...");
    $readmemh("sushi2_palette.mem", r_palette);
  end

  always @(posedge CLK100MHZ)
  begin
    r_adress <= w_y * DISPLAY_WIDTH + w_x;

    if (w_activ)
      r_rgb <= r_palette[w_data];
    else
      r_rgb <= 0;

    VGA_R <= r_rgb[11:8];
    VGA_G <= r_rgb[7:4];
    VGA_B <= r_rgb[3:0];
  end
endmodule
