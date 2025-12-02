`timescale 1ns / 1ps

module tb_hc_sr04;

    // ==========================================
    // Объявление сигналов
    // ==========================================
    logic clk;
    logic rst;
    logic start;
    logic echo;
    logic trig;
    logic [15:0] result;
    logic done;

    // ==========================================
    // Подключение тестируемого модуля (DUT)
    // ==========================================
    hc_sr04_driver dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .echo(echo),
        .trig(trig),
        .result(result),
        .done(done)
    );

    // ==========================================
    // Генерация Clock (100 MHz -> период 10ns)
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ==========================================
    // Задача: Имитация физики датчика
    // ==========================================
    task simulate_sensor_response(input int distance_cm);
        // Ждем передний фронт trig
        @(posedge trig);      
        
        // Ждем задний фронт trig (конец импульса 10мкс)
        @(negedge trig);      
        
        // Имитация внутренней задержки электроники датчика
        #5000;                
        
        // Поднимаем ECHO
        echo = 1;             
        
        // Держим ECHO: 58 мкс * кол-во сантиметров
        // В timescale 1ns: 58000 * distance_cm
        repeat(distance_cm * 58000) #1; 
        
        // Опускаем ECHO
        echo = 0;             
    endtask

    // ==========================================
    // Основной сценарий тестирования
    // ==========================================
    initial begin
        // 1. Инициализация
        rst = 1;
        start = 0;
        echo = 0;
        
        #200;
        rst = 0;
        #200;

        $display("=== Simulation Started ===");

        // -------------------------------------------------------
        // ТЕСТ 1: Дистанция 10 см
        // Длинный импульс START (чтобы проверить фикс)
        // -------------------------------------------------------
        $display("[%0t] Starting Test 1 (10 cm)...", $time);

        fork
            // Поток А: Управление сигналом start
            begin
                @(posedge clk);
                start = 1;
                #100;      // Длинный импульс (10 тактов)
                start = 0;
            end

            // Поток Б: Физика датчика (начинает слушать сразу!)
            simulate_sensor_response(10);

            // Поток В: Проверка результата
            begin
                // Ждем пока модуль закончит измерение
                wait(done == 1);
                
                if (result == 10) 
                    $display("[PASS] Test 1: Expected 10, Got %d", result);
                else 
                    $display("[FAIL] Test 1: Expected 10, Got %d", result);
            end
        join

        // Пауза между измерениями (имитация работы топ-модуля)
        #1000000; 

        // -------------------------------------------------------
        // ТЕСТ 2: Дистанция 45 см
        // Короткий импульс START (1 такт)
        // -------------------------------------------------------
        $display("[%0t] Starting Test 2 (45 cm)...", $time);

        fork
            // Поток А
            begin
                @(posedge clk);
                start = 1;
                @(posedge clk); // Импульс всего 1 такт
                start = 0;
            end

            // Поток Б
            simulate_sensor_response(45);

            // Поток В
            begin
                wait(done == 1);
                if (result == 45) 
                    $display("[PASS] Test 2: Expected 45, Got %d", result);
                else 
                    $display("[FAIL] Test 2: Expected 45, Got %d", result);
            end
        join

        $display("=== Simulation Finished ===");
        $stop;
    end

endmodule