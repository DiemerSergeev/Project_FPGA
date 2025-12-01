`timescale 1ns / 1ps

module DHT11_driver(
    input  logic clk,      // 100 MHz
    input  logic rst,
    inout  wire  data,     // Двунаправленная линия
    input  logic start,
    
    output logic [15:0] Temperature,
    output logic [15:0] Humidity,
    output logic valid,
    output logic error
    );

    // Внутренние сигналы
    logic [39:0] shift_reg;
    logic [23:0] counter;
    logic [5:0]  bit_counter;
    logic        drive_low; // управление tri-state буфером

    // Tri-state буфер:
    // Когда drive_low = 1, выдаем 0 (земля).
    // Когда drive_low = 0, выдаем Z (высокоимпедансное состояние), резистор подтягивает к 1.
    assign data = (drive_low) ? 1'b0 : 1'bz;

    // Описание состояний FSM
    typedef enum logic [2:0] {
        IDLE,
        HOST_PULL_LOW,   // МК тянет линию вниз 18мс
        WAIT_SENSOR_LOW, // Ждем ответа датчика (0)
        WAIT_SENSOR_HIGH,// Ждем ответа датчика (1)
        WAIT_BIT_START,  // Ждем начала слота (спад 1->0)
        WAIT_BIT_HIGH,   // Ждем начала данных (спад 0->1), это конец 50мкс паузы
        MEASURE_BIT,     // �?змеряем длительность "1"
        CHECK_SUM        // Проверка данных
    } state_t;

    state_t current_state, next_state;

    // --- FSM Sequential Logic ---
    always_ff @ (posedge clk) begin
        if(rst) begin
            counter      <= 0;
            current_state<= IDLE;
            bit_counter  <= 0;
            shift_reg    <= 0;
            drive_low    <= 0;
            Temperature  <= 0;
            Humidity     <= 0;
            valid        <= 0;
            error        <= 0;
        end else begin
            current_state <= next_state;
            
            // Управление счетчиком: сброс при смене состояния, иначе инкремент
            if (next_state != current_state)
                counter <= 0;
            else
                counter <= counter + 1'b1;
            
            // Логика выходов и регистров по текущему состоянию
            case(current_state)
                IDLE: begin
                    drive_low <= 0;
                    if (start) begin
                        error <= 1'b0;
                        valid <= 1'b0;
                    end
                end

                HOST_PULL_LOW: begin
                    drive_low <= 1'b1; // Прижимаем линию
                end

                WAIT_SENSOR_LOW: begin
                    drive_low <= 1'b0; // Отпускаем линию
                end

                WAIT_SENSOR_HIGH: 
                    bit_counter <= 6'd0; // Готовимся считать биты

                MEASURE_BIT: begin
                    // Если линия упала в 0, значит бит закончился. Фиксируем значение.
                    if (data == 1'b0) begin
                        // Порог 50мкс (5000 тактов на 100МГц)
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
                        Humidity    <= {shift_reg[39:32], shift_reg[31:24]};
                        Temperature <= {shift_reg[23:16], shift_reg[15:8]};
                        valid       <= 1'b1;
                    end else begin
                        error       <= 1'b1;
                    end
                end

                default: drive_low <= 1'b0;
            endcase
            
            // Глобальный таймаут (если FSM вылетает в IDLE не через CHECK_SUM)
            if (current_state != IDLE && current_state != CHECK_SUM && next_state == IDLE) begin
                error <= 1'b1;
            end
        end            
    end

// --- FSM Combinational Logic ---
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (start) next_state = HOST_PULL_LOW;
            end
            
            HOST_PULL_LOW: begin
                // 18ms @ 100MHz = 1,800,000
                if (counter >= 24'd1800000) next_state = WAIT_SENSOR_LOW;
            end
            
            WAIT_SENSOR_LOW: begin
                if (data == 1'b0 && counter >= 24'd1000) next_state = WAIT_SENSOR_HIGH;
                else if (counter >= 24'd20000) next_state = IDLE; // Timeout 200us
            end
            
            WAIT_SENSOR_HIGH: begin
                if(data == 1'b1) next_state = WAIT_BIT_START;
                else if (counter >= 24'd20000) next_state = IDLE;
            end
            
            WAIT_BIT_START: begin
                if(data == 1'b0) next_state = WAIT_BIT_HIGH;
                else if (counter >= 24'd20000) next_state = IDLE;
            end 
            
            WAIT_BIT_HIGH: begin
                if(data == 1'b1) next_state = MEASURE_BIT;
                else if (counter >= 24'd20000) next_state = IDLE;
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
            
            CHECK_SUM: next_state = IDLE;
            
            default: next_state = IDLE;   
        endcase
    end
endmodule