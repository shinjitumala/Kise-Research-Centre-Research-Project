`default_nettype none

module m_test0
(
  //input  wire        CLK100MHZ,
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
  wire w_vclk;
  //CLK40MHZ clk (w_vclk, CLK100MHZ);

  wire [10:0] w_x;
  wire [10:0] w_y;
  wire        w_activ;
  wire        w_reset;

  assign w_reset = 0;

  m_vga display
  (
    .iw_clock (w_vclk),
    .iw_rst   (w_reset),
    .ow_hs    (VGA_HS),
    .ow_vs    (VGA_VS),
    .ow_x     (w_x),
    .ow_y     (w_y),
    .ow_activ (w_activ)
  );

  // VRAM
  localparam DISPLAY_WIDTH   = 800;
  localparam DISPLAY_HEIGHT  = 600;
  localparam VRAM_DEPTH      = DISPLAY_WIDTH * DISPLAY_HEIGHT;
  localparam VRAM_ADDR_WIDTH = 19;
  localparam VRAM_DATA_WIDTH = 8;

  reg  [VRAM_ADDR_WIDTH - 1:0] r_address0, r_address1;
  reg  [VRAM_DATA_WIDTH - 1:0] r_datain0, r_datain1;
  wire [VRAM_DATA_WIDTH - 1:0] w_dataout0, w_dataout1;
  reg r_write0 = 0, r_write1 = 1;

  // Frame buffer 0
  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH),
    .MEMFILE    ("")
  )
  vram0
  (
    .iw_addr  (r_address0),
    .iw_clock (CLK100MHZ),
    .iw_write (r_write0),
    .or_data  (w_dataout0),
    .iw_data  (r_datain0)
  );

  // Frame buffer 1
  m_sram
  #(
    .ADDR_WIDTH (VRAM_ADDR_WIDTH),
    .DATA_WIDTH (VRAM_DATA_WIDTH),
    .DEPTH      (VRAM_DEPTH),
    .MEMFILE    ("")
  )
  vram1
  (
    .iw_addr  (r_address1),
    .iw_clock (CLK100MHZ),
    .iw_write (r_write1),
    .or_data  (w_dataout1),
    .iw_data  (r_datain1)
  );

  // Sprite data
  localparam SPRITE_SIZE = 32;
  localparam SPRITE_COUNT = 8;
  localparam SPRITE_DATA_WIDTH = 8;
  localparam SPRITE_DEPTH = SPRITE_SIZE * SPRITE_SIZE * SPRITE_COUNT;
  localparam SPRITE_ADDR_WIDTH = 13;

  reg  [SPRITE_DATA_WIDTH - 1:0] r_sp_address;
  wire [SPRITE_DATA_WIDTH - 1:0] r_sp_data;

  // Sprite memory
  m_sram
  #(
    .ADDR_WIDTH (SPRITE_ADDR_WIDTH),
    .DATA_WIDTH (SPRITE_DATA_WIDTH),
    .DEPTH      (SPRITE_DEPTH),
    .MEMFILE    ("sprites.mem")
  )
  vram
  (
    .iw_addr  (r_sp_address),
    .iw_clock (CLK100MHZ),
    .iw_write (0),
    .or_data  (r_sp_data),
    .iw_data  (0)
  );

  reg [11:0] r_sp_palette [0:255];
  reg [11:0] r_sp_color;
  initial
  begin
    $display("Loading sprite r_sp_palette.");
    $readmemh("sprites_palette.mem", r_sp_palette);
  end

  // Sprites to load and positions for the player
  localparam SPRITE_BACKGROUND_INDEX  = 7;
  localparam SPRITE_PLAYER_INDEX      = 0;
  localparam SPRITE_BACKGROUND_OFFSET = SPRITE_BACKGROUND_INDEX * SPRITE_SIZE * SPRITE_SIZE;
  localparam SPRITE_PLAYER_OFFSET     = SPRITE_PLAYER_INDEX * SPRITE_SIZE * SPRITE_SIZE;
  localparam SPRITE_PLAYER_INIT_X     = DISPLAY_WIDTH - SPRITE_SIZE >> 1;
  localparam SPRITE_PLAYER_INIT_Y     = DISPLAY_HEIGHT - SPRITE_SIZE;

  reg [10:0] r_x;
  reg [10:0] r_y;
  reg [10:0] r_px = SPRITE_PLAYER_INIT_X;
  reg [10:0] r_py = SPRITE_PLAYER_INIT_Y;
  reg [10:0] r_px_p, r_py_p;

  // Pipeline registers for adress
  reg [VRAM_ADDR_WIDTH - 1:0] r_addr_p0;
  reg [VRAM_ADDR_WIDTH - 1:0] r_addr_p1;

  always @ (posedge CLK100MHZ)
  begin
    // reset drawing
    if (0)
    begin
      r_x <= 0;
      r_y <= 0;
      r_px <= SPRITE_PLAYER_INIT_X;
      r_py <= SPRITE_PLAYER_INIT_Y;
      r_px_p <= 0;
      r_py_p <= 0;
    end

    // draw background
    if (r_addr_p0 < VRAM_DEPTH)
    begin
      if (r_x < DISPLAY_WIDTH)
        r_x <= r_x + 1;
      else
      begin
        r_x <= 0;
        r_y <= r_y + 1;
      end

      // calculate address of sprite and frame buffer (with pipeline)
      r_sp_address <= SPRITE_BACKGROUND_OFFSET +
                  (SPRITE_SIZE * r_y[4:0]) + r_x[4:0];
      r_addr_p0 <= (DISPLAY_WIDTH * r_y) + r_x;
      r_addr_p1 <= r_addr_p0;

      if (r_write0)
      begin
        r_address0 <= r_addr_p1;
        r_datain0 <= r_sp_data;
      end
      else
      begin
        r_address1 <= r_addr_p1;
        r_datain1 <= r_sp_data;
      end
    end
  end

  always @(posedge w_vclk)
  begin
    if (r_write0)  // when drawing to A, output from B
    begin
      r_address1 <= w_y * DISPLAY_WIDTH + w_x;
      r_sp_color <= w_activ ? r_sp_palette[w_dataout1] : 0;
    end
    else  // otherwise output from A
    begin
      r_address0 <= w_y * DISPLAY_WIDTH + w_x;
      r_sp_color <= w_activ ? r_sp_palette[w_dataout0] : 0;
    end

    // Draw player ship
    if (r_addr_p0 >= VRAM_DEPTH)  // background drawing is finished
    begin
      if (r_py_p < SPRITE_SIZE)
      begin
        if (r_px_p < SPRITE_SIZE - 1)
          r_px_p <= r_px_p + 1;
        else
        begin
          r_px_p <= 0;
          r_py_p <= r_py_p + 1;
        end

        r_sp_address <= SPRITE_PLAYER_OFFSET
                    + (SPRITE_SIZE * r_py_p) + r_px_p;
        r_addr_p0 <= DISPLAY_WIDTH * (r_py + r_py_p)
                    + r_px + r_px_p;
        r_addr_p1 <= r_addr_p0;

        if (r_write0)
        begin
          r_address0 <= r_addr_p1;
          r_datain0 <= r_sp_data;
        end
        else
        begin
          r_address1 <= r_addr_p1;
          r_datain1 <= r_sp_data;
        end
      end
    end
  end

  always @(negedge w_activ)
  begin
    r_write0 <= ~r_write0;
    r_write1 <= ~r_write1;
    // reset background position at start of frame
    r_x <= 0;
    r_y <= 0;
    // reset player position
    r_px_p <= 0;
    r_py_p <= 0;
    // reset frame address
    r_addr_p0 <= 0;


    // Ship control
    if (BTN[4] && r_px < DISPLAY_WIDTH - SPRITE_SIZE)
      r_px <= r_px + 1;
    if (BTN[1] && r_px > 0)
      r_px <= r_px - 1;
    if (BTN[3] && r_py < DISPLAY_HEIGHT - SPRITE_SIZE)
      r_py <= r_py + 1;
    if (BTN[2] && r_py > 0)
      r_py <= r_py - 1;
  end
endmodule
