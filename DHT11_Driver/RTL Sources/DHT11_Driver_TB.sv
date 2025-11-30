`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.11.2025 17:22:01
// Design Name: 
// Module Name: DHT11_Driver_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DHT11_Driver_TB();
    // Inputs
    logic clk;
    logic rst;
    logic start;

    // Bi-directional
    wire data;

    // Outputs
    logic [15:0] Temperature;
    logic [15:0] Humidity;
    logic valid;
    logic error;

    // Variables for Testbench control
    logic tb_drive_data; // 1 = TB управляет линией, 0 = TB отпускает линию
    logic tb_data_val;   // Значение, которое выдает TB

    // Pull-up resistor simulation
    // Если никто (ни FPGA, ни TB) не тянет линию к 0, она становится 1.
    // pullup(data); - можно так, но для надежности в TB используем assign с 'z
    assign data = (tb_drive_data) ? tb_data_val : 1'bz;
    // Имитация резистора подтяжки:
    assign (weak1, weak0) data = 1'b1; 

    // Instantiate the Unit Under Test (UUT)
    DHT11_driver uut (
        .clk(clk), 
        .rst(rst), 
        .data(data), 
        .start(start), 
        .Temperature(Temperature), 
        .Humidity(Humidity), 
        .valid(valid), 
        .error(error)
    );

    // Clock generation (100 MHz -> 10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Task to send a single bit from DHT11 to FPGA ---
    task send_dht_bit(input logic bit_val);
        begin
            // 1. Начало слота: Датчик тянет в 0 на 50 мкс
            tb_drive_data = 1;
            tb_data_val = 0;
            #50000; // 50 us

            // 2. Передача бита: Датчик отпускает в 1
            // Если '0' -> 26-28 мкс. Если '1' -> 70 мкс.
            tb_data_val = 1; // (или 1'bz с подтяжкой, но для теста проще 1)
            
            if (bit_val) 
                #72000; // 72 us for Logic 1
            else 
                #27000; // 27 us for Logic 0
        end
    endtask

    // --- Task to send a full byte ---
    task send_dht_byte(input logic [7:0] byte_val);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                send_dht_bit(byte_val[i]);
            end
        end
    endtask
    always @(uut.current_state) begin
        // Мы хотим посмотреть данные именно в момент перехода к проверке суммы
        if (uut.current_state == uut.CHECK_SUM) begin
            $display("\n[DEBUG] --- Internal State Inspection at %0t ---", $time);
            
            // Выводим сырой сдвиговый регистр
            $display("[DEBUG] Shift Register (Raw): %h", uut.shift_reg);
            
            // Разбиваем его на части вручную, чтобы проверить логику
            $display("[DEBUG] Byte 4 (Hum Int) : %d (0x%h)", uut.shift_reg[39:32], uut.shift_reg[39:32]);
            $display("[DEBUG] Byte 3 (Hum Dec) : %d (0x%h)", uut.shift_reg[31:24], uut.shift_reg[31:24]);
            $display("[DEBUG] Byte 2 (Tmp Int) : %d (0x%h)", uut.shift_reg[23:16], uut.shift_reg[23:16]);
            $display("[DEBUG] Byte 1 (Tmp Dec) : %d (0x%h)", uut.shift_reg[15:8],  uut.shift_reg[15:8]);
            $display("[DEBUG] Byte 0 (CheckSum): %d (0x%h)", uut.shift_reg[7:0],   uut.shift_reg[7:0]);
            
            // Считаем сумму прямо в тестбенче для проверки
            begin
                logic [7:0] calc_sum;
                calc_sum = uut.shift_reg[39:32] + uut.shift_reg[31:24] + 
                           uut.shift_reg[23:16] + uut.shift_reg[15:8];
                $display("[DEBUG] Calculated Sum   : %d (0x%h)", calc_sum, calc_sum);
                
                if (calc_sum == uut.shift_reg[7:0])
                    $display("[DEBUG] >> Checksum MATCH matches internal logic.");
                else
                    $display("[DEBUG] >> Checksum MISMATCH!");
            end
        end
    end
    // --- Main Stimulus ---
    initial begin
        // Initialize Inputs
        rst = 1;
        start = 0;
        tb_drive_data = 0; // TB не вмешивается
        tb_data_val = 0;

        // Wait 100 ns for global reset to finish
        #100;
        rst = 0;
        #1000;

        // --- Start Test ---
        $display("Starting DHT11 simulation...");
        
        // 1. Send Start Command from FPGA
        start = 1;
        #20; // Pulse start
        start = 0;

        // 2. Wait for FPGA to pull line LOW (Start Signal)
        wait(data === 1'b0);
        $display("FPGA pulled line LOW (Start Signal detected)");

        // 3. Wait for FPGA to release line (Wait > 18ms)
        // В коде у тебя 18мс. В симуляции это долго, но подождем.
        wait(data === 1'b1); 
        $display("FPGA released line (End of Start Signal)");

        // 4. DHT11 Response
        // Ждем немного (20-40 мкс), как будто датчик думает
        #30000; 
        
        // Датчик отвечает: Low 80us, High 80us
        $display("DHT11 sending Response...");
        tb_drive_data = 1;
        tb_data_val = 0;
        #80000; // 80 us Low
        
        tb_data_val = 1;
        #80000; // 80 us High

        // 5. Sending Data (40 bits)
        // Пример данных:
        // Hum Int: 20 (0x14)
        // Hum Dec: 0  (0x00)
        // Tmp Int: 25 (0x19)
        // Tmp Dec: 4  (0x04)
        // Sum: 0x14 + 0x00 + 0x19 + 0x04 = 0x31 (49 decimal)
        
        $display("DHT11 sending Data...");
        send_dht_byte(8'h14); // Hum Int
        send_dht_byte(8'h00); // Hum Dec
        send_dht_byte(8'h19); // Temp Int
        send_dht_byte(8'h04); // Temp Dec
        send_dht_byte(8'h31); // Checksum

        // End of transmission
        // Датчик тянет в 0 на 50 мкс в конце последнего бита, потом отпускает
        tb_drive_data = 1;
        tb_data_val = 0;
        #50000; 
        tb_drive_data = 0; // Отпускаем линию (Idle)
        
        // 6. Check Results
        #1000; // Даем FPGA время посчитать CRC
        
        if (valid) begin
            $display("SUCCESS: Valid data received!");
            $display("Humidity: %d.%d %%", Humidity[15:8], Humidity[7:0]);
            $display("Temperature: %d.%d C", Temperature[15:8], Temperature[7:0]);
        end else begin
            $display("ERROR: Valid signal not asserted!");
            if (error) $display("Error flag is set.");
        end

        $stop;
    end
endmodule
