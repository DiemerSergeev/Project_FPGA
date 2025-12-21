`timescale 1ns / 1ps

module top_module_tb;
    integer f;

    logic clk, rst;
    logic button;
    logic hsync, vsync, vgadata;
    wire  dht_data_pin;
    logic sonar_echo_pin;
    wire  sonar_trig_pin;
    
    // LEDs
    logic [3:0] led;
    logic [2:0] led0, led1, led2, led3;
    logic btn_pulse;

    // --- INSTANTIATION with SIMULATION parameter ---
    top_module #(
        .SIMULATION(1)  // <<< Включаем режим ускоренной симуляции (1:1000)
    ) top_module_ins (
        .clk(clk), 
        .rst(rst), 
        .dataDHT11(dht_data_pin),
        .echosr04(sonar_echo_pin), 
        .trigsr04(sonar_trig_pin), 
        .button(button), 
        .hsync(hsync), 
        .vsync(vsync), 
        .vgadata(vgadata),
        .led(led), .led0(led0), .led1(led1), .led2(led2), .led3(led3),
        .btn_pulse(btn_pulse)
    );

    int   sim_dist_cm;
    logic [7:0] sim_temp;
    logic [7:0] sim_hum;

    // Clock generation
    initial begin 
        button = 0;
        clk = 0; 
        forever #5 clk = ~clk; 
    end

    // HC-SR04 Logic (Real-time physics for simulation)
    // Эти задержки остаются физическими, так как драйверы датчиков внутри работают на частоте клока
    always begin
        wait(sonar_trig_pin == 1); wait(sonar_trig_pin == 0);
        #1000;
        sonar_echo_pin = 1; 
        repeat(sim_dist_cm * 58000) #1; 
        sonar_echo_pin = 0;
    end

    // DHT11 Logic
    logic dht_sim_drive, dht_sim_val;
    assign (weak1, weak0) dht_data_pin = 1'b1;
    assign dht_data_pin = (dht_sim_drive) ? dht_sim_val : 1'bz;

    always begin
        // Ждем старта. В режиме SIMULATION(1) мастер может посылать старт чаще (каждые 7мс)
        wait(dht_data_pin == 0); wait(dht_data_pin == 1);
        
        #20000;
        dht_sim_drive = 1; dht_sim_val = 0; 
        #80000; 
        dht_sim_val = 1; 
        #80000;
        send_dht_packet(sim_hum, 8'd0, sim_temp, 8'd0);
        dht_sim_val = 0;
        #50000; 
        dht_sim_drive = 0;
    end
    
    // Button Logic
    always begin
        #30000000; // Просто переключаем кнопку время от времени
        button = ~button;
    end

    task automatic send_dht_packet(input [7:0] hi, hd, ti, td);
        logic [7:0] cs; logic [39:0] pkt; integer k;
        begin
            cs = hi + hd + ti + td; pkt = {hi, hd, ti, td, cs};
            for (k=39; k>=0; k--) begin
                dht_sim_val = 0; #50000;
                dht_sim_val = 1; if(pkt[k]) #70000; else #27000;
            end
        end
    endtask

    initial begin
        f = $fopen("vga_dump.csv", "w");
        $fwrite(f, "Time,hsync,vsync,vgadata\n");
        rst = 1; sonar_echo_pin = 0; dht_sim_drive = 0; dht_sim_val = 1;
        sim_dist_cm = 0; sim_temp = 0; sim_hum = 0;
        
        #200 rst = 0;

        // В симуляции таймер опроса теперь 7мс (вместо 7с).
        // Задержка #40000000 (40мс) позволяет пройти ~5 циклам измерения.
        
        sim_dist_cm = 15; sim_temp = 22; sim_hum = 45;
        $display("Simulation finished1.");
        #40000000; 
        
        sim_dist_cm = 30; sim_temp = 28; sim_hum = 60;
         $display("Simulation finished2.");
        #40000000; 
        
        sim_dist_cm = 50; sim_temp = 32; sim_hum = 65;
         $display("Simulation finished3.");
        #80000000; 
        
        $fclose(f);
        $display("Simulation finished.");
        $finish;
        
        $stop;
    end
    always @(hsync or vsync or vgadata) begin
        if (!rst) begin
            $fwrite(f, "%0t,%b,%b,%h\n", $time, hsync, vsync, vgadata);
        end
    end
endmodule
