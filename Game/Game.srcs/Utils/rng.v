module m_rng
(
  input  wire iw_clock,
  output wire or_random
);
(* OPTIMIZE="OFF" *)
(* ALLOW_COMBINATORIAL_LOOPS = "true", KEEP = "true" *) wire [31:0] r_stage /* synthesis keep */;
reg r_meta1 = 1'b0;
reg r_meta2 = 1'b0;

assign or_random = r_meta2;

always@(posedge iw_clock)
begin
  r_meta1 <= r_stage[1];
  r_meta2 <= r_meta1;
end

assign r_stage[1] = ~&{r_stage[2] ^ r_stage[1]};
assign r_stage[2] = !r_stage[3];
assign r_stage[3] = !r_stage[4] ^ r_stage[1];
assign r_stage[4] = !r_stage[5] ^ r_stage[1];
assign r_stage[5] = !r_stage[6] ^ r_stage[1];
assign r_stage[6] = !r_stage[7] ^ r_stage[1];
assign r_stage[7] = !r_stage[8];
assign r_stage[8] = !r_stage[9] ^ r_stage[1];
assign r_stage[9] = !r_stage[10] ^ r_stage[1];
assign r_stage[10] = !r_stage[11];
assign r_stage[11] = !r_stage[12];
assign r_stage[12] = !r_stage[13] ^ r_stage[1];
assign r_stage[13] = !r_stage[14];
assign r_stage[14] = !r_stage[15] ^ r_stage[1];
assign r_stage[15] = !r_stage[16] ^ r_stage[1];
assign r_stage[16] = !r_stage[17] ^ r_stage[1];
assign r_stage[17] = !r_stage[18];
assign r_stage[18] = !r_stage[19];
assign r_stage[19] = !r_stage[20] ^ r_stage[1];
assign r_stage[20] = !r_stage[21] ^ r_stage[1];
assign r_stage[21] = !r_stage[22];
assign r_stage[22] = !r_stage[23];
assign r_stage[23] = !r_stage[24];
assign r_stage[24] = !r_stage[25];
assign r_stage[25] = !r_stage[26];
assign r_stage[26] = !r_stage[27] ^ r_stage[1];
assign r_stage[27] = !r_stage[28];
assign r_stage[28] = !r_stage[29];
assign r_stage[29] = !r_stage[30];
assign r_stage[30] = !r_stage[31];
assign r_stage[31] = !r_stage[1];
endmodule

/******************************************************************************/

module m_rng_16bit
(
  input  wire        iw_clock,
  input  wire        iw_generate,
  output reg  [15:0] or_random
);
  wire w_random;
  m_rng rng (iw_clock, w_random);

  reg [15:0] r_random;
  reg [3:0]  r_count;
  always @(posedge iw_clock)
  begin
    r_count <= r_count + 1;
    r_random[r_count] <= w_random;
  end

  always @(posedge iw_generate) or_random <= r_random;
endmodule

/******************************************************************************/

module m_rng_test
(
  input  wire        CLK100MHZ,
  output wire [6:0]  SG,
  output wire [7:0]  AN
);
  reg [31:0] r_num;
  wire w_rnd;
  reg [26:0] r_count;

  m_rng rng (CLK100MHZ, w_rnd);

  always @(posedge CLK100MHZ)
  begin
    r_count = r_count + 1;

    if (r_count >= 0 && r_count <= 31)
    begin
      r_num[r_count] <= w_rnd;
    end
  end

  m_int_7seg segcon (CLK100MHZ, r_num, SG, AN);
endmodule
