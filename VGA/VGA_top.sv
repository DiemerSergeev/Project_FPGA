module VGA_top
(
    input wire logic [7:0] temp_int, temp_dec, // Data temp
    input wire logic [7:0] hum_int, hum_dec,   // Data Hum
    input wire logic [7:0] dist_int, dist_dec, // Data Dist
    
    input wire logic pulse,  // 0 - Temp/Hum, 1 - Distance
    input logic clk_100m,
    input logic btn_rst_n,
    
    output logic vga_hsync,
    output logic vga_vsync,
    output logic vga_r,
    output logic vga_g,
    output logic vga_b
);

// ========== ПАРАМЕТРЫ И СИГНАЛЫ ==========
logic clk_pix;
logic [1:0] q;

// VGA координаты
localparam CORDW = 10;
logic [CORDW-1:0] sx, sy;
logic hsync, vsync, de;

// Цвета
logic vga_r_reg, vga_g_reg, vga_b_reg;
logic picture;

// Размеры символов
localparam CHAR_WIDTH = 8;
localparam CHAR_HEIGHT = 16;
localparam LINE1_Y = 200;
localparam LINE2_Y = 250;

// =========================================================================
// ФУНКЦИЯ BINARY TO BCD (DOUBLE DABBLE)
// =========================================================================
// Эта функция синтезируется в комбинационную логику.
// Вход: 8 бит (0-255)
// Выход: 12 бит (3 цифры BCD: Сотни[11:8], Десятки[7:4], Единицы[3:0])

function automatic [11:0] bin2bcd(input [7:0] bin_in);
    logic [11:0] bcd;
    integer i;
begin
    bcd = 12'd0;
    for (i = 0; i < 8; i = i + 1) begin
        // Коррекция тетрад > 4
        if (bcd[3:0]   >= 5) bcd[3:0]   = bcd[3:0]   + 4'd3;
        if (bcd[7:4]   >= 5) bcd[7:4]   = bcd[7:4]   + 4'd3;
        if (bcd[11:8]  >= 5) bcd[11:8]  = bcd[11:8]  + 4'd3;
        
        // Сдвиг
        bcd = {bcd[10:0], bin_in[7-i]};
    end
    bin2bcd = bcd;
end
endfunction

// =========================================================================
// КОНВЕРТАЦИЯ ДАННЫХ (ВСЕГДА АКТУАЛЬНА)
// =========================================================================
logic [11:0] temp_bcd; // [11:8]-сотни, [7:4]-десятки, [3:0]-единицы
logic [11:0] hum_bcd;
logic [11:0] dist_bcd;

// Выполняем конвертацию параллельно для всех переменных
assign temp_bcd = bin2bcd(temp_int);
assign hum_bcd  = bin2bcd(hum_int);
assign dist_bcd = bin2bcd(dist_int);

// Детектор переключения
logic switch;
logic pulse_prev;
always_ff @(posedge clk_100m or negedge btn_rst_n)
begin
    if(!btn_rst_n) pulse_prev <= 1'b0;
    else           pulse_prev <= pulse;

end

logic pulse_edge;
assign pulse_edge = pulse && !pulse_prev;

always_ff @(posedge clk_100m or negedge btn_rst_n)
begin
    if(!btn_rst_n)      switch <= 1'b0;
    else if(pulse_edge) switch <= ~switch;

end

// Вспомогательные сигналы для текущего отображения (Main Line)
logic [3:0] show_digit1, show_digit2, show_digit3;
logic [3:0] show_dec;
logic show_sign;

always_comb begin
    if (!switch) begin
        // РЕЖИМ ТЕМПЕРАТУРА
        show_digit1 = temp_bcd[11:8]; // Сотни (обычно 0 для темп < 100)
        show_digit2 = temp_bcd[7:4];  // Десятки
        show_digit3 = temp_bcd[3:0];  // Единицы
        show_dec    = temp_dec[3:0];  // Десятые
        // Для примера знак. Если нужно реально определять минус, нужна логика с temp_int
        show_sign   = 1'b0; 
    end else begin
        // РЕЖИМ РАССТОЯНИЕ
        show_digit1 = dist_bcd[11:8]; // Сотни
        show_digit2 = dist_bcd[7:4];  // Десятки
        show_digit3 = dist_bcd[3:0];  // Единицы
        show_dec    = dist_dec[3:0];  // Десятые
        show_sign   = 1'b0;
    end
end

// =========================================================================
// ГЕНЕРАЦИЯ CLK
// =========================================================================
always_ff @(posedge clk_100m or negedge btn_rst_n) begin
    if(!btn_rst_n) begin
        q <= 0;
        clk_pix <= 0;
    end else begin
        q <= q + 1;
        clk_pix <= q[1];
    end
end

// =========================================================================
// VGA КОНТРОЛЛЕР
// =========================================================================
simple_480p display_inst (
    .clk_pix(clk_pix),
    .rst_pix(btn_rst_n),
    .sx(sx),
    .sy(sy),
    .hsync(hsync),
    .vsync(vsync),
    .de(de)
);

// Пайплайн задержки (для синхронизации с ROM шрифта)
logic [9:0] sx_d, sy_d;
logic de_d;
logic hsync_d, vsync_d;
logic switch_d;

always_ff @(posedge clk_pix or negedge btn_rst_n) begin
    if(!btn_rst_n) 
    begin
        sx_d <= 0;
        sy_d <= 0;
        de_d <= 0;
        hsync_d <= 0;
        vsync_d <= 0;
        switch_d <= 0;
    end
    else
    begin
        sx_d <= sx;
        sy_d <= sy;
        de_d <= de;
        hsync_d <= hsync;
        vsync_d <= vsync;
        switch_d <= switch;
    end
end

// =========================================================================
// ОТРИСОВКА СИМВОЛОВ
// =========================================================================
logic [7:0] char_code;
logic pixel_out;
logic [9:0] char_x_pos;
logic [9:0] char_start_x; // Расширил до 10 бит, чтобы не было warning

// ROM шрифтов
font_rom font_inst (
    .clk(clk_pix),
    .addr_x(sx[2:0]), 
    .addr_y(sy[3:0]), 
    .char_code(char_code),
    .pixel(pixel_out)
);

always_comb begin
    picture = 1'b0;
    char_code = 8'h00;
    
    // Используем 'sx' для вычисления адреса (так как ROM синхронный и отдаст данные на след. такте для de_d)
    if (de) begin
        // --- СТРОКА 1: ЗАГОЛОВОК ---
        if (sy >= LINE1_Y && sy < LINE1_Y + CHAR_HEIGHT) begin
            char_start_x = 100;
            if (sx >= char_start_x && sx < char_start_x + CHAR_WIDTH * 15) begin
                char_x_pos = (sx - char_start_x) >> 3;
                case (char_x_pos)
                    0: char_code = (!switch) ? 8'h54 : 8'h44; // T / D
                    1: char_code = (!switch) ? 8'h45 : 8'h49; // E / I
                    2: char_code = (!switch) ? 8'h52 : 8'h53; // R / S
                    3: char_code = (!switch) ? 8'h4D : 8'h54; // M / T
                    4: char_code = 8'h3D; // =
                    5: char_code = (!switch) ? ((show_sign) ? 8'h2D : 8'h2B) : {4'h3, show_digit1};// +\- / Сотни
                    6: char_code = {4'h3, show_digit2};       // Десятки
                    7: char_code = {4'h3, show_digit3};       // Единицы
                    8: char_code = 8'h2E;                     // .
                    9: char_code = {4'h3, show_dec};          // Десятые
                    //10: char_code = 8'h00;                    // space
                    10: char_code = (!switch) ? 8'hB0 : 8'h63;// degree  / c
                    11: char_code = (!switch) ? 8'h43 : 8'h6D;// C / m
                    default: char_code = 8'h00;
                endcase
                 if (char_code != 0) picture = pixel_out;
            end
        end
       
        // --- СТРОКА 2: ВЛАЖНОСТЬ (ТОЛЬКО В РЕЖИМЕ TEMP) ---
        if (!switch && sy >= LINE1_Y + 80 && sy < LINE1_Y + 80 + CHAR_HEIGHT) begin
            char_start_x = 100;
            if (sx >= char_start_x && sx < char_start_x + CHAR_WIDTH * 8) begin
                char_x_pos = (sx - char_start_x) >> 3;
                case (char_x_pos)
                    0: char_code = 8'h48; // H
                    1: char_code = 8'h55; // U
                    2: char_code = 8'h4D; // M
                    3: char_code = 8'h3D; // =
                    4: char_code = {4'h3, hum_bcd[7:4]}; // Десятки влажности
                    5: char_code = {4'h3, hum_bcd[3:0]}; // Единицы влажности
                    6: char_code = 8'h25; // %
                    default: char_code = 8'h00;
                endcase
                if (char_code != 0) picture = pixel_out;
            end
        end
    end
end

// =========================================================================
// ВЫХОДНЫЕ ЦВЕТА
// =========================================================================
always_comb begin
    // Если picture == 1, ставим белый цвет
    if (picture) begin
        vga_r_reg = 1'b1;
        vga_g_reg = 1'b1;
        vga_b_reg = 1'b1;
    end else begin
        vga_r_reg = 1'b0;
        vga_g_reg = 1'b0;
        vga_b_reg = 1'b0;
    end
end

always_ff @(posedge clk_pix or negedge btn_rst_n) begin
    if(!btn_rst_n) 
    begin
        vga_hsync <= 0;
        vga_vsync <= 0;
        vga_r <= 0;
        vga_g <= 0;
        vga_b <= 0;
    end
    else
    begin
        vga_hsync <= hsync_d;
        vga_vsync <= vsync_d;
        
        // Используем de_d, так как pixel_out пришел от ROM с задержкой в 1 такт
        if (de_d) begin 
            vga_r <= vga_r_reg; 
            vga_g <= vga_g_reg;
            vga_b <= vga_b_reg;
        end else begin
            vga_r <= 1'b0; 
            vga_g <= 1'b0;
            vga_b <= 1'b0;
        end
    end
end

endmodule