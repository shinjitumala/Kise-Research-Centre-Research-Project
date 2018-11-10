-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
-- Date        : Sat Nov 10 15:23:18 2018
-- Host        : HOME-PC97 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub {D:/TiTech
--               Files/2018/3Q/Kise-Research-Centre-Research-Project/Game/Game.srcs/VideoIO/ip/CLK40MHZ/CLK40MHZ_stub.vhdl}
-- Design      : CLK40MHZ
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CLK40MHZ is
  Port ( 
    clk_out1 : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end CLK40MHZ;

architecture stub of CLK40MHZ is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,clk_in1";
begin
end;
