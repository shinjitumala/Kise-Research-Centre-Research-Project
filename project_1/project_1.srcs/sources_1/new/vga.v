

module vga_sync
(
  input  wire iw_clk, iw_reset,
  output wire ow_hsync, ow_vsync, ow_video_on, ow_p_tick,
  output wire [9:0] ow_x, ow_y
  );

  // local constants
  localparam H_DISPLAY      = 800;
  localparam H_FRONT_PORCH  = 40;
  localparam H_BACK_PORCH   = 88;
  localparam H_PULSE        = 128;
  localparam H_MAX          = H_DISPLAY + H_FRONT_PORCH + H_BACK_PORCH + H_PULSE - 1;
  localparam H_START        = H_DISPLAY + H_BACK_PORCH;
  localparam H_END          = H_DISPLAY + H_BACK_PORCH + H_PULSE - 1;

  localparam V_DISPLAY      = 600;
  localparam V_FRONT_PORCH  = 1;
  localparam V_BACK_PORCH   = 23;
  localparam V_PULSE        = 4;
  localparam V_MAX          = V_DISPLAY + V_FRONT_PORCH + V_BACK_PORCH + V_PULSE - 1;
  localparam V_START        = V_DISPLAY + V_BACK_PORCH;
  localparam V_END          = V_DISPLAY + V_BACK_PORCH + V_PULSE - 1;

  // mod-4 counter to generate 25 MHz pixel tick
  reg  [1:0] r_pixel;
  wire [1:0] w_pixel_next;
  wire       w_pixel_tick;

  always @(posedge iw_clk, posedge iw_reset)
    if(iw_reset)
      r_pixel <= 0;
    else
      r_pixel <= w_pixel_next;

  assign w_pixel_next = r_pixel + 1;
  assign w_pixel_tick = (r_pixel == 0);

  // registries too keep track of current pixel locaion
  reg  [9:0] r_h_count, r_h_next, r_v_count, r_v_next;

  // registries to keep track of vsync and hsync signal states
  reg        r_vsync, r_hsync;
  wire       w_next_vsync, w_next_hsync;

  // infer registries
  always @(posedge iw_clk, posedge iw_reset)
    if(iw_reset) begin
      r_v_count <= 0;
      r_h_count <= 0;
      r_vsync <= 0;
      r_hsync <= 0;
    end
    else begin
      r_v_count <= r_v_next;
      r_h_count <= r_h_next;
      r_vsync <= w_next_vsync;
      r_hsync <= w_next_hsync;
    end

  // next state logic of horizontal vertial sync counters
  always @* begin
    r_h_next = w_pixel_tick ? r_h_count == H_MAX ? 0 : r_h_count + 1 : r_h_count;
    r_v_next = w_pixel_tick ? r_v_count == V_MAX ? 0 : r_v_count + 1 : r_v_count;
  end

  // hsync and vsync are active low signals
  // hsync signal asserted during horizontal retrace
  assign w_next_hsync = r_h_count >= H_START
                      && r_h_count <= H_END;

  // vsync signal asserted during vertical retrace
  assign w_next_vsync = r_v_count >= V_START
                      && r_v_count <= V_END;

  // video only on when pixels are in both horizontal and vertical display region
  assign ow_video_on = (r_h_count < H_DISPLAY)
                    && (r_v_count < V_DISPLAY);

  // output signals
  assign ow_hsync  = r_hsync;
  assign ow_vsync  = r_vsync;
  assign ow_x      = r_h_count;
  assign ow_y      = r_v_count;
  assign ow_p_tick = w_pixel_tick;

endmodule

module vga_test
  (
    input wire CLK100MHZ,
    input  wire [15:0] SW,
    input  wire [4:0]      BTN,
    output wire VGA_HS, VGA_VS,
    output wire [3:0]  VGA_R, VGA_G, VGA_B,
    output wire [2:0]  LED16
    );
  reg  [11:0] r_rgb;
  wire        w_clk, w_lock;



  always @(posedge w_clk) r_rgb <= SW;
  assign VGA_R = SW[3:0];
  assign VGA_G = SW[7:4];
  assign VGA_B = SW[11:8];
  assign LED16[0] = w_clk;
  wire [9:0] w_x, w_y;
  wire video_on, p_tick;

  clk_wiz_0 clk (w_clk, 1'd1, w_lock, CLK100MHZ);

  vga_sync vga_sync_unit (w_clk, BTN[0], VGA_HS, VGA_VS, video_on, p_tick, w_x, w_y);
endmodule
