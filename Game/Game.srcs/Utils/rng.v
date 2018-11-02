module m_rng
(
  input  wire iw_clock,
  output wire or_random
);
(* OPTIMIZE="OFF" *)
wire [31:0] r_stage /* synthesis keep */;
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
