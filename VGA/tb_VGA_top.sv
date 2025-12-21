`timescale 1ns / 1ps

module tb_VGA_top;

    // =====================
    // Входы DUT
    // =====================
    logic clk_100m;
    logic btn_rst_n;
    logic pulse;

    // Данные датчиков
    logic [7:0] temp_int;
    logic [7:0] temp_dec;
    logic [7:0] dist_int;
    logic [7:0] dist_dec;
    logic [7:0] hum_int;

    // =====================
    // Выходы DUT
    // =====================
    logic vga_hsync;
    logic vga_vsync;
    logic vga_r;
    logic vga_g;
    logic vga_b;

    // =====================
    // Инстанцирование DUT
    // =====================
    VGA_top uut (
        .clk_100m   (clk_100m),
        .btn_rst_n  (btn_rst_n),
        .pulse      (pulse),

        .temp_int   (temp_int),
        .temp_dec   (temp_dec),
        .dist_int   (dist_int),
        .dist_dec   (dist_dec),
        .hum_int    (hum_int),

        .vga_hsync  (vga_hsync),
        .vga_vsync  (vga_vsync),
        .vga_r      (vga_r),
        .vga_g      (vga_g),
        .vga_b      (vga_b)
    );

    // =====================
    // Генерация такта 100 МГц
    // =====================
    initial begin
        clk_100m = 0;
        forever #5 clk_100m = ~clk_100m; // период 10 нс
    end

    // =====================
    // Основной сценарий теста
    // =====================
    initial begin
        // Начальные значения
        btn_rst_n = 0;
        pulse     = 0;   // режим температуры

        temp_int = 8'd24;
        temp_dec = 8'd2;
        dist_int = 8'd222;
        dist_dec = 8'd1;
        hum_int  = 8'd75;

        // Сброс системы
        #100;
        btn_rst_n = 1;
        $display("Reset released. TEMP mode active.");

        // --- Этап 1: режим температуры ---
        #50_000_000;

        // --- Этап 2: переключение режима ---
        pulse = 1;
        #100;
        pulse = 0;
        $display("Time %0t: Switched to DISTANCE mode.", $time);

        // --- Этап 3: режим расстояния ---
        #50_000_000;

        // Завершение симуляции
        $display("Simulation finished.");
        $finish;
    end

endmodule
