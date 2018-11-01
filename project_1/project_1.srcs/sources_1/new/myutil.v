`default_nettype none

module m_top();
  reg r_clk=0;
  reg r_clk2=0;
  initial forever #1 r_clk = ~r_clk;
  initial forever #2 r_clk2 = ~r_clk2;

  wire [6:0]  w_sg;
  wire [7:0]  w_an;
  reg  [31:0] r_num;

  m_7segcon m_7segcon(r_clk, r_num, w_sg, w_an);
  always @(posedge r_clk) r_num <= convert(32'd37564);

        reg  [11:0] r_rgb;
  wire        w_lock;
  wire VGA_HS, VGA_VS;

  assign w_lock = 1'd0;
  wire [9:0] w_x, w_y;
  wire video_on, p_tick, temp, temp2;
  reg  w_reset;

  m_VGA lel (r_clk, r_clk2, w_reset, VGA_HS, VGA_VS, temp, temp2, video_on, p_tick, w_x, w_y);

  // convert 32 bit int for 7segcon output
  function [31:0] convert (input reg [31:0] i);
    reg [3:0] digit [7:0];

    begin
        digit[0] = i % 10;
        digit[1] = i / 10 % 10;
        digit[2] = i / 100 % 10;
        digit[3] = i / 1000 % 10;
        digit[4] = i / 10000 % 10;
        digit[5] = i / 100000 % 10;
        digit[6] = i / 1000000 % 10;
        digit[7] = i / 10000000 % 10;

        convert = {digit[7], digit[6], digit[5], digit[4], digit[3], digit[2], digit[1], digit[0]};
    end
  endfunction
endmodule
