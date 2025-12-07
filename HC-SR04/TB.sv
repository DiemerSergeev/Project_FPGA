`timescale 1ns / 1ps

module tb_hc_sr04;

    logic clk;
    logic rst;
    logic start;
    logic echo;
    logic trig;
    logic [15:0] result;
    logic done;
//////////////////////////////////////////////////////////////////////////////
    hc_sr04_driver dut (
        .clk(clk), .rst(rst), .start(start), .echo(echo),
        .trig(trig), .result(result), .done(done)
    );
//////////////////////////////////////////////////////////////////////////////
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
//////////////////////////////////////////////////////////////////////////////
    task simulate_sensor_response(input int distance_cm);
        @(posedge trig);      
        @(negedge trig);      
        #5000;                
        echo = 1;             
        repeat(distance_cm * 58000) #1; 
        echo = 0;             
    endtask
//////////////////////////////////////////////////////////////////////////////
    initial begin
        rst = 1; 
        start = 0; 
        echo = 0;
        #200; 
        rst = 0; 
        #20000;
//////////////////////////////////////////////////////////////////////////////
        $display("=== Simulation Started ===");
        $display("[%0t] Starting Test 1 (10 cm)...", $time);
//////////////////////////////////////////////////////////////////////////////
        fork
            begin
                @(posedge clk); 
                start = 1;
                #20000; 
                start = 0;
            end
            simulate_sensor_response(10);
            begin
                @(posedge done); 
                #1;
                if (result == 10) $display("[PASS] Test 1: Expected 10, Got %d", result);
                else              $display("[FAIL] Test 1: Expected 10, Got %d", result);
            end
        join
        #1000000; 
//////////////////////////////////////////////////////////////////////////////
        $display("[%0t] Starting Test 2 (45 cm)...", $time);
//////////////////////////////////////////////////////////////////////////////
        fork
            begin
                @(posedge clk); 
                start = 1;
                @(posedge clk); 
                start = 0;
            end
            simulate_sensor_response(45);
            begin
                @(posedge done);
                #1;
                if (result == 45) $display("[PASS] Test 2: Expected 45, Got %d", result);
                else              $display("[FAIL] Test 2: Expected 45, Got %d", result);
            end
        join
//////////////////////////////////////////////////////////////////////////////
        $display("=== Simulation Finished ===");
        $stop;
    end
endmodule