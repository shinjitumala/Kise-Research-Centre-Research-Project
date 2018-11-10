module m_engine
(
  input  wire        CLK100MHZ, // 100MHZ clock.
  input  wire [4:0]  BTN,       // Buttons frorm 0 to 4,
                                // center, up, left, right, down
  input  wire [15:0] SW,        // 16 switches
  output wire [6:0]  SG,        // 7 segment display controller
  output wire [7:0]  AN,        // 7 segment display controller
  output wire [15:0] LED,       // 16 LEDs
  output wire [2:0]  LED16,     // Colorful LED 1
  output wire [2:0]  LED17,     // Colorful LED 2
  output wire        VGA_HS,    // VGA horizontal sync signal
  output wire        VGA_VS,    // VGA vertical sync signal
  output reg  [3:0]  VGA_R,     // VGA red output
  output reg  [3:0]  VGA_G,     // VGA green output
  output reg  [3:0]  VGA_B      // VGA blue output
);
  /****************************************************************************/
  // Simulation
  /****************************************************************************/
  // You also have to comment out the definition of w_display_clock, CLK100MHZ
  // and display_clock (instance of CLK40MHZ).

  // reg  r_display_clock = 0;
  // wire w_display_clock;
  // initial forever #1 w_display_clock = ~w_display_clock;
  //
  // assign w_display_clock = r_display_clock;
  /****************************************************************************/

  /****************************************************************************/
  // Display
  /****************************************************************************/
  wire        w_display_clock;  // The clock for the display. In this case, it
                                //  is also used for the entire game.
  wire [9:0]  w_display_x;      // The x axis of the pixel currently drawn.
  wire [9:0]  w_display_y;      // The y axis of the pixel currently drawn.
  wire        w_display_active; // High while drawing on the screen.
  wire        w_display_reset;  // Screen will reset when set to high.
  reg  [11:0] r_display_out;    // VGA color output.

  // 40MHZ clock
  CLK40MHZ display_clock (w_display_clock, CLK100MHZ);

  assign w_display_reset = SW[15];

  // "VideoIO/VGA/vga_sync.v"
  m_vga display
  (
    .iw_clock  (w_display_clock),
    .iw_rst    (w_display_reset),
    .ow_hs     (VGA_HS),
    .ow_vs     (VGA_VS),
    .ow_x      (w_display_x),
    .ow_y      (w_display_y),
    .ow_active (w_display_active)
  );
  /****************************************************************************/

  /****************************************************************************/
  // VRAM
  /****************************************************************************/
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19; // Make sure it is large enough for the VRAM.
                                   // In this case, '2^19 > 800 * 600'.
  localparam VRAM_DATA_WIDTH = 4;  // Color depth per pixel.
                                   // VRAM is 4 bits but I cheated the game is
                                   // actually 12 bit color.

  wire [VRAM_ADDR_WIDTH - 1:0] w_vram_address; // Read and write address for
                                               // the VRAM.
  wire [VRAM_DATA_WIDTH - 1:0] w_vram_dataout; // Output data from the VRAM.
  reg  [VRAM_DATA_WIDTH - 1:0] r_vram_datain;  // Input data for the VRAM.

  assign w_vram_address = w_display_y * DISPLAY_WIDTH + w_display_x;

  // "VideoIO/vram.v"
  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH)
  )
  vram
  (
    .iw_addr  (w_vram_address),
    .iw_clock (w_display_clock),
    .iw_write (1),
    .or_data  (w_vram_dataout),
    .iw_data  (r_vram_datain)
  );

  // Game palette
  reg [11:0] r_game_palette [0:15];
  initial
  begin
    $display("Loading sprite r_game_palette.");
    $readmemh("fpr_palette.mem", r_game_palette);
  end
  /****************************************************************************/

  /****************************************************************************/
  // Game Logic
  /****************************************************************************/
  //--------------------------------------------------------------------------//
  // Parameters
  //--------------------------------------------------------------------------//
  // Player
  localparam PLAYER_SIZE                = 32;
  localparam PLAYER_INIT_X              = DISPLAY_WIDTH / 2 + PLAYER_SIZE / 2;
  localparam PLAYER_INIT_Y              = DISPLAY_HEIGHT - PLAYER_SIZE;
  reg [15:0] r_player_control_count     = 0;     // Player movement speed.

  // Torpedo
  localparam TORPEDO_WIDTH              = 16;
  localparam TORPEDO_HEIGHT             = 32;
  localparam TORPEDO_BASE_DAMAGE        = 1;
  localparam TORPEDO_COLOR_BONUS_DAMAGE = 10000;
  reg [13:0] r_torpedo_movement_counter = 0; // Torpedo movement speed.

  // Enemy
  localparam ENEMY_SIZE                 = 128;
  localparam ENEMY_HIT_POINTS           = 24'd10000000;
  localparam ENEMY_INIT_X               = DISPLAY_WIDTH / 2 + ENEMY_SIZE / 2;
  localparam ENEMY_INIT_Y               = 0;
  reg [21:0] r_enemy_control_counter    = 0;    // Enemy movement speed.
  reg [28:0] r_enemy_color_counter      = 0;      // Enemy color change rate.

  // Game
  reg [27:0] r_game_start_counter       = 1;       // Game start delay.
  //--------------------------------------------------------------------------//

  //--------------------------------------------------------------------------//
  // Player
  //--------------------------------------------------------------------------//
  reg  [9:0]                   r_player_x, r_player_y;
  wire                         w_player_draw;
  wire [VRAM_DATA_WIDTH - 1:0] w_player_dataout;
  reg                          r_player_status;

  // "VideoIO/entity.v"
  m_entity
  #(
    .ADDR_WIDTH  (10),
    .DATA_WIDTH  (VRAM_DATA_WIDTH),
    .ENTITY_SIZE (PLAYER_SIZE),
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
  //--------------------------------------------------------------------------//

  //--------------------------------------------------------------------------//
  // Torpedo
  //--------------------------------------------------------------------------//
  reg [11:0] r_torpedo_color;
  reg [9:0]  r_torpedo_x, r_torpedo_y;
  wire       w_torpedo_draw;
  reg        r_torpedo_status;

  // "Game/Engine/torpedo.v"
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
  //--------------------------------------------------------------------------//

  //--------------------------------------------------------------------------//
  // Enemy
  //--------------------------------------------------------------------------//
  reg [11:0] r_enemy_color;
  reg [9:0]  r_enemy_x, r_enemy_y;
  wire       w_enemy_draw;
  reg [23:0] r_enemy_hit_points;

  // Color Generator
  wire [11:0] w_random_color;
  wire        w_random_generate;
  // "Utils/random_color.v"
  m_random_color rng (w_display_clock, w_random_generate, w_random_color);

  assign w_random_generate = (r_enemy_color_counter == 0);

  // "Game/Engine/enemy.v"
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

  // Display enemy hit points
  // "7SegDisplay/7seg.v"
  m_int_7seg enemy_hitpoints_display
  (
    .iw_clock (w_display_clock),
    .iw_int   ({8'b00000000, r_enemy_hit_points}),
    .or_sg    (SG),
    .or_an    (AN)
  );
  //--------------------------------------------------------------------------//

  //--------------------------------------------------------------------------//
  // Background
  //--------------------------------------------------------------------------//
  wire [11:0] w_background_address;
  wire [3:0]  w_background_dataout;

  assign w_background_address = (w_display_y % 50 * 50) + (w_display_x % 50);

  // "VideoIO/vram.v"
  m_sram
  #(
    .ADDR_WIDTH (12),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (50 * 50),
    .MEMFILE    ("background.mem")
  )
  background
  (
    .iw_clock (w_display_clock),
    .iw_addr  (w_background_address),
    .iw_write (0),
    .iw_data  (0),
    .or_data  (w_background_dataout)
  );
  //--------------------------------------------------------------------------//

  //--------------------------------------------------------------------------//
  // Wires
  //--------------------------------------------------------------------------//
  wire [9:0] w_diff_torpedo_enemy_x, w_diff_torpedo_enemy_y, w_diff_player_enemy_x, w_diff_player_enemy_y;

  assign w_diff_torpedo_enemy_x = (r_enemy_x > r_torpedo_x) ? (r_enemy_x - r_torpedo_x) : (r_torpedo_x - r_enemy_x);
  assign w_diff_torpedo_enemy_y = (r_enemy_y > r_torpedo_y) ? (r_enemy_y - r_torpedo_y) : (r_torpedo_y - r_enemy_y);
  assign w_diff_player_enemy_x  = (r_enemy_x > r_player_x)  ? (r_enemy_x - r_player_x)  : (r_player_x  - r_enemy_x);
  assign w_diff_player_enemy_y  = (r_enemy_y > r_player_y)  ? (r_enemy_y - r_player_y)  : (r_player_y  - r_enemy_y);

  // LEDs
  assign LED = {SW[15], r_player_status, r_torpedo_status, (r_enemy_hit_points > 0), r_enemy_color};
  assign LED16 = {r_torpedo_color[11], r_torpedo_color[7], r_torpedo_color[3]};
  assign LED17 = {r_enemy_color[11], r_enemy_color[7], r_enemy_color[3]};
  //--------------------------------------------------------------------------//

  //--------------------------------------------------------------------------//
  // Registers
  //--------------------------------------------------------------------------//
  always @(posedge w_display_clock)
  begin
    // Game
    r_game_start_counter = (r_game_start_counter == 0) ? r_game_start_counter : r_game_start_counter + 1;

    // Initialize game`
    if(r_game_start_counter == 1000 || SW[14])
    begin
      // Player
      r_player_x <= PLAYER_INIT_X;
      r_player_y <= PLAYER_INIT_Y;
      r_player_status <= 1;

      // Torpedo
      r_torpedo_x <= 0;
      r_torpedo_y <= 0;
      r_torpedo_status <= 0;

      // Enemy
      r_enemy_x <= ENEMY_INIT_X;
      r_enemy_y <= ENEMY_INIT_Y;
      r_enemy_hit_points <= ENEMY_HIT_POINTS;
    end

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

    // Player movement
    r_player_control_count <= r_player_control_count + 1;
    if(r_player_control_count == 0)
    begin
     if (BTN[3] && r_player_x < DISPLAY_WIDTH - PLAYER_SIZE)
       r_player_x <= r_player_x + 1;
     if (BTN[2] && r_player_x > 0)
       r_player_x <= r_player_x - 1;
     if (BTN[4] && r_player_y < DISPLAY_HEIGHT - PLAYER_SIZE)
       r_player_y <= r_player_y + 1;
     if (BTN[1] && r_player_y > 0)
       r_player_y <= r_player_y - 1;
    end

    // Torpedo movement
    r_torpedo_movement_counter <= r_torpedo_movement_counter + 1;
    r_torpedo_y <= ((r_torpedo_movement_counter == 0) && (r_torpedo_status == 1)) ? r_torpedo_y - 1 : r_torpedo_y;
    r_torpedo_status <= (r_torpedo_y == 0) ? 0 : r_torpedo_status;
    r_torpedo_color <= SW[11:0];

    // Torpedo firing
    if(r_torpedo_status == 0 && BTN[0] && r_player_status)
    begin
     r_torpedo_status <= 1;
     r_torpedo_x <= r_player_x + PLAYER_SIZE / 2 - TORPEDO_WIDTH / 2;
     r_torpedo_y <= r_player_y + PLAYER_SIZE / 2 - TORPEDO_WIDTH / 2;
    end

    // Enemy movement
    r_enemy_control_counter <= r_enemy_control_counter + 1;
    if (r_enemy_control_counter == 0 && (r_game_start_counter == 1'b0 && SW[13]))
    begin
      r_enemy_x <= ((r_enemy_x + ENEMY_SIZE / 2) > (r_player_x + PLAYER_SIZE / 2)) ? r_enemy_x - 1 : r_enemy_x + 1;
      r_enemy_y <= ((r_enemy_y + ENEMY_SIZE / 2) > (r_player_y + PLAYER_SIZE / 2)) ? r_enemy_y - 1 : r_enemy_y + 1;
    end

    // Enemy color
    r_enemy_color_counter <= r_enemy_color_counter + 1;
    r_enemy_color <= (SW[12]) ? r_enemy_color : w_random_color;

    // Torpedo hit enemy
    if (((w_diff_torpedo_enemy_x < ((TORPEDO_WIDTH  + ENEMY_SIZE) / 2)) &&
      (w_diff_torpedo_enemy_y < ((TORPEDO_HEIGHT + ENEMY_SIZE) / 2))) &&
      (r_torpedo_status == 1) && (r_game_start_counter == 1'b0) && (r_enemy_hit_points > 0))
    begin
      r_enemy_hit_points <=   (r_enemy_hit_points > (TORPEDO_BASE_DAMAGE + (r_enemy_color == r_torpedo_color) * TORPEDO_COLOR_BONUS_DAMAGE))
                                ? (r_enemy_hit_points - (TORPEDO_BASE_DAMAGE + (r_enemy_color == r_torpedo_color) * TORPEDO_COLOR_BONUS_DAMAGE))
                                : 0;
      r_torpedo_status <= 0;
    end

    // Enemy hit player
    if (((w_diff_player_enemy_x < ((PLAYER_SIZE + ENEMY_SIZE) / 2)) &&
         (w_diff_player_enemy_y < ((PLAYER_SIZE + ENEMY_SIZE) / 2))) &&
       (r_enemy_hit_points > 0) && (r_game_start_counter == 1'b0))
    begin
      r_player_status <= 0;
    end

    // Draw to VRAM
    // And yes, I cheated. The VRAM is 4 bits but the video output is 12 bits.
    if      (w_player_draw && r_player_status)           r_vram_datain <= w_player_dataout;
    else if (w_enemy_draw && (r_enemy_hit_points > 0))   r_vram_datain <= 4'b0010;
    else if (w_torpedo_draw && r_torpedo_status)         r_vram_datain <= 4'b0001;
    else                                                 r_vram_datain <= w_background_dataout;

    // VRAM to Display
    r_display_out <= (w_vram_dataout == 4'b0010) ? r_enemy_color :
                    ((w_vram_dataout == 4'b0001) ? r_torpedo_color : r_game_palette[w_vram_dataout]);

  end
  //--------------------------------------------------------------------------//
  /****************************************************************************/
endmodule
