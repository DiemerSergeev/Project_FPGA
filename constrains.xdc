set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

## ==============================================================================
## Buttons
## ==============================================================================
## Reset Button (BTN1 - Pin C9 used as Reset in your code)
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports rst]

## User Button (BTN0 - Pin D9)
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports button]

## ==============================================================================
## VGA Signals
## ==============================================================================
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports hsync]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports vsync]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports vgadata]

## ==============================================================================
## Sensors
## ==============================================================================
## DHT11 Data Line
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports dataDHT11]

## HC-SR04 Ultrasonic Sensor
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports echosr04]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports trigsr04]

## ==============================================================================
## LEDs Display Logic
## ==============================================================================

## Standard LEDs (Green 4-7)
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## RGB LEDs
## Mapping logic: [2]=Red, [1]=Green, [0]=Blue

## RGB LED 0 (LD0) -> Pins: Red=G6, Green=F6, Blue=E1
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {led0[0]}]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {led0[1]}]
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports {led0[2]}]

## RGB LED 1 (LD1) -> Pins: Red=G3, Green=J4, Blue=G4
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {led1[0]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {led1[1]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {led1[2]}]

## RGB LED 2 (LD2) -> Pins: Red=J3, Green=J2, Blue=H4
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {led2[0]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {led2[1]}]
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {led2[2]}]

## RGB LED 3 (LD3) -> Pins: Red=K1, Green=H6, Blue=K2
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {led3[0]}]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports {led3[1]}]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {led3[2]}]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {hum_dec[0]} {hum_dec[1]} {hum_dec[2]} {hum_dec[3]} {hum_dec[4]} {hum_dec[5]} {hum_dec[6]} {hum_dec[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {hum_int[0]} {hum_int[1]} {hum_int[2]} {hum_int[3]} {hum_int[4]} {hum_int[5]} {hum_int[6]} {hum_int[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dist_int[0]} {dist_int[1]} {dist_int[2]} {dist_int[3]} {dist_int[4]} {dist_int[5]} {dist_int[6]} {dist_int[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {w_sonar_dist[0]} {w_sonar_dist[1]} {w_sonar_dist[2]} {w_sonar_dist[3]} {w_sonar_dist[4]} {w_sonar_dist[5]} {w_sonar_dist[6]} {w_sonar_dist[7]} {w_sonar_dist[8]} {w_sonar_dist[9]} {w_sonar_dist[10]} {w_sonar_dist[11]} {w_sonar_dist[12]} {w_sonar_dist[13]} {w_sonar_dist[14]} {w_sonar_dist[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {temp_int[0]} {temp_int[1]} {temp_int[2]} {temp_int[3]} {temp_int[4]} {temp_int[5]} {temp_int[6]} {temp_int[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {temp_dec[0]} {temp_dec[1]} {temp_dec[2]} {temp_dec[3]} {temp_dec[4]} {temp_dec[5]} {temp_dec[6]} {temp_dec[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {w_dht_hum[0]} {w_dht_hum[1]} {w_dht_hum[2]} {w_dht_hum[3]} {w_dht_hum[4]} {w_dht_hum[5]} {w_dht_hum[6]} {w_dht_hum[7]} {w_dht_hum[8]} {w_dht_hum[9]} {w_dht_hum[10]} {w_dht_hum[11]} {w_dht_hum[12]} {w_dht_hum[13]} {w_dht_hum[14]} {w_dht_hum[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 16 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {w_dht_temp[0]} {w_dht_temp[1]} {w_dht_temp[2]} {w_dht_temp[3]} {w_dht_temp[4]} {w_dht_temp[5]} {w_dht_temp[6]} {w_dht_temp[7]} {w_dht_temp[8]} {w_dht_temp[9]} {w_dht_temp[10]} {w_dht_temp[11]} {w_dht_temp[12]} {w_dht_temp[13]} {w_dht_temp[14]} {w_dht_temp[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list button_IBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list ctrl_start]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list data_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list dht_rx_data]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list echosr04_IBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list p_0_in]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list trigsr04_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list w_dht_error]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list w_dht_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list w_sonar_done]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_IBUF_BUFG]
