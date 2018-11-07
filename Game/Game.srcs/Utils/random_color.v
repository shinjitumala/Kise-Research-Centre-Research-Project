module m_random_color
(
  input  wire        iw_clock,
  input  wire        iw_generate,
  output reg  [11:0] or_color
);
  wire w_random;
  m_rng rng (iw_clock, w_random);

  reg [11:0] r_color;
  reg [3:0]  r_count = 0;
  always @(posedge iw_clock)
  begin
    r_count <= (r_count == 12) ? 0 : r_count + 1;
    r_color[r_count] <= w_random;
  end

  always @(posedge iw_generate) or_color <= r_color;
endmodule

/******************************************************************************/

module m_random_color_test
(
  input  wire        CLK100MHZ,
  output reg  [15:0] LED,
  output wire        VGA_HS,
  output wire        VGA_VS,
  output reg  [3:0]  VGA_R,
  output reg  [3:0]  VGA_G,
  output reg  [3:0]  VGA_B
);
  wire w_clk;
  CLK40MHZ clk (w_clk, CLK100MHZ);

  wire [10:0] w_x;
  wire [10:0] w_y;
  wire       w_activ;

  m_vga display
  (
    .iw_clock (w_clk),
    .iw_rst   (0),
    .ow_hs    (VGA_HS),
    .ow_vs    (VGA_VS),
    .ow_x     (w_x),
    .ow_y     (w_y),
    .ow_active (w_activ)
  );

  wire [11:0] r_rgb;
  reg  [11:0] r_out;
  reg [25:0] r_count;
  reg r_generate;
  m_random_color color (CLK100MHZ, r_generate, r_rgb);

  always @(posedge CLK100MHZ)
  begin
    r_count = r_count + 1;
    if(r_count == 0) r_generate = ~r_generate;

    if (w_activ)
      r_out <= r_rgb;
    else
      r_out <= 0;

    VGA_R <= r_out[11:8];
    VGA_G <= r_out[7:4];
    VGA_B <= r_out[3:0];
  end
endmodule
