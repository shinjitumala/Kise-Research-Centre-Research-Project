module m_engine_simulation
(
  input  wire [4:0]  BTN,
  input  wire [15:0] SW,
  output wire [6:0]  SG,
  output wire [7:0]  AN,
  output wire [15:0] LED,
  output wire        VGA_HS,
  output wire        VGA_VS,
  output reg  [3:0]  VGA_R,
  output reg  [3:0]  VGA_G,
  output reg  [3:0]  VGA_B
);
  /****************************************************************************/
  // Simulation
  /****************************************************************************/
  reg r_display_clock = 0;
  wire w_display_clock;
  initial forever #1 r_display_clock = ~r_display_clock;
  // initial forever #2 r_display_clock = ~r_display_clock;
  //
  assign w_display_clock = r_display_clock;
  /****************************************************************************/
  /****************************************************************************/
  // Display
  /****************************************************************************/
  //wire        w_display_clock;
  wire [10:0] w_display_x;
  wire [10:0] w_display_y;
  wire        w_display_active;
  wire        w_display_reset;
  wire        w_display_frame;
  reg  [11:0] r_display_out;

  //CLK40MHZ display_clock (w_display_clock, CLK100MHZ);
  assign w_display_reset = 0;

  m_vga display
  (
    .iw_clock  (w_display_clock),
    .iw_rst    (w_display_reset),
    .ow_hs     (VGA_HS),
    .ow_vs     (VGA_VS),
    .ow_x      (w_display_x),
    .ow_y      (w_display_y),
    .ow_active (w_display_active),
    .ow_frame  (w_display_frame)
  );
  /****************************************************************************/
  /****************************************************************************/

  /****************************************************************************/
  // VRAM
  /****************************************************************************/
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19;
  localparam VRAM_DATA_WIDTH = 4;

  reg  [VRAM_ADDR_WIDTH - 1:0] r_vram_address;
  wire [VRAM_DATA_WIDTH - 1:0] w_vram_dataout;
  reg  [VRAM_DATA_WIDTH - 1:0] r_vram_dataout_buffer;
  reg  [VRAM_DATA_WIDTH - 1:0] r_vram_datain;

  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH)
  )
  vram
  (
    .iw_addr  (r_vram_address),
    .iw_clock (w_display_clock),
    .iw_write (1),
    .or_data  (w_vram_dataout),
    .iw_data  (r_vram_datain)
  );
  /****************************************************************************/

  /****************************************************************************/
  // Game Logic
  /****************************************************************************/
  // Player
  reg [10:0] r_player_x = DISPLAY_WIDTH / 2 - 32 / 2, r_player_y = DISPLAY_HEIGHT - 32;
  wire w_player_draw;
  wire [VRAM_DATA_WIDTH - 1:0] w_player_dataout;
  reg  r_player_status = 1;
  reg [15:0] r_player_control_count = 0;

  m_entity
  #(
    .ADDR_WIDTH  (VRAM_ADDR_WIDTH),
    .DATA_WIDTH  (VRAM_DATA_WIDTH),
    .ENTITY_SIZE (32),
    .MEMFILE     ("fpr.mem")
  )
  player
  (
    .iw_clock  (w_display_clock),
    .iw_draw_x (w_display_x),
    .iw_draw_y (w_display_y),
    .iw_pos_x  (r_player_x),
    .iw_pos_y  (r_player_y),
    .ow_draw   (w_player_draw),
    .or_data   (w_player_dataout)
  );
  reg [11:0] r_player_palette [0:15];
  initial
  begin
    $display("Loading sprite r_player_palette.");
    $readmemh("fpr_palette.mem", r_player_palette);
  end

  // Torpedo
  localparam TORPEDO_WIDTH  = 16;
  localparam TORPEDO_HEIGHT = 32;
  reg [11:0] r_torpedo_color;
  reg [10:0] r_torpedo_x = 0, r_torpedo_y = 0;
  wire       w_torpedo_draw;
  reg        r_torpedo_status = 0;
  reg [13:0] r_torpedo_movement_counter = 0;

  m_torpedo
  #(
      .WIDTH  (TORPEDO_WIDTH),
      .HEIGHT (TORPEDO_HEIGHT)
  )
  torpedo
  (
    .iw_draw_x (w_display_x),
    .iw_draw_y (w_display_y),
    .iw_pos_x  (r_torpedo_x),
    .iw_pos_y  (r_torpedo_y),
    .ow_draw   (w_torpedo_draw)
  );

  // Enemy
  localparam ENEMY_SIZE = 128;
  reg [11:0] r_enemy_color;
  reg [27:0] r_enemy_color_counter;
  reg [10:0] r_enemy_x = 400 - ENEMY_SIZE / 2, r_enemy_y = 0;
  wire       w_enemy_draw;
  reg [21:0] r_enemy_control_counter = 0;
  reg [23:0] r_enemy_hit_points = 24'd10000000;

  // Color Generator
  wire [11:0] w_random_color;
  wire        w_random_generate;
  m_random_color rng (w_display_clock, w_random_generate, w_random_color);

  m_enemy
  #(
    .SIZE (ENEMY_SIZE)
  )
  enemy
  (
    .iw_draw_x (w_display_x),
    .iw_draw_y (w_display_y),
    .iw_pos_x  (r_enemy_x),
    .iw_pos_y  (r_enemy_y),
    .ow_draw   (w_enemy_draw)
  );

  m_int_7seg enemy_hitpoints_display
  (
    .iw_clock (w_display_clock),
    .iw_int   ({8'b00000000, r_enemy_hit_points}),
    .or_sg    (SG),
    .or_an    (AN)
  );

  assign LED = {SW[15], r_player_status, r_torpedo_status, (r_enemy_hit_points > 0), r_enemy_color};
  assign w_random_generate = (r_enemy_color_counter == 0);

  // Background
  wire [11:0] w_background_address;
  wire [3:0]  w_background_dataout;

  assign w_background_address = (w_display_y % 50 * 50) + (w_display_x % 50);

  m_sram
  #(
    .ADDR_WIDTH (12),
    .DATA_WIDTH (4),
    .DEPTH      (50 * 50),
    .MEMFILE    ("background.mem")
  )
  background
  (
    .iw_clock (w_display_clock),
    .iw_addr  (w_background_address),
    .iw_write (1),
    .iw_data  (0),
    .or_data  (w_background_dataout)
  );
  reg [9:0] r_diff_torpedo_enemy_x, r_diff_torpedo_enemy_y, r_diff_player_enemy_x, r_diff_player_enemy_y;
  /****************************************************************************/
  always @(posedge w_display_clock)
  begin
    // Display
    if (w_display_active)
    begin
     VGA_R <= r_display_out[11:8];
     VGA_G <= r_display_out[7:4];
     VGA_B <= r_display_out[3:0];
    end
    else
    begin
     VGA_R <= 0;
     VGA_G <= 0;
     VGA_B <= 0;
    end

    // Player control
    r_player_control_count <= r_player_control_count + 1;
    if(r_player_control_count == 0)
    begin
     if (BTN[3] && r_player_x < DISPLAY_WIDTH - 32)
       r_player_x <= r_player_x + 1;
     if (BTN[2] && r_player_x > 0)
       r_player_x <= r_player_x - 1;
     if (BTN[4] && r_player_y < DISPLAY_HEIGHT - 32)
       r_player_y <= r_player_y + 1;
     if (BTN[1] && r_player_y > 0)
       r_player_y <= r_player_y - 1;
    end

    // Torpedo
    r_diff_torpedo_enemy_x <= (r_enemy_x > r_torpedo_x) ? (r_enemy_x - r_torpedo_x) : (r_torpedo_x - r_enemy_x);
    r_diff_torpedo_enemy_y <= (r_enemy_y > r_torpedo_y) ? (r_enemy_y - r_torpedo_y) : (r_torpedo_y - r_enemy_y);
    r_diff_player_enemy_x  <= (r_enemy_x > r_player_x)  ? (r_enemy_x - r_player_x)  : (r_player_x  - r_enemy_x);
    r_diff_player_enemy_y  <= (r_enemy_y > r_player_y)  ? (r_enemy_y - r_player_y)  : (r_player_y  - r_enemy_y);
    r_torpedo_movement_counter <= r_torpedo_movement_counter + 1;
    r_torpedo_y <= ((r_torpedo_movement_counter == 0) && (r_torpedo_status == 1)) ? r_torpedo_y - 1 : r_torpedo_y;
    r_torpedo_status <= (r_torpedo_y == 0) ? 0 :
                       (((r_diff_torpedo_enemy_x < ((TORPEDO_WIDTH  + ENEMY_SIZE) / 2)) &&
                         (r_diff_torpedo_enemy_y < ((TORPEDO_HEIGHT + ENEMY_SIZE) / 2)))
                         ? 0 : r_torpedo_status);
    r_torpedo_color <= SW[11:0];
    if(r_torpedo_status == 0 && BTN[0])
    begin
     r_torpedo_status <= 1;
     r_torpedo_x <= r_player_x;
     r_torpedo_y <= r_player_y;
    end

    // Enemy
    r_enemy_color_counter <= r_enemy_color_counter + 1;
    r_enemy_control_counter <= r_enemy_control_counter + 1;
    if (r_enemy_control_counter == 0)
    begin
      r_enemy_x <= ((r_enemy_x + ENEMY_SIZE) > (r_player_x + 16)) ? r_enemy_x - 1 : r_enemy_x + 1;
      r_enemy_y <= ((r_enemy_y + ENEMY_SIZE) > (r_player_y + 16)) ? r_enemy_y - 1 : r_enemy_y + 1;
    end
    r_enemy_color <= w_random_color;

    // Hit detection
    if (((r_diff_torpedo_enemy_x < ((TORPEDO_WIDTH  + ENEMY_SIZE) / 2)) &&
      (r_diff_torpedo_enemy_y < ((TORPEDO_HEIGHT + ENEMY_SIZE) / 2))) &&
      (r_torpedo_status == 1))
    begin
     r_enemy_hit_points <= (r_enemy_hit_points > (1 + (r_enemy_color == r_torpedo_color) * 10000)) ? (r_enemy_hit_points - (1 + (r_enemy_color == r_torpedo_color) * 10000)) : 0;
    end
    if (((r_diff_player_enemy_x < ((32 + ENEMY_SIZE) / 2)) &&
         (r_diff_player_enemy_y < ((32 + ENEMY_SIZE) / 2))) &&
       (r_enemy_hit_points > 0))
    begin
     r_player_status <= 0;
    end

    // Draw to VRAM
    if      (w_player_draw && r_player_status)           r_vram_datain <= w_player_dataout;
    else if (w_enemy_draw && (r_enemy_hit_points > 0))   r_vram_datain <= 4'b0010;
    else if (w_torpedo_draw && r_torpedo_status)         r_vram_datain <= 4'b0001;
    else                                                 r_vram_datain <= w_background_dataout;

    r_vram_address <= w_display_y * DISPLAY_WIDTH + w_display_x;
    // Display content of active VRAM
    r_vram_dataout_buffer <= w_vram_dataout;
    r_display_out <= (r_vram_dataout_buffer == 4'b0010) ? r_enemy_color :
                   ((r_vram_dataout_buffer == 4'b0001) ? r_torpedo_color : r_player_palette[r_vram_dataout_buffer]);
  end
endmodule
