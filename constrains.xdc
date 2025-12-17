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
