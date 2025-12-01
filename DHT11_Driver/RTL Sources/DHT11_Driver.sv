`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.11.2025 12:28:21
// Design Name: 
// Module Name: DHT11_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DHT11_driver(
    input logic clk,
    input logic rst,
    inout wire data,
    input logic start,
    
    output logic [15:0] Temperature,
    output logic [15:0] Humidity,
    output logic valid,
    output logic error
    
    );
logic [39:0] shift_reg;
logic [23:0] counter;
logic [5:0]  bit_counter;

logic drive_low; //управление tri-state буфером

assign data = (drive_low) ? 1'b0 : 1'bz;

typedef enum logic [2:0] {
    IDLE,
    HOST_PULL_LOW,  // 18ms Low
    WAIT_SENSOR_LOW,// ∆дем ответа (0)
    WAIT_SENSOR_HIGH,// ∆дем ответа (1)
    WAIT_BIT_START, // ∆дем начала слота (перепад 1->0)
    WAIT_BIT_HIGH,  // ∆дем начала данных (перепад 0->1) - это 50us low период
    MEASURE_BIT,    // »змер€ем длительность 1
    CHECK_SUM
} state_t;

state_t current_state, next_state;

//FSM state logic
always_ff @ (posedge clk)
begin
    if(rst)
    begin
        counter <= 0;
        current_state <= IDLE;
        bit_counter <= 0;
        shift_reg <= 0;
        drive_low <= 0;
        Temperature <= 0;
        Humidity <= 0;
        valid <= 0;
        error <= 0;
     end
     else begin
        current_state <= next_state;
        if (next_state != current_state)
            counter <= 0;
        else
            counter <= counter + 1'b1;
        
        case(current_state)
            IDLE: begin
                drive_low <=0;
                if (start) begin
                    error <= 1'b0;
                    valid <= 1'b0;
                end
            end
            HOST_PULL_LOW: begin
                drive_low <= 1'b1;
            end
            WAIT_SENSOR_LOW: begin
                drive_low <= 1'b0;
            end
            WAIT_SENSOR_HIGH: 
                bit_counter <= 6'd0;
            MEASURE_BIT: begin
                if (data == 1'b0) begin
                    if(counter > 24'd5000)
                        shift_reg <= {shift_reg[38:0], 1'b1};
                    else
                        shift_reg <= {shift_reg[38:0], 1'b0};
                    bit_counter <= bit_counter + 1'b1;
                end
            end
            CHECK_SUM: begin
                logic [7:0] sum;
                sum = shift_reg[39:32] + shift_reg[31:24] + shift_reg[23:16] + shift_reg[15:8];
                if (sum == shift_reg[7:0]) begin
                    Humidity <= {shift_reg[39:32],shift_reg[31:24]};
                    Temperature <= {shift_reg[23:16],shift_reg[15:8]};
                    valid <= 1'b1;
                end
                else error <= 1'b1;
            end
            default:
                drive_low <= 1'b0;
         endcase
         if (current_state != IDLE && current_state != CHECK_SUM && next_state == IDLE) begin
                error <= 1'b1;
         end
     end            
end

//FSM Transition logic
always_comb begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (start)
                next_state = HOST_PULL_LOW;
        end
        HOST_PULL_LOW: begin
            if (counter >= 24'd1800000) begin
                next_state = WAIT_SENSOR_LOW;
            end 
        end
        WAIT_SENSOR_LOW: begin
            if (data == 1'b0 && counter > 24'd1000)
                next_state = WAIT_SENSOR_HIGH;
            else if (counter >= 24'd20000)
                next_state = IDLE;
        end
        WAIT_SENSOR_HIGH: begin
            if(data == 1'b1) 
                next_state = WAIT_BIT_START;
            else if (counter >= 24'd20000)
                next_state = IDLE;
        end
        WAIT_BIT_START: begin
            if(data == 1'b0) 
                next_state = WAIT_BIT_HIGH;
            else if (counter >= 24'd20000)
                next_state = IDLE;
        end 
        WAIT_BIT_HIGH: begin
            if(data == 1'b1) 
                next_state = MEASURE_BIT;
            else if (counter >= 24'd20000)
                next_state = IDLE;
        end        
        MEASURE_BIT: begin
            if (data == 1'b0) begin
                if (bit_counter == 6'd39)
                    next_state = CHECK_SUM;
                else
                    next_state = WAIT_BIT_HIGH;
            end
            else if (counter >= 24'd20000) next_state = IDLE;
        end
        CHECK_SUM:
            next_state = IDLE;
        default: next_state = IDLE;   
    endcase
end
endmodule
