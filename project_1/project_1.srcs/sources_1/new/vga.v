module vga_sync
(
  input  wire iw_clk, iw_reset,
  output wire ow_hsync, ow_symc, ow_video_on, ow_p_tick,
  output wire [9:0] ow_x, ow_y
  );

  // local constants
  localparam H_DISPLAY      = 800;
  localparam V_DISPLAY      = 600;

  // mod-4 counter to generate 25 MHz pixel tick
  reg  [1:0] r_pixel;
  wire [1:0] w_pixel_next;
  wire       w_pixel_tick;

  always @(posedge iw_clk, posedge iw_reset)
    if(reset)
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
    if(reset) begin
      r_v_count <= 0;
      r_h_count <= 0:
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
    r_h_next = w_pixel_tick ? r_h_count == H_DISPLAY ? 0 : r_h_count + 1 : r_h_count;
    r_v_next = w_pixel_tick ? r_v_count == V_DISPLAY ? 0 : r_v_count + 1 : r_v_count;
  end

endmodule

module vga_test
  (
    input  wire        CLK100MHZ;
    input  wire [15:0] SW;
    output wire ow_hsync, ow_vsync;
    output wire [3:0]  VGA_R, VGA_G, VGA_B;
    )
  reg  [11:0] r_rgb;

  always @(posedge CLK100MHZ) r_rgb <= SW;

  vga_sync vga_sync_unit (CLK100MHZ, 0, ow_hsync, ow_vsync, r_rgb);
endmodule
