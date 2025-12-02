`timescale 1ns / 1ps

module hc_sr04_driver (
    input  logic        clk,    // 100 MHz
    input  logic        rst,
    input  logic        start,  // Сигнал запуска измерения (импульс)
    input  logic        echo,
    output logic        trig,
    output logic [15:0] result, // Дистанция в см
    output logic        done    // Флаг готовности результата (1 такт)
);

    // Параметры для 100 МГц
    localparam int TRIG_WIDTH = 1000; // 10 мкс
    localparam int CLK_PER_CM = 5800; // 58 мкс (звук туда-обратно 1 см)

    typedef enum logic [1:0] {
        IDLE,
        TRIGGER,
        WAIT_ECHO,
        MEASURE
    } state_t;

    state_t state;
    logic [31:0] tick_counter;
    logic [15:0] cm_counter;
    
    // Синхронизация echo
    logic echo_sync_0, echo_sync;
    always_ff @(posedge clk) begin
        echo_sync_0 <= echo;
        echo_sync   <= echo_sync_0;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
        begin
            state        <= IDLE;
            trig         <= 0;
            result       <= 0;
            done         <= 0;
            tick_counter <= 0;
            cm_counter   <= 0;
        end 
        else 
        begin
            case (state)
                // Ждем внешнего сигнала start
                IDLE: begin
                    trig <= 0;
                    if (start) begin
                        state <= TRIGGER;
                        tick_counter <= 0;
                        // Сбрасываем старый результат или оставляем - на выбор.
                        // Обычно лучше держать старый, пока не готов новый.
                    end
                end

                // Генерируем 10 мкс импульс
                TRIGGER: 
                begin
                    done <= 0;
                    trig <= 1;
                    if (tick_counter < TRIG_WIDTH) begin
                        tick_counter <= tick_counter + 1;
                    end else begin
                        trig <= 0;
                        tick_counter <= 0;
                        state <= WAIT_ECHO;
                    end
                end

                // Ждем ответа от датчика
                WAIT_ECHO: begin
                    // Защита от зависания (если датчик не подключен)
                    // Ждем макс ~30мс (3,000,000 тактов), иначе сброс
                    if (tick_counter > 3_000_000) begin
                        state <= IDLE;
                        result <= 0; // Ошибка
                        done <= 1;
                    end
                    else if (echo_sync) begin
                        tick_counter <= 0;
                        cm_counter <= 0;
                        state <= MEASURE;
                    end
                    else begin
                        tick_counter <= tick_counter + 1;
                    end
                end

                // Измеряем длительность
                MEASURE: begin
                    if (!echo_sync) begin
                        // Округление результата
                        if (tick_counter >= CLK_PER_CM / 2)
                            result <= cm_counter + 1;
                        else
                            result <= cm_counter;
                        
                        done <= 1; // Сообщаем топу, что данные готовы
                        state <= IDLE;
                    end else begin
                        if (tick_counter < CLK_PER_CM - 1) begin
                            tick_counter <= tick_counter + 1;
                        end else begin
                            tick_counter <= 0;
                            cm_counter <= cm_counter + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule