`timescale 1ns / 1ps

module hc_sr04_driver 
(
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic        echo,
    output logic        trig,
    output logic [15:0] result,
    output logic        done
);
//////////////////////////////////////////////////////////////////////////////
    localparam int TRIG_WIDTH = 1000; // продолжительность импульса 10 мкс
    localparam int CLK_PER_CM = 5800; // константа 58 мкс (звук туда-обратно 1 см)
//////////////////////////////////////////////////////////////////////////////
    typedef enum logic [1:0] // конечный автомат логики состояний датчика
    {
        IDLE,
        TRIGGER,
        WAIT_ECHO,
        MEASURE
    } state_t;
//////////////////////////////////////////////////////////////////////////////
    state_t state;
    logic [31:0] tick_counter;
    logic [15:0] cm_counter;
    logic echo_sync_0;
	logic echo_sync;
//////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) 
	begin
        echo_sync_0 <= echo;
        echo_sync   <= echo_sync_0;
    end
//////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk or posedge rst) 
	begin
        if (rst) 
        begin
            state        <= IDLE;
            trig         <= 0;
            result       <= 0;
            done         <= 0;
            tick_counter <= 0;
            cm_counter   <= 0;
        end
////////////////////////////////////////////////////////////////////////////// 
        else 
        begin
            case (state)
                IDLE: // ожидание сигнала start на входе
                begin
                    trig <= 0;
                    done <= 1;
                    if (start) 
                    begin
                        state <= TRIGGER; // переходим в состояние TRIGGER
                        tick_counter <= 0; // подготавливаем счетчик
                        done <= 0;
                    end
                end
//////////////////////////////////////////////////////////////////////////////
                TRIGGER: // для работы датчика подаем импульс TRIGGER длительностью 10мкс
                begin
                    done <= 0; // данные еще не готовы
                    trig <= 1; // подняли импульс
                    //result <= 0; // результат во время измерений обнуляется
                    if (tick_counter < TRIG_WIDTH) 
                    begin
                        tick_counter <= tick_counter + 1;
                    end
////////////////////////////////////////////////////////////////////////////// 
                    else // TRIGGER продержался 10мкс, теперь ждем сигнал ECHO от датчика
                    begin
                        trig <= 0; // опустили TRIGGER
                        tick_counter <= 0; // обнулили счетчик
                        state <= WAIT_ECHO; // переход в состояние ECHO
                    end
                end
//////////////////////////////////////////////////////////////////////////////
                WAIT_ECHO: // ждем сигнал ECHO от датчика, а пока отдыхаем
                begin
                   if (tick_counter > 'd3000000) // ошибка измерения, превышен лимит ожидания
                    begin
                        state <= IDLE; // переход в состояние ожидания
                        result <= 0; // результат на выходе 0
                        done <= 1;
                    end 
//////////////////////////////////////////////////////////////////////////////
                    else if (echo_sync) // ECHO поднялся, пора мерить расстояние
                    begin
                        tick_counter <= 0; // обнулили счетчик
                        cm_counter <= 0; // обнулили счетчик расстояния
                        state <= MEASURE; // переходим к измерениям
                    end
//////////////////////////////////////////////////////////////////////////////
                    else // тактируем
                    begin
                        tick_counter <= tick_counter + 1;
                    end
                end
//////////////////////////////////////////////////////////////////////////////
                MEASURE: // измеряем длительность импульса, которая эквивалентна расстоянию
                begin
                    if (!echo_sync) 
                    begin
                        if (tick_counter >= CLK_PER_CM / 2)
                        begin
                            result <= cm_counter + 1;
                        end
//////////////////////////////////////////////////////////////////////////////
                        else
                        begin
                            result <= cm_counter;
                        end
//////////////////////////////////////////////////////////////////////////////
                        done <= 1;
                        state <= IDLE;
                    end
////////////////////////////////////////////////////////////////////////////// 
                    else 
                    begin
                        if (tick_counter < CLK_PER_CM - 1) 
                        begin
                            tick_counter <= tick_counter + 1;
                        end
////////////////////////////////////////////////////////////////////////////// 
                        else 
                        begin
                            tick_counter <= 0;
                            cm_counter <= cm_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule