module m_enemy
#(parameter
  HIT_POINTS  = 8,
  SIZE        = 32
)
(
  input  wire [10:0] iw_x,
  input  wire [10:0] iw_y,
  input  wire [2:0]  iw_damage,
  output wire [2:0]  ow_hit_points,

)
