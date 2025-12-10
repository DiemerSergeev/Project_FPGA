## Clock signal (100 MHz)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; 
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Reset Button (Active Low on Arty A7 usually, Pin C2)
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { rst }];

## User Button (BTN0 - Pin D9)
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { button }];

## ChipKit / Arduino Header Pins
## VGA Signals (Mapping based on your UCF)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { hsync }];   # IO0
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { vsync }];   # IO1
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { vgadata }]; # IO2

## Sensors
## DHT11 Data Line (IO3)
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { dataDHT11 }]; 

## HC-SR04 Ultrasonic Sensor
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { echosr04 }]; # IO4
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { trigsr04 }]; # IO5

## Configuration options (Optional but recommended for Arty A7)
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]