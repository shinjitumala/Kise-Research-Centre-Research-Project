module m_torpedo
#(parameter
  WIDTH  = 16,
  HEIGHT = 32
)
(
  input  wire  [9:0]             iw_draw_x,
  input  wire  [9:0]             iw_draw_y,
  input  wire  [9:0]             iw_pos_x,
  input  wire  [9:0]             iw_pos_y,
  output wire                    ow_draw
);
  assign ow_draw = (((iw_pos_x <= iw_draw_x) && (iw_draw_x < iw_pos_x + WIDTH)) &&
                    ((iw_pos_y <= iw_draw_y) && (iw_draw_y < iw_pos_y + HEIGHT)));
endmodule
