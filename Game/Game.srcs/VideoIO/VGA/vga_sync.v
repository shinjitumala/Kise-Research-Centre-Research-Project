`timescale 1ns / 1ps

module m_vga
  // Set up all the appropriate parameters for your VGA display.
  // You can search "VGA video timings" on google to get all the necessary numbers.
  // Also, make sure that the input clock is the right frequency. All other variables are already here.
  #(parameter
    H_VISIBLE = 800,
    H_FRONT   = 40,
    H_PULSE   = 128,
    H_BACK    = 88,

    V_VISIBLE = 600,
    V_FRONT   = 1,
    V_PULSE   = 4,
    V_BACK    = 23
  )
  (
    input  wire        iw_clock, //            input clock: Make sure that it's the correct frequency according to the video timings table.
    input  wire        iw_rst,   //             reset wire: Will reset the display output. Not really needed so leave it at 0 if not using.
    output wire        ow_hs,    // horizontal sync signal: Horizontal sync signal for VGA output.
    output wire        ow_vs,    //   vertical sync signal: Vertical sync signal for VGA output.
    output wire [10:0] ow_x,     //                      x: The horizontal axis of the pixel which is currently being drawn.
    output wire [10:0] ow_y,     //                      y: The vertical axis of the pixel which is currently being drawn.
    output wire        ow_activ //                 active: High during active pixel drawing.
  );
  // Constants for horizontal sync.
  localparam HS_STA = H_VISIBLE + H_FRONT;
  localparam HS_END = HS_STA + H_PULSE;
  // Constants for vertical sync.
  localparam VS_STA = V_VISIBLE + V_FRONT;
  localparam VS_END = VS_STA + V_PULSE;
  // Constants for maximum internal count value.
  localparam H_MAX   = H_FRONT + H_PULSE + H_BACK + H_VISIBLE - 1;
  localparam V_MAX = V_FRONT + V_PULSE + V_BACK + V_VISIBLE - 1;

  reg [10:0] r_hcount = 0;
  reg [10:0] r_vcount = 0;

  always @(posedge iw_clock)
  begin
    r_hcount <= (iw_rst) ? 0 : (r_hcount == H_MAX) ? 0 : r_hcount + 1;
    r_vcount <= (iw_rst) ? 0 : (r_hcount != H_MAX) ? r_vcount : (r_vcount == V_MAX) ? 0 : r_vcount + 1;
  end

  assign ow_hs = (iw_rst) ? 1 : (r_hcount >= HS_STA && r_hcount < HS_END) ? 0 : 1;
  assign ow_vs = (iw_rst) ? 1 : (r_vcount >= VS_STA && r_vcount < VS_END) ? 0 : 1;
  assign ow_x  = (iw_rst) ? 0 : (r_hcount < H_VISIBLE) ? r_hcount : 0;
  assign ow_y  = (iw_rst) ? 0 : (r_vcount < V_VISIBLE) ? r_vcount : 0;
  assign ow_activ = (iw_rst) ? 0 : (r_hcount < H_VISIBLE && r_vcount < V_VISIBLE);
endmodule

/******************************************************************************/

module m_vga_test
  (
    input  wire        CLK100MHZ,
    input  wire  [4:0] BTN,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire  [3:0] VGA_R,
    output wire  [3:0] VGA_G,
    output wire  [3:0] VGA_B
  );
  wire w_rst = BTN[0] || BTN[1] || BTN[2] || BTN[3] || BTN[4];

  wire [9:0] w_x;
  wire [9:0] w_y;

  wire w_clk2;
  CLK40MHZ clk (w_clk2, CLK100MHZ);

  reg [3:0] r_cnt0 = 0;
  reg [3:0] r_cnt1 = 0;

  m_vga display (
    .iw_clock   (w_clk2),
    .iw_rst     (w_rst),
    .ow_hs      (VGA_HS),
    .ow_vs      (VGA_VS),
    .ow_x       (w_x),
    .ow_y       (w_y)
  );

  // Display overlapping 4 squares
  wire w_sq0, w_sq1, w_sq2, w_sq3;
  assign w_sq0 = ((w_x > 120) & (w_y > 40 ) & (w_x < 280) & (w_y < 200)) ? 1 : 0;
  assign w_sq1 = ((w_x > 200) & (w_y > 120) & (w_x < 360) & (w_y < 280)) ? 1 : 0;
  assign w_sq2 = ((w_x > 280) & (w_y > 200) & (w_x < 440) & (w_y < 360)) ? 1 : 0;
  assign w_sq3 = ((w_x > 360) & (w_y > 280) & (w_x < 520) & (w_y < 440)) ? 1 : 0;

  assign VGA_R[3] = w_sq1;
  assign VGA_G[3] = w_sq0 | w_sq3;
  assign VGA_B[3] = w_sq2;
endmodule
