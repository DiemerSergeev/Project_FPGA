`timescale 1ns / 1ps

module top_module(
	input logic clk,
    input logic rst,
	inout logic dataDHT11,
	input logic echosr04,
	input logic trigsr04,
	input logic button,
	output logic hsync,
	output logic vsync,
	output logic vgadata);

    logic [7:0] temp_int, temp_dec, hum_int, hum_dec, dist_int, dist_dec;
    logic data_ready;
    wire ctrl_start;
    wire [15:0] w_dht_temp, w_dht_hum, w_sonar_dist;
    wire w_dht_valid, w_dht_error, w_sonar_done;
	logic btn_pulse;
	logic [1:0]  btn_sync;   // Для синхронизации входа
	logic [22:0] db_cnt;     // Счётчик
	localparam TIME_BTN = 5_000_000; 
    sensor_interface #(
        .TIMER_LIMIT(32'd2000000) 
    ) ctrl_inst (
        .clk(clk), .rst(rst),
        .drv_dht_temp(w_dht_temp), .drv_dht_hum(w_dht_hum),
        .drv_dht_valid(w_dht_valid), .drv_dht_error(w_dht_error),
        .drv_sonar_dist(w_sonar_dist), .drv_sonar_done(w_sonar_done),
		.drv_start(ctrl_start),
        .temp_int(temp_int), .temp_dec(temp_dec),
        .hum_int(hum_int),   .hum_dec(hum_dec),
        .dist_int(dist_int), .dist_dec(dist_dec),
        .data_ready(data_ready)
    );
    DHT11_driver dht_drv_inst (
        .clk(clk), .rst(rst), 
        .data(dataDHT11), .start(ctrl_start),
        .Temperature(w_dht_temp), .Humidity(w_dht_hum),
        .valid(w_dht_valid), .error(w_dht_error)
    );
    hc_sr04_driver sonar_drv_inst (
        .clk(clk), .rst(rst),
        .start(ctrl_start), .echo(echosr04), .trig(trigsr04),
        .result(w_sonar_dist), .done(w_sonar_done)
    );
	VGA_top vga_drv_inst (
        .clk_50m(clk), .btn_rst_n(rst), .switch(btn_pulse),
        .temp_int(temp_int), .temp_dec(temp_dec),
        .hum_int(hum_int),   .hum_dec(hum_dec),
		.dist_int(dist_int), .dist_dec(dist_dec),
		.vga_hsync(hsync), .vga_vsync(vsync), .vga_out(vgadata)		
    );
	
	always_ff @(posedge clk) begin // 1. Синхронизация (убрать метастабильность)
    btn_sync <= {btn_sync[0], button}; 
    if (btn_sync[1] == 1'b0) begin // Кнопка отпущена
        db_cnt <= 0;
        btn_pulse <= 0;
		end 
	else begin// Кнопка нажата
        if (db_cnt < TIME_BTN) begin
            db_cnt <= db_cnt + 1;
            btn_pulse <= 0;
        end 
        else if (db_cnt == TIME_BTN) begin // Время вышло: даем импульс ровно на 1 такт
            btn_pulse <= 1;
            db_cnt <= db_cnt + 1;
        end 
        else begin // Блокировка: если держим кнопку дольше, импульс уже был
            btn_pulse <= 0;
        end
    end
end
	
endmodule