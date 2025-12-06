`timescale 1ns / 1ps

module sensor_interface_tb;

    logic clk, rst, en1, en2;
    logic [7:0] temp_int, temp_dec, hum_int, hum_dec, dist_int, dist_dec;
    logic data_ready;

    wire  dht_data_pin;
    logic sonar_echo_pin;
    wire  sonar_trig_pin;

    wire ctrl_start;

    wire [15:0] w_dht_temp, w_dht_hum;
    wire w_dht_valid, w_dht_error;

    wire [15:0] w_sonar_dist;
    wire w_sonar_done;

    sensor_interface ctrl_inst (
        .clk(clk), .rst(rst), .en1(en1), .en2(en2),
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
        .data(dht_data_pin),
        .start(ctrl_start),
        .Temperature(w_dht_temp),
        .Humidity(w_dht_hum),
        .valid(w_dht_valid),
        .error(w_dht_error)
    );

    hc_sr04_driver sonar_drv_inst (
        .clk(clk), .rst(rst),
        .start(ctrl_start),
        .echo(sonar_echo_pin),
        .trig(sonar_trig_pin),
        .result(w_sonar_dist),
        .done(w_sonar_done)
    );

    logic dht_sim_drive, dht_sim_val;
    assign (weak1, weak0) dht_data_pin = 1'b1;
    assign dht_data_pin = (dht_sim_drive) ? dht_sim_val : 1'bz;

    typedef struct {
        logic [7:0] t_i, t_d, h_i, h_d;
        logic [15:0] distance_val;
    } test_case_t;
    test_case_t tests [0:2];

    initial begin clk = 0; forever #5 clk = ~clk; end
    integer i;

    initial begin
        tests[0].t_i=20; tests[0].t_d=5; tests[0].h_i=50; tests[0].h_d=0; tests[0].distance_val=10;
        tests[1].t_i=32; tests[1].t_d=1; tests[1].h_i=65; tests[1].h_d=9; tests[1].distance_val=45;
        tests[2].t_i=15; tests[2].t_d=0; tests[2].h_i=40; tests[2].h_d=2; tests[2].distance_val=8;

        rst = 1; en1 = 0; en2 = 0;
        dht_sim_drive = 0; dht_sim_val = 1; sonar_echo_pin = 0;
        #200 rst = 0;

        for (i = 0; i < 3; i = i + 1) begin
            #100; en1 = 1; en2 = 1;

            fork
                simulate_dht11(tests[i].h_i, tests[i].h_d, tests[i].t_i, tests[i].t_d);
                simulate_sonar(tests[i].distance_val);
            join

            #1000; en1 = 0; en2 = 0; 
            #20000; 
        end
        $stop;
    end

    task automatic simulate_dht11(input [7:0] hi, hd, ti, td);
        logic [7:0] cs; logic [39:0] pkt; integer k;
        begin
            cs = hi + hd + ti + td; pkt = {hi, hd, ti, td, cs};
            wait(dht_data_pin === 0); wait(dht_data_pin === 1);
            #20000; dht_sim_drive = 1; 
            dht_sim_val = 0; #80000; dht_sim_val = 1; #80000;
            for (k=39; k>=0; k=k-1) begin
                dht_sim_val = 0; #50000;
                dht_sim_val = 1; if(pkt[k]) #70000; else #27000;
            end
            dht_sim_val = 0; #50000; dht_sim_drive = 0;
        end
    endtask

    task automatic simulate_sonar(input logic [15:0] dist_val_cm);
        begin
            wait(sonar_trig_pin === 1); wait(sonar_trig_pin === 0);
            #10000;
            sonar_echo_pin = 1; repeat(dist_val_cm * 58000) #1; sonar_echo_pin = 0;
        end
    endtask
endmodule