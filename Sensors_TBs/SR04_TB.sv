`timescale 1ns / 1ps

module SR04_TB();
    
    logic clk;
    logic rst;
    logic start;
    logic echo;
    logic trig;
    logic [15:0] result;
    logic done;
    
    hc_sr04_driver uut (
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .echo(echo),
        .trig(trig), 
        .result(result), 
        .done(done)
    );
    
    task sensor_response(input int distance_cm);       
        #500000;                
        echo = 1;             
        repeat(distance_cm * 58000) #1; 
        echo = 0;             
    endtask
    
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    
     initial begin
        rst = 1; 
        start = 0; 
        echo = 0;
        #200; 
        rst = 0;
         
        #20000; 
         
        start = 1;
        #40;
        start = 0;
             
        @(negedge trig);
        sensor_response(10);
        
        #200000;
        
        start = 1;
        #40;
        start = 0;  
           
        @(negedge trig);
        sensor_response(40);
        
        #200000;
        $stop;    
    end
endmodule
