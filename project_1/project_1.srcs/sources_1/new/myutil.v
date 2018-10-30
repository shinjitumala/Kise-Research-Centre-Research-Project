module m_top();
  reg r_clk=0;
  initial forever #50 r_clk = ~r_clk;

  wire [6:0]  w_sg;
  wire [7:0]  w_an;
  reg  [31:0] r_num;

  m_7segcon m_7segcon(r_clk, r_num, w_sg, w_an);
  always @(posedge r_clk) r_num <= convert(32'd37564);


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
