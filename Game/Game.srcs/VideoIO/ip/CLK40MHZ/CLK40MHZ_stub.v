// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
// Date        : Sat Nov 10 15:23:18 2018
// Host        : HOME-PC97 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {D:/TiTech
//               Files/2018/3Q/Kise-Research-Centre-Research-Project/Game/Game.srcs/VideoIO/ip/CLK40MHZ/CLK40MHZ_stub.v}
// Design      : CLK40MHZ
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module CLK40MHZ(clk_out1, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_in1" */;
  output clk_out1;
  input clk_in1;
endmodule
