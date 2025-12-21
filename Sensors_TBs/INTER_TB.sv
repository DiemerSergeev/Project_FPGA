`timescale 1ns / 1ps

module INTER_TB();

    logic clk, rst;
    logic [7:0] temp_int, temp_dec, hum_int, hum_dec, dist_int, dist_dec;
    logic data_ready;

    wire  dht_data_in;
    logic dht_data_out, dht_data_oe;
    logic sensor_drive_data;
    logic sensor_data;
    logic sonar_echo_pin;
    wire  sonar_trig_pin;

    wire ctrl_start;
    wire [15:0] w_dht_temp, w_dht_hum, w_sonar_dist;
    wire w_dht_valid, w_dht_error, w_sonar_done;
    
    int   sim_dist_cm;
    logic [7:0] sim_temp;
    logic [7:0] sim_hum;
    
    real start_time, stop_time, module_start_signal_time; 
    
    int iter;

    sensor_interface #(
        .TIMER_LIMIT(32'd4000000) 
    ) ctrl_inst (
        .clk(clk), .rst(rst),
        .drv_start(ctrl_start),
        .drv_dht_temp(w_dht_temp), .drv_dht_hum(w_dht_hum),
        .drv_dht_valid(w_dht_valid), .drv_dht_error(w_dht_error),
        .drv_sonar_dist(w_sonar_dist), .drv_sonar_done(w_sonar_done),
        .temp_int(temp_int), .temp_dec(temp_dec),
        .hum_int(hum_int),   .hum_dec(hum_dec),
        .dist_int(dist_int), .dist_dec(dist_dec),
        .data_ready(data_ready)
    );

    DHT11_driver dht_drv_inst (
        .clk(clk), .rst(rst), 
        .data_in(dht_data_in), .data_out(dht_data_out), .data_oe(dht_data_oe),
        .start(ctrl_start),
        .Temperature(w_dht_temp), .Humidity(w_dht_hum),
        .valid(w_dht_valid), .error(w_dht_error)
    );

    hc_sr04_driver sonar_drv_inst (
        .clk(clk), .rst(rst),
        .start(ctrl_start), .echo(sonar_echo_pin), .trig(sonar_trig_pin),
        .result(w_sonar_dist), .done(w_sonar_done)
    );

    assign dht_data_in = (sensor_drive_data) ? sensor_data : 1'bz;
    assign (weak1, weak0) dht_data_in = 1'b1;

    task send_dht_bit(input logic bit_val);
        begin
            sensor_data = 0;
            #50000;

            sensor_data = 1; 
            
            if (bit_val) 
                #70000; 
            else 
                #27000; 
        end
    endtask
    
    task send_dht_byte(input logic [7:0] byte_val);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                send_dht_bit(byte_val[i]);
            end
        end
    endtask
    
    task sensor_response(input int distance_cm);       
        #500000;                
        sonar_echo_pin = 1;             
        repeat(distance_cm * 58000) #1; 
        sonar_echo_pin = 0;             
    endtask


    initial begin 
        clk = 0; 
        forever #5 clk = ~clk; 
    end
    
    initial begin
        rst = 1;
        sensor_drive_data = 0; 
        sensor_data = 0;
        sonar_echo_pin = 0;
        iter = 0;

        #100;
        rst = 0;
        
        #200_000_000;
        $stop; 

    end


    always begin
    
        wait(dht_data_oe === 1'b1);
        start_time = $realtime;

        wait(dht_data_oe === 1'b0); 
        stop_time = $realtime; 
        
        module_start_signal_time = stop_time - start_time;

        #20000; 
        
        sensor_drive_data = 1;
        sensor_data = 0;
        #80000; 
        
        sensor_data = 1;
        #80000; 
        
        
        send_dht_byte(8'd14+iter); 
        send_dht_byte(8'd02+iter);
         
        send_dht_byte(8'd20+iter); 
        send_dht_byte(8'd04+iter);
         
        send_dht_byte(8'd40+5*iter);
        
        
        
        sensor_data = 0;
        #50000; 
        sensor_drive_data = 0; 
        
        #500000;
        iter = iter + 1;
    end
    
    always begin
         @(negedge sonar_trig_pin);
        sensor_response(10*iter);
    end


endmodule
