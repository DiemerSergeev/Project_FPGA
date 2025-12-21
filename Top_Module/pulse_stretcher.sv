`timescale 1ns / 1ps

module pulse_stretcher #(
    parameter int CYCLES_LIMIT = 20_000_000
)(
    input  logic clk,
    input  logic rst,
    input  logic trigger_in, // Входной сигнал (может быть длинным)
    output logic signal_out  // Выход на LED (вспышка фиксированной длины)
);
    logic [$clog2(CYCLES_LIMIT):0] counter;
    logic trigger_prev; // Для хранения предыдущего состояния входа

    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            signal_out <= 0;
            trigger_prev <= 0;
        end else begin
            trigger_prev <= trigger_in; // Запоминаем состояние для детекции фронта

            // Логика детекции переднего фронта (Rising Edge):
            // Было 0, стало 1. Запускаем таймер.
            if (trigger_in && !trigger_prev) begin
                counter <= CYCLES_LIMIT;
                signal_out <= 1'b1;
            end 
            // Если таймер запущен, уменьшаем его
            else if (counter > 0) begin
                counter <= counter - 1;
                signal_out <= 1'b1; // Держим LED включенным
            end 
            // Время вышло -> гасим LED, даже если trigger_in всё ещё 1
            else begin
                signal_out <= 1'b0;
            end
        end
    end
endmodule