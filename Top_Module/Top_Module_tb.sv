`timescale 1ns / 1ps

module top_module_tb;

    logic clk, rst;
	logic button;
	logic hsync, vsync,	vgadata;
    wire  dht_data_pin;
    logic sonar_echo_pin;
    wire  sonar_trig_pin;
	
	top_module top_module_ins(
		.clk(clk), .rst(rst), 
		.dataDHT11(dht_data_pin),
		.echosr04(sonar_echo_pin), .trigsr04(sonar_trig_pin), 
		.button(button), .hsync(hsync), .vsync(vsync), .vgadata(vgadata) );

    int   sim_dist_cm;
    logic [7:0] sim_temp;
    logic [7:0] sim_hum;
    initial begin 
		button = 0;
		clk = 0; 
		forever #5 clk = ~clk; 
	end
    // HC-SR04
    always begin
        wait(sonar_trig_pin == 1); wait(sonar_trig_pin == 0);
        #1000;
        sonar_echo_pin = 1; 
		repeat(sim_dist_cm * 58000) #1; 
		sonar_echo_pin = 0;
    end

    // DHT11
    logic dht_sim_drive, dht_sim_val;
    assign (weak1, weak0) dht_data_pin = 1'b1;
    assign dht_data_pin = (dht_sim_drive) ? dht_sim_val : 1'bz;

    always begin
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
	
	always begin
		#80000;
		button=~button;
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
        rst = 1; sonar_echo_pin = 0; dht_sim_drive = 0; dht_sim_val = 1;
        sim_dist_cm = 0; sim_temp = 0; sim_hum = 0;
        
        #200 rst = 0;

        sim_dist_cm = 15; sim_temp = 22; sim_hum = 45;
        
        #40000000; 
        sim_dist_cm = 30; sim_temp = 28; sim_hum = 60;
        
        #40000000; 
        sim_dist_cm = 50; sim_temp = 32; sim_hum = 65;

        #80000000; 
        $stop;
    end
endmodule
