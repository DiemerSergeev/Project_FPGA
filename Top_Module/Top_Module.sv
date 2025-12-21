`timescale 1ns / 1ps

module top_module #(
    parameter bit SIMULATION = 0 
)(
    input logic clk,
    (*mark_debug = "true"*) input logic rst,
    
    // ФИЗИЧЕСКИЙ ПОРТ (убрали mark_debug, так как это external pin)
    inout wire dataDHT11,
    
    (*mark_debug = "true"*) input logic echosr04,
    (*mark_debug = "true"*) output logic trigsr04,
    (*mark_debug = "true"*) input logic button,
    output logic hsync,
    output logic vsync,
    output logic vgadata,
    
    output logic [3:0] led,
    output logic [2:0] led0,
    output logic [2:0] led1,
    output logic [2:0] led2,
    output logic [2:0] led3
);

    (*mark_debug = "true"*) logic [7:0] temp_int, temp_dec, hum_int, hum_dec, dist_int;
    logic [7:0] dist_dec;
    (*mark_debug = "true"*) logic data_ready;
    (*mark_debug = "true"*) logic ctrl_start;
    (*mark_debug = "true"*) logic [15:0] w_dht_temp, w_dht_hum, w_sonar_dist;
    (*mark_debug = "true"*) logic w_dht_valid, w_dht_error, w_sonar_done;
    localparam int SCALE = SIMULATION ? 1000 : 1;
    localparam int CLK_FREQ = 100_000_000;
    localparam int SENSOR_POLL_TIME  = (7 * CLK_FREQ) / SCALE;
    localparam int LED_STRETCH_TIME  = (5 * CLK_FREQ) / (10 * SCALE); 
    localparam int BTN_DEBOUNCE_TIME = (5 * CLK_FREQ) / (100 * SCALE); 
    localparam int HEARTBEAT_TOGGLE  = (5 * CLK_FREQ) / (10 * SCALE);

    logic btn_pulse;
    logic [1:0]  btn_sync;   
    logic [31:0] db_cnt; 
    logic vgar;    
    logic vgab;  
    
    logic str_dht_valid, str_dht_error, str_dht_active;
    logic str_ctrl_start, str_data_ready, str_sonar_done;
    logic str_btn_pulse, str_vsync, str_trig;
    logic dht_edge_detect, dht_last;
    
    logic [31:0] hb_counter=0;
    logic hb_led_state=0;

    // Регистры светодиодов
    logic [3:0] led_reg;
    logic [2:0] led0_reg, led1_reg, led2_reg, led3_reg;
    
    // --- IOBUF LOGIC ---
    // Сигналы для соединения IOBUF и драйвера
    (* mark_debug = "true" *) logic dht_rx_data; // То, что реально видит FPGA на входе
    logic dht_tx_data; // То, что драйвер хочет отправить (0)
    logic dht_tx_oe;   // 1 = Драйвер активен
    
    // Примитив ввода-вывода. 
    // .IO - физический пин
    // .O  - выход внутрь FPGA (Rx)
    // .I  - вход от FPGA (Tx)
    // .T  - управление 3-им состоянием (Active Low: 0=Drive, 1=HighZ)
    IOBUF dht_iobuf (
        .IO(dataDHT11),
        .O(dht_rx_data),
        .I(dht_tx_data),
        .T(~dht_tx_oe) // Инвертируем, так как IOBUF хочет 0 для активности, а у нас 1
    );

    // --- INSTANCES ---
    
    sensor_interface #( .TIMER_LIMIT(SENSOR_POLL_TIME) ) ctrl_inst (
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

    // Подключаем обновленный драйвер с раздельными линиями
    DHT11_driver dht_drv_inst (
        .clk(clk), .rst(rst), 
        .data_in(dht_rx_data),   // Вход: то, что прошло через IOBUF
        .data_out(dht_tx_data),  // Выход: данные драйвера
        .data_oe(dht_tx_oe),     // Выход: разрешение драйвера
        
        .start(ctrl_start),
        .Temperature(w_dht_temp), .Humidity(w_dht_hum),
        .valid(w_dht_valid), .error(w_dht_error)
    );

    hc_sr04_driver sonar_drv_inst (
        .clk(clk), .rst(rst),
        .start(ctrl_start), .echo(echosr04), .trig(trigsr04),
        .result(w_sonar_dist), .done(w_sonar_done)
    );

    VGA_top vga_driver_inst (
        .clk_100m(clk),
        .btn_rst_n(!rst),
        .pulse(btn_pulse),
        .temp_int(temp_int),
        .temp_dec(temp_dec),
        .dist_int(dist_int),
        .dist_dec(dist_dec),
        .hum_int(hum_int),
        .hum_dec(hum_dec),
        .vga_hsync(hsync),
        .vga_vsync(vsync),
        .vga_g(vgadata),
        .vga_r(vgar),
        .vga_b(vgab)
    );
    
    // Debouncer
    always_ff @(posedge clk) begin 
        btn_sync <= {btn_sync[0], button}; 
        if (btn_sync[1] == 1'b0) begin 
            db_cnt <= 0;
            btn_pulse <= 0;
        end 
        else begin
            if (db_cnt < BTN_DEBOUNCE_TIME) begin
                db_cnt <= db_cnt + 1;
                btn_pulse <= 0;
            end 
            else if (db_cnt == BTN_DEBOUNCE_TIME) begin 
                btn_pulse <= 1;
                db_cnt <= db_cnt + 1; 
            end 
            else begin 
                btn_pulse <= 0;
            end
        end
    end

    // --- LED LOGIC ---
    always_ff @(posedge clk) begin
        if (rst) begin
            dht_last <= 1'b1;
            dht_edge_detect <= 0;
            hb_counter <= 0;
            hb_led_state <= 0;
            
            led_reg <= 0;
            led0_reg <= 0;
            led1_reg <= 0;
            led2_reg <= 0;
            led3_reg <= 0;
        end else begin
            // 1. Детекция фронтов (смотрим на RX данные из буфера)
            dht_last <= dht_rx_data;
            dht_edge_detect <= (dht_last == 1'b1 && dht_rx_data == 1'b0);
            
            // 2. Heartbeat
            if (hb_counter >= HEARTBEAT_TOGGLE) begin
                hb_counter <= 0;
                hb_led_state <= ~hb_led_state;
            end else begin
                hb_counter <= hb_counter + 1;
            end

            // 3. Выходные регистры
            led_reg[0] <= hb_led_state;    
            led_reg[1] <= str_ctrl_start;
            led_reg[2] <= str_data_ready;
            led_reg[3] <= str_sonar_done;

            led0_reg[2] <= str_dht_error;
            led0_reg[1] <= str_dht_valid;
            led0_reg[0] <= str_dht_active;
            
            led1_reg[2] <= str_trig;
            led1_reg[1] <= echosr04;
            led1_reg[0] <= 1'b0;

            led2_reg[2] <= rst;
            led2_reg[1] <= str_btn_pulse;
            led2_reg[0] <= button;

            led3_reg[2] <= 1'b0;              
            led3_reg[1] <= 1'b0;              
            led3_reg[0] <= str_vsync;
        end
    end

    // Pulse Stretchers
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_dht_err (.clk(clk), .rst(rst), .trigger_in(w_dht_error), .signal_out(str_dht_error));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_dht_val (.clk(clk), .rst(rst), .trigger_in(w_dht_valid), .signal_out(str_dht_valid));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_dht_act (.clk(clk), .rst(rst), .trigger_in(dht_edge_detect), .signal_out(str_dht_active));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_start   (.clk(clk), .rst(rst), .trigger_in(ctrl_start), .signal_out(str_ctrl_start));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_ready   (.clk(clk), .rst(rst), .trigger_in(data_ready), .signal_out(str_data_ready));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_sonar   (.clk(clk), .rst(rst), .trigger_in(w_sonar_done), .signal_out(str_sonar_done));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_btn     (.clk(clk), .rst(rst), .trigger_in(btn_pulse), .signal_out(str_btn_pulse));
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_vsync   (.clk(clk), .rst(rst), .trigger_in(!vsync), .signal_out(str_vsync)); 
    pulse_stretcher #(.CYCLES_LIMIT(LED_STRETCH_TIME)) ps_trig    (.clk(clk), .rst(rst), .trigger_in(trigsr04), .signal_out(str_trig));

    // Assignments
    assign led  = led_reg;
    assign led0 = led0_reg;
    assign led1 = led1_reg;
    assign led2 = led2_reg;
    assign led3 = led3_reg;

endmodule
