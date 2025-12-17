`timescale 1ns / 1ps

module tb_VGA_top;

    // ====== CLOCK & RESET ======
    logic clk_100m;
    logic btn_rst_n;

    // ====== VGA OUTPUTS ======
    logic vga_hsync;
    logic vga_vsync;
    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;
    
    // ====== DUT ======
    VGA_top dut (
        .clk_100m  (clk_100m),
        .btn_rst_n (btn_rst_n),

        .vga_hsync (vga_hsync),
        .vga_vsync (vga_vsync),
        .vga_r     (vga_r),
        .vga_g     (vga_g),
        .vga_b     (vga_b)
    );

    // ====== 100 MHz CLOCK ======
    initial clk_100m = 0;
    always #5 clk_100m = ~clk_100m; // 10 ns period → 100 MHz

    // ====== TEST SEQUENCE ======
    initial begin
        btn_rst_n = 0;
        #1000;        // ← не 200 нс, а минимум 1 мкс
        btn_rst_n = 1;
    end

endmodule
