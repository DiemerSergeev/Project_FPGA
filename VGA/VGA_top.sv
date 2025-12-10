module VGA_top (
    input wire logic    clk_50m,
    input wire logic    btn_rst_n,
    input  logic		switch,
    input  logic [7:0]  temp_int,
    input  logic [7:0]  temp_dec,
    input  logic [7:0]  hum_int,
    input  logic [7:0]  hum_dec,
    input  logic [7:0]  dist_int,
    input  logic [7:0]  dist_dec,
    output logic        vga_hsync,
    output logic        vga_vsync,
    output logic		vga_out
);

    assign vga_hsync  = 1'b0;
    assign vga_vsync  = 1'b0;
    assign vga_out = '0;

endmodule

  