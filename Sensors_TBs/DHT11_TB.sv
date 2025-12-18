`timescale 1ns / 1ps

module DHT11_TB();

    logic clk;
    logic rst;
    logic start;

    logic data_out, data_oe;
    
    wire data_in;

    logic [15:0] temp;
    logic [15:0] hum;
    logic valid;
    logic error;


    logic sensor_drive_data; 
    logic sensor_data;
    logic sensor_data_sending;
    
    real start_time, stop_time, module_start_signal_time;
    
    logic [7:0] temp_int, temp_dec;
    logic [7:0] hum_int, hum_dec;
    
    integer i;

    assign data_in = (sensor_drive_data) ? sensor_data : 1'bz;

    assign (weak1, weak0) data_in = 1'b1;

    DHT11_driver uut (
        .clk(clk), 
        .rst(rst), 
        .data_in(data_in),
        .data_out(data_out),
        .data_oe(data_oe), 
        .start(start), 
        .Temperature(temp), 
        .Humidity(hum), 
        .valid(valid), 
        .error(error)
    );
    
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
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        start = 0;
        sensor_drive_data = 0; 
        sensor_data = 0;
        sensor_data_sending = 0;
        temp_int = 0;
        temp_dec = 0;
        hum_int = 0;
        hum_dec = 0;

        #100;
        rst = 0;
        #1000;
        
        for (i = 0; i < 3; i = i + 1) begin
    
            start = 1;
            #20; 
            start = 0;
            
            wait(data_oe === 1'b1);
            start_time = $realtime;
    
            wait(data_oe === 1'b0); 
            stop_time = $realtime; 
            
            module_start_signal_time = stop_time - start_time;
    
            #20000; 
            
            sensor_drive_data = 1;
            sensor_data = 0;
            #80000; 
            
            sensor_data = 1;
            #80000; 
            
            sensor_data_sending = 1;
            
            send_dht_byte(8'd14+i); 
            send_dht_byte(8'd02+i);
             
            send_dht_byte(8'd20+i); 
            send_dht_byte(8'd04+i);
             
            send_dht_byte(8'd41+4*i);
            
            sensor_data_sending = 0;
            
            
            sensor_data = 0;
            #50000; 
            sensor_drive_data = 0; 
            
            #100
            
            temp_int = temp[15:8];
            temp_dec = temp[7:0];
            hum_int = hum[15:8];
            hum_dec = hum[7:0];
            
            #500000;
        end
        $stop;
        
        end

endmodule
