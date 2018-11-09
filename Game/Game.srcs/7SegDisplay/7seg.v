`define DELAY7SEG  100000 // 200000 for 100MHz, 100000 for 50MHz

module m_7segled
(
  input  wire [3:0] iw_in,
  output reg  [6:0] or_led
);
  always @(*) begin
    case (iw_in)
      4'h0  : or_led <= 7'b1111110;
      4'h1  : or_led <= 7'b0110000;
      4'h2  : or_led <= 7'b1101101;
      4'h3  : or_led <= 7'b1111001;
      4'h4  : or_led <= 7'b0110011;
      4'h5  : or_led <= 7'b1011011;
      4'h6  : or_led <= 7'b1011111;
      4'h7  : or_led <= 7'b1110000;
      4'h8  : or_led <= 7'b1111111;
      4'h9  : or_led <= 7'b1111011;
      4'ha  : or_led <= 7'b1110111;
      4'hb  : or_led <= 7'b0011111;
      4'hc  : or_led <= 7'b1001110;
      4'hd  : or_led <= 7'b0111101;
      4'he  : or_led <= 7'b1001111;
      4'hf  : or_led <= 7'b1000111;
      default:or_led <= 7'b0000000;
    endcase
  end
endmodule

/******************************************************************************/

module m_7segcon
(
  input  wire        iw_clock,
  input  wire [31:0] iw_din,
  output reg  [6:0]  or_sg,  // cathode segments
  output reg  [7:0]  or_an  // common anode
);
  reg [31:0] r_val   = 0;
  reg [31:0] r_cnt   = 0;
  reg  [3:0] r_in    = 0;
  reg  [2:0] r_digit = 0;
  always@(posedge iw_clock) r_val <= iw_din;

  always@(posedge iw_clock)
  begin
    r_cnt <= (r_cnt>=(`DELAY7SEG-1)) ? 0 : r_cnt + 1;
    if(r_cnt==0)
    begin
      r_digit <= r_digit+ 1;
      if      (r_digit==0) begin or_an <= 8'b11111110; r_in <= r_val[3:0];   end
      else if (r_digit==1) begin or_an <= 8'b11111101; r_in <= r_val[7:4];   end
      else if (r_digit==2) begin or_an <= 8'b11111011; r_in <= r_val[11:8];  end
      else if (r_digit==3) begin or_an <= 8'b11110111; r_in <= r_val[15:12]; end
      else if (r_digit==4) begin or_an <= 8'b11101111; r_in <= r_val[19:16]; end
      else if (r_digit==5) begin or_an <= 8'b11011111; r_in <= r_val[23:20]; end
      else if (r_digit==6) begin or_an <= 8'b10111111; r_in <= r_val[27:24]; end
      else                 begin or_an <= 8'b01111111; r_in <= r_val[31:28]; end
    end
  end
  wire [6:0] w_segments;
  m_7segled m_7segled (r_in, w_segments);
  always@(posedge iw_clock) or_sg <= ~w_segments;
endmodule

/******************************************************************************/

module m_int_7seg
(
  input  wire        iw_clock,
  input  wire [31:0] iw_int,
  output wire  [6:0]  or_sg,
  output wire  [7:0]  or_an
);
  reg [3:0]  r_digit [7:0];
  reg [31:0] r_converted;
  always @(posedge iw_clock)
  begin
    r_converted[3:0]   <= iw_int % 10;
    r_converted[7:4]   <= iw_int / 10 % 10;
    r_converted[11:8]  <= iw_int / 100 % 10;
    r_converted[15:12] <= iw_int / 1000 % 10;
    r_converted[19:16] <= iw_int / 10000 % 10;
    r_converted[23:20] <= iw_int / 100000 % 10;
    r_converted[27:24] <= iw_int / 1000000 % 10;
    r_converted[31:28] <= iw_int / 10000000 % 10;
  end
  m_7segcon segcon (iw_clock, r_converted, or_sg, or_an);
endmodule

/******************************************************************************/

module m_7segtest
(
  input  wire        CLK100MHZ,
  output wire [6:0]  SG,
  output wire [7:0]  AN
);
  m_int_7seg segcon (CLK100MHZ, 32'd20181102, SG, AN);
endmodule
