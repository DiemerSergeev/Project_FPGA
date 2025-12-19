`timescale 1ns / 1ps

module sensor_interface #(
    parameter logic [31:0] TIMER_LIMIT = 32'd700_000_000
)(
    input  logic        clk,
    input  logic        rst,
    
    output logic        drv_start,
    
    input  logic [15:0] drv_dht_temp,
    input  logic [15:0] drv_dht_hum,
    input  logic        drv_dht_valid,
    input  logic        drv_dht_error,
    
    input  logic [15:0] drv_sonar_dist,
    input  logic        drv_sonar_done,
    
    output logic [7:0]  temp_int, temp_dec,
    output logic [7:0]  hum_int, hum_dec,
    output logic [7:0]  dist_int, dist_dec,
    
    output logic        data_ready
    );

    logic [15:0] temp_buffer;
    logic [15:0] hum_buffer;
    logic [15:0] dist_buffer;
    
    logic dht_finished;
    logic sonar_finished;
    
    logic [11:0] wait_cnt; 
    
    logic [31:0] timer_cnt; 

    typedef enum logic [1:0] {
        IDLE,
        START_DELAY,
        WAIT_SENSORS,
        UPDATE_OUTPUT
    } state_t;
    
    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state           <= IDLE;
            drv_start       <= 1'b0;
            data_ready      <= 1'b0;
            
            dht_finished    <= 1'b0;
            sonar_finished  <= 1'b0;
            
            temp_buffer     <= 16'd0;
            hum_buffer      <= 16'd0;
            dist_buffer     <= 16'd0;
            
            temp_int        <= 8'd0; temp_dec <= 8'd0;
            hum_int         <= 8'd0; hum_dec  <= 8'd0;
            dist_int        <= 8'd0; dist_dec <= 8'd0;
            
            wait_cnt        <= 12'd0;
            timer_cnt       <= 32'd0;
        end 
        else begin
            
            data_ready <= 1'b0;

            if (state == WAIT_SENSORS) begin
                if (drv_dht_valid || drv_dht_error) begin
                    dht_finished <= 1'b1;
                    if (drv_dht_valid) begin
                        temp_buffer <= drv_dht_temp;
                        hum_buffer  <= drv_dht_hum;
                    end
                end
                if (drv_sonar_done) begin
                    sonar_finished <= 1'b1;
                    dist_buffer <= drv_sonar_dist;
                end
            end

            case (state)
                IDLE: begin
                    if (timer_cnt >= TIMER_LIMIT - 1) begin
                        timer_cnt <= 32'd0;
                        
                        drv_start <= 1'b1;       
                        wait_cnt <= 12'd0;
                        dht_finished <= 1'b0;      
                        sonar_finished <= 1'b0;
                        state <= START_DELAY;
                    end else begin
                        timer_cnt <= timer_cnt + 1'b1;
                    end
                end

                START_DELAY: begin
                    wait_cnt <= wait_cnt + 1'b1;
                    if (wait_cnt == 12'd2000) begin
                        state <= WAIT_SENSORS;
                    end
                end

                WAIT_SENSORS: begin
                    drv_start  <= 1'b0;
                    if (dht_finished && sonar_finished) begin
                        state <= UPDATE_OUTPUT;
                    end
                end

                UPDATE_OUTPUT: begin
                    temp_int <= temp_buffer[15:8];
                    temp_dec <= temp_buffer[7:0];
                    hum_int  <= hum_buffer[15:8];
                    hum_dec  <= hum_buffer[7:0];
                    dist_int <= dist_buffer[7:0];
                    dist_dec <= 8'd0;
                    
                    data_ready <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule