// FPGA VGA Graphics Part 3: Top Module (background only)
// (C)2018 Will Green - Licensed under the MIT License
// Learn more at https://timetoexplore.net/blog/arty-fpga-vga-verilog-03

`default_nettype none

module top(
    input wire CLK100MHZ,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire [4:0] BTN,         // reset button
    output wire VGA_HS,       // horizontal sync output
    output wire VGA_VS,       // vertical sync output
    output reg [3:0] VGA_R,     // 4-bit VGA red output
    output reg [3:0] VGA_G,     // 4-bit VGA green output
    output reg [3:0] VGA_B      // 4-bit VGA blue output
    );

    wire rst = 0;

    // generate a 25 MHz pixel strobe
    wire w_clock;
    CLK40MHZ clk (w_clock, CLK100MHZ);

    wire [10:0] x;       // current pixel x position: 10-bit value: 0-1023
    wire [10:0] y;       // current pixel y position:  9-bit value: 0-511
    wire active;        // high during active pixel drawing

    m_vga display (
      .iw_clock (w_clock),
      .iw_rst   (rst),
      .ow_hs    (VGA_HS),
      .ow_vs    (VGA_VS),
      .ow_x     (x),
      .ow_y     (y),
      .ow_activ (active)
    );

    // VRAM frame buffers (read-write)
    localparam SCREEN_WIDTH = 800;
    localparam SCREEN_HEIGHT = 600;
    localparam VRAM_DEPTH = SCREEN_WIDTH * SCREEN_HEIGHT;
    localparam VRAM_A_WIDTH = 20;  // 2^16 > 320 x 180
    localparam VRAM_D_WIDTH = 8;   // colour bits per pixel

    reg [VRAM_A_WIDTH-1:0] address_a, address_b;
    reg [VRAM_D_WIDTH-1:0] datain_a, datain_b;
    wire [VRAM_D_WIDTH-1:0] dataout_a, dataout_b;
    reg we_a = 0, we_b = 1;  // write enable bit

    // frame buffer A VRAM
    m_sram #(
        .ADDR_WIDTH(VRAM_A_WIDTH),
        .DATA_WIDTH(VRAM_D_WIDTH),
        .DEPTH(VRAM_DEPTH),
        .MEMFILE(""))
        vram_a (
        .iw_addr(address_a),
        .iw_clock(CLK100MHZ),
        .iw_write(we_a),
        .iw_data(datain_a),
        .or_data(dataout_a)
    );

    // frame buffer B VRAM
    m_sram #(
        .ADDR_WIDTH(VRAM_A_WIDTH),
        .DATA_WIDTH(VRAM_D_WIDTH),
        .DEPTH(VRAM_DEPTH),
        .MEMFILE(""))
        vram_b (
        .iw_addr(address_b),
        .iw_clock(CLK100MHZ),
        .iw_write(we_b),
        .iw_data(datain_b),
        .or_data(dataout_b)
    );

    // sprite buffer (read-only)
    localparam SPRITE_SIZE = 32;  // dimensions of square sprites in pixels
    localparam SPRITE_COUNT = 8;  // number of sprites in buffer
    localparam SPRITEBUF_D_WIDTH = 8;  // colour bits per pixel
    localparam SPRITEBUF_DEPTH = SPRITE_SIZE * SPRITE_SIZE * SPRITE_COUNT;
    localparam SPRITEBUF_A_WIDTH = 13;  // 2^13 == 8,096 == 32 x 256

    reg [SPRITEBUF_A_WIDTH-1:0] address_s;
    wire [SPRITEBUF_D_WIDTH-1:0] dataout_s;

    // sprite buffer memory
    m_sram #(
        .ADDR_WIDTH(SPRITEBUF_A_WIDTH),
        .DATA_WIDTH(SPRITEBUF_D_WIDTH),
        .DEPTH(SPRITEBUF_DEPTH),
        .MEMFILE("sprites.mem"))
        spritebuf (
        .iw_addr(address_s),
        .iw_clock(CLK100MHZ),
        .iw_write(0),  // read only
        .iw_data(0),
        .or_data(dataout_s)
    );

    reg [11:0] palette [0:255];  // 256 x 12-bit colour palette entries
    reg [11:0] colour;
    initial begin
        $display("Loading palette.");
        $readmemh("sprites_palette.mem", palette);
    end

    // sprites to load and position of player sprite in frame
    localparam SPRITE_BG_INDEX = 7;  // background sprite
    localparam SPRITE_PL_INDEX = 0;  // player sprite
    localparam SPRITE_BG_OFFSET = SPRITE_BG_INDEX * SPRITE_SIZE * SPRITE_SIZE;
    localparam SPRITE_PL_OFFSET = SPRITE_PL_INDEX * SPRITE_SIZE * SPRITE_SIZE;
    localparam SPRITE_PL_X = SCREEN_WIDTH - SPRITE_SIZE >> 1; // centre
    localparam SPRITE_PL_Y = SCREEN_HEIGHT - SPRITE_SIZE;     // bottom

    reg [9:0] draw_x;
    reg [8:0] draw_y;
    reg [9:0] pl_x = SPRITE_PL_X;
    reg [9:0] pl_y = SPRITE_PL_Y;
    reg [9:0] pl_pix_x;
    reg [8:0] pl_pix_y;

    // pipeline registers for for address calculation
    reg [VRAM_A_WIDTH-1:0] address_fb1;
    reg [VRAM_A_WIDTH-1:0] address_fb2;

    always @ (posedge CLK100MHZ)
    begin
        // reset drawing
        if (rst)
        begin
            draw_x <= 0;
            draw_y <= 0;
            pl_x <= SPRITE_PL_X;
            pl_y <= SPRITE_PL_Y;
            pl_pix_x <= 0;
            pl_pix_y <= 0;
        end

        // draw background
        if (address_fb1 < VRAM_DEPTH)
        begin
            if (draw_x < SCREEN_WIDTH)
                draw_x <= draw_x + 1;
            else
            begin
                draw_x <= 0;
                draw_y <= draw_y + 1;
            end

            // calculate address of sprite and frame buffer (with pipeline)
            address_s <= SPRITE_BG_OFFSET +
                        (SPRITE_SIZE * draw_y[4:0]) + draw_x[4:0];
            address_fb1 <= (SCREEN_WIDTH * draw_y) + draw_x;
            address_fb2 <= address_fb1;

            if (we_a)
            begin
                address_a <= address_fb2;
                datain_a <= dataout_s;
            end
            else
            begin
                address_b <= address_fb2;
                datain_b <= dataout_s;
            end
        end

        // draw player ship
        if (address_fb1 >= VRAM_DEPTH)  // background drawing is finished
        begin
            if (pl_pix_y < SPRITE_SIZE)
            begin
                if (pl_pix_x < SPRITE_SIZE - 1)
                    pl_pix_x <= pl_pix_x + 1;
                else
                begin
                    pl_pix_x <= 0;
                    pl_pix_y <= pl_pix_y + 1;
                end

                address_s <= SPRITE_PL_OFFSET
                			+ (SPRITE_SIZE * pl_pix_y) + pl_pix_x;
                address_fb1 <= SCREEN_WIDTH * (pl_y + pl_pix_y)
                			+ pl_x + pl_pix_x;
                address_fb2 <= address_fb1;

                if (we_a)
                begin
                    address_a <= address_fb2;
                    datain_a <= dataout_s;
                end
                else
                begin
                    address_b <= address_fb2;
                    datain_b <= dataout_s;
                end
            end
        end

        if (w_clock)  // once per pixel
        begin
            if (we_a)  // when drawing to A, output from B
            begin
                address_b <= y * SCREEN_WIDTH + x;
                colour <= active ? palette[dataout_b] : 0;
            end
            else  // otherwise output from A
            begin
                address_a <= y * SCREEN_WIDTH + x;
                colour <= active ? palette[dataout_a] : 0;
            end
        end

        VGA_R <= colour[11:8];
        VGA_G <= colour[7:4];
        VGA_B <= colour[3:0];
    end

    always @(negedge active)
    begin
        we_a <= ~we_a;
        we_b <= ~we_b;
        // reset background position at start of frame
        draw_x <= 0;
        draw_y <= 0;
        // reset player position
        pl_pix_x <= 0;
        pl_pix_y <= 0;
        // reset frame address
        address_fb1 <= 0;

        // update ship position based on switches
        if (BTN[1] && pl_x < SCREEN_WIDTH - SPRITE_SIZE)
            pl_x <= pl_x + 1;
        if (BTN[4] && pl_x > 0)
            pl_x <= pl_x - 1;
        if (BTN[2] && pl_y < SCREEN_HEIGHT - SPRITE_SIZE)
            pl_y <= pl_y + 1;
        if (BTN[3] & pl_y > 0)
            pl_y <= pl_y - 1;
    end
endmodule
