`default_nettype none

module m_VGA(
  input  wire        iw_clock,
  input  wire        iw_pix_stb,
  input  wire        iw_rst,
  output wire        ow_hs,
  output wire        ow_vs,
  output wire        ow_blanking,
  output wire        ow_active,
  output wire        ow_screenend,
  output wire        ow_animate,
  output wire  [9:0] ow_x,
  output wire  [9:0] ow_y
  );

  localparam H_VISIBLE = 800;
  localparam H_FRONT   = 40;
  localparam H_PULSE   = 128;
  localparam H_BACK    = 88;

  localparam V_VISIBLE = 600;
  localparam V_FRONT   = 1;
  localparam V_PULSE   = 4;
  localparam V_BACK    = 23;

  localparam HS_STA = H_VISIBLE + H_FRONT;
  localparam HS_END = HS_STA + H_PULSE;
  localparam HA_STA = H_FRONT + H_PULSE + H_BACK;
  localparam VS_STA = V_VISIBLE + V_FRONT;
  localparam VS_END = VS_STA + V_PULSE;
  localparam VA_END = V_VISIBLE;
  localparam LINE   = H_FRONT + H_PULSE + H_BACK + H_VISIBLE - 1;
  localparam SCREEN = V_FRONT + V_PULSE + V_BACK + V_VISIBLE;

  reg [9:0] r_hcount = 0;
  reg [9:0] r_vcount = 0;

  assign ow_hs = ~((r_hcount >= HS_STA) && (r_hcount < HS_END));
  assign ow_vs = ~((r_vcount >= VS_STA) && (r_vcount < VS_END));

  assign ow_x = (r_hcount <  HA_STA) ? 0 : (r_hcount - HA_STA);
  assign ow_y = (r_vcount >= VA_END) ? (VA_END - 1) : (r_vcount);

  assign ow_blanking = ((r_hcount < HA_STA) | (r_vcount > VA_END - 1));

  assign ow_active = ~((r_hcount < HA_STA) | (r_vcount > VA_END - 1));

  assign ow_screenend = ((r_vcount == SCREEN - 1) & (r_hcount == LINE));

  assign ow_animate = ((r_vcount ==VA_END - 1) & (r_hcount == LINE));

  always @(posedge iw_pix_stb)
  begin
    if (iw_rst)
    begin
      r_hcount <= 0;
      r_vcount <= 0;
    end
    else
    begin
      if (r_hcount == LINE)
      begin
        r_hcount <= 0;
        r_vcount <= r_vcount + 1;
      end
      else
        r_hcount <= r_hcount + 1;

      if (r_vcount == SCREEN)
        r_vcount <= 0;
    end
  end
endmodule

module m_VGAtest(
  input  wire        CLK100MHZ,
  input  wire  [4:0] BTN,
  output wire        VGA_HS,
  output wire        VGA_VS,
  output wire  [3:0] VGA_R,
  output wire  [3:0] VGA_G,
  output wire  [3:0] VGA_B,
  output wire [15:0] LED,
  output wire  [6:0] SG,
  output wire  [7:0] AN
  );
  wire w_rst = BTN[0];

  wire [9:0] w_x;
  wire [9:0] w_y;

  wire w_clk2;
  clk_wiz_0 clk (w_clk2, w_rst, CLK100MHZ);



  m_VGA display (
   .iw_clock   (CLK100MHZ),
   .iw_pix_stb (w_clk2),
   .iw_rst     (w_rst),
   .ow_hs      (VGA_HS),
   .ow_vs      (VGA_VS),
   .ow_x       (w_x),
   .ow_y       (w_y)
   );

  wire w_sq0, w_sq1, w_sq2, w_sq3;
  assign w_sq0 = ((w_x > 120) & (w_y > 40 ) & (w_x < 280) & (w_y < 200)) ? 1 : 0;
  assign w_sq1 = ((w_x > 200) & (w_y > 120) & (w_x < 360) & (w_y < 280)) ? 1 : 0;
  assign w_sq2 = ((w_x > 280) & (w_y > 200) & (w_x < 440) & (w_y < 360)) ? 1 : 0;
  assign w_sq3 = ((w_x > 360) & (w_y > 280) & (w_x < 520) & (w_y < 440)) ? 1 : 0;

  assign VGA_R[3] = w_sq1;
  assign VGA_G[3] = w_sq0 | w_sq3;
  assign VGA_B[3] = w_sq2;

endmodule

module m_sram #(parameter ADDR_WIDTH=8, DATA_WIDTH=8, DEPTH=256, MEMFILE="") (
  input  wire                  iw_clk,
  input  wire [ADDR_WIDTH-1:0] iw_addr,
  input  wire                  iw_write,
  input  wire [DATA_WIDTH-1:0] iw_data,
  output reg  [DATA_WIDTH-1:0] or_data
  );

  reg [DATA_WIDTH-1:0] r_memory_array [0:DEPTH-1];

  initial begin
    if (MEMFILE > 0)
    begin
      $display ("Loading memory init file '" + MEMFILE + "' into array.");
      $readmemh(MEMFILE, r_memory_array);
    end
  end

  always @(posedge iw_clk)
  begin
    if (iw_write)
    begin
      r_memory_array[iw_addr] <= iw_data;
    end
    else begin
      or_data <= r_memory_array[iw_addr];
    end
  end
endmodule

module m_VGAtest2 (
  input  wire        CLK100MHZ,
  input  wire  [4:0] BTN,
  output wire        VGA_HS,
  output wire        VGA_VS,
  output reg   [3:0] VGA_R,
  output reg   [3:0] VGA_G,
  output reg   [3:0] VGA_B
  );

endmodule
