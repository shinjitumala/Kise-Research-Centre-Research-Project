`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Hoshino's integrated games
// Engineer: Hoshino Shinji
//
// Create Date: 2018/10/29 17:43:22
// Design Name:
// Module Name: main
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module m_main(
  input  wire        CLK100MHZ,
  input  wire [15:0] SW,
  input  wire [4:0]  BTN,
  output reg  [6:0]  SG,
  output reg  [7:0]  AN,
  output reg  [15:0] LED,
  output reg  [2:0]  LED16,
  output reg  [2:0]  LED17
  );

  wire [6:0]  w_sg;
  wire [7:0]  w_an;
  reg  [31:0] r_num;
  reg  [15:0]  r_cnt;
  reg         r_clk2;

  m_7segcon m_7segcon(CLK100MHZ, r_num, w_sg, w_an);
  always @(posedge CLK100MHZ) SG <= w_sg;
  always @(posedge CLK100MHZ) AN <= w_an;
  always @(posedge CLK100MHZ) r_num <= convert(32'd37564);
  always @(posedge CLK100MHZ) LED <= SW;
  always @(posedge CLK100MHZ) LED16 <= BTN;
  always @(posedge CLK100MHZ) r_cnt <= r_cnt + 1;
  always @(posedge CLK100MHZ) r_clk2 <= (r_cnt == 0) ? 1 : 0;
  always @(posedge r_clk2)    LED17  <= 3'b100;

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

/******************************************************************************/
module m_7segled (w_in, r_led);
  input  wire [3:0] w_in;
  output reg  [6:0] r_led;
  always @(*) begin
    case (w_in)
      4'h0  : r_led <= 7'b1111110;
      4'h1  : r_led <= 7'b0110000;
      4'h2  : r_led <= 7'b1101101;
      4'h3  : r_led <= 7'b1111001;
      4'h4  : r_led <= 7'b0110011;
      4'h5  : r_led <= 7'b1011011;
      4'h6  : r_led <= 7'b1011111;
      4'h7  : r_led <= 7'b1110000;
      4'h8  : r_led <= 7'b1111111;
      4'h9  : r_led <= 7'b1111011;
      4'ha  : r_led <= 7'b1110111;
      4'hb  : r_led <= 7'b0011111;
      4'hc  : r_led <= 7'b1001110;
      4'hd  : r_led <= 7'b0111101;
      4'he  : r_led <= 7'b1001111;
      4'hf  : r_led <= 7'b1000111;
      default:r_led <= 7'b0000000;
    endcase
  end
endmodule

`define DELAY7SEG  100000 // 200000 for 100MHz, 100000 for 50MHz
/******************************************************************************/

module m_7segcon (w_clk, w_din, r_sg, r_an);
  input  wire w_clk;
  input  wire [31:0] w_din;
  output reg [6:0] r_sg;  // cathode segments
  output reg [7:0] r_an;  // common anode

  reg [31:0] r_val   = 0;
  reg [31:0] r_cnt   = 0;
  reg  [3:0] r_in    = 0;
  reg  [2:0] r_digit = 0;
  always@(posedge w_clk) r_val <= w_din;

  always@(posedge w_clk) begin
    r_cnt <= (r_cnt>=(`DELAY7SEG-1)) ? 0 : r_cnt + 1;
    if(r_cnt==0) begin
      r_digit <= r_digit+ 1;
      if      (r_digit==0) begin r_an <= 8'b11111110; r_in <= r_val[3:0];   end
      else if (r_digit==1) begin r_an <= 8'b11111101; r_in <= r_val[7:4];   end
      else if (r_digit==2) begin r_an <= 8'b11111011; r_in <= r_val[11:8];  end
      else if (r_digit==3) begin r_an <= 8'b11110111; r_in <= r_val[15:12]; end
      else if (r_digit==4) begin r_an <= 8'b11101111; r_in <= r_val[19:16]; end
      else if (r_digit==5) begin r_an <= 8'b11011111; r_in <= r_val[23:20]; end
      else if (r_digit==6) begin r_an <= 8'b10111111; r_in <= r_val[27:24]; end
      else                 begin r_an <= 8'b01111111; r_in <= r_val[31:28]; end
    end
  end
  wire [6:0] w_segments;
  m_7segled m_7segled (r_in, w_segments);
  always@(posedge w_clk) r_sg <= ~w_segments;
endmodule

/******************************************************************************/

module m_test0(w_clk);
  // Definitions
  input wire w_clk;

  // Assign

endmodule
