# FPGA Sensor System: Distance, Temperature & Humidity Monitor

A team course project ("FPGA Device Design Automation", Peter the Great St. Petersburg Polytechnic University, 2025). The device measures distance, temperature, and humidity with an HC-SR04 ultrasonic sensor and a DHT11 sensor, and shows the readings in real time on a VGA monitor. Implemented in SystemVerilog on a Digilent Arty A7-35T (Xilinx Artix-7) using Vivado.

## Features

- Distance measurement with the HC-SR04 ultrasonic sensor
- Temperature and humidity measurement with the DHT11 sensor (single-wire protocol)
- Periodic, synchronized polling of both sensors
- VGA output at 640x480 @ 60 Hz with on-screen text
- A button switches the screen between temperature/humidity and distance
- Status indication on LEDs and RGB LEDs (data valid, sensor error, trigger/echo activity, button state, frame sync)
- Hardware debugging with an integrated logic analyzer (ILA)
- Testbenches for the sensor drivers, the sensor interface, and the VGA module
- Project build from a Vivado TCL script

## Hardware

| Item | Details |
|---|---|
| Board | Digilent Arty A7-35T (Artix-7) |
| Clock | 100 MHz system clock |
| Distance sensor | HC-SR04 (TRIGGER / ECHO) |
| Temperature & humidity sensor | DHT11 (single-wire bidirectional) |
| Display | VGA monitor, 640x480 @ 60 Hz |
| I/O standard | LVCMOS33 (pin and timing constraints in `constraints.xdc`) |

## Architecture

```
                 +-------------------+
 HC-SR04 <-----> | hc_sr04_driver    |--+
                 +-------------------+  |   +------------------+      +----------+
                                        +-->| sensor_interface |----->| VGA_top  |--> VGA
                 +-------------------+  |   +------------------+      +----------+
 DHT11   <-----> | DHT11_driver      |--+            ^
   (IOBUF)       +-------------------+               |
                                                   button
```

`top_module` connects the drivers, the sensor interface, and the VGA controller, and adds the status LEDs and the ILA.

## Modules

| Module | Purpose |
|---|---|
| `hc_sr04_driver` | HC-SR04 driver: generates the 10 µs TRIGGER pulse, measures the ECHO pulse width with the system clock, and converts it to distance. FSM with a `start` / `done` handshake. |
| `DHT11_driver` | DHT11 driver: sends the start signal (18 ms), reads the 40-bit data packet, validates it, and reports errors. Uses an `IOBUF` primitive for the bidirectional line. |
| `sensor_interface` | Synchronizes both drivers, polls them periodically (the `TIMER_LIMIT` parameter sets the period, limited by the DHT11's 2 s minimum interval), buffers the data, and outputs integer and fractional parts for the display. 4-state FSM: `IDLE`, `START_DELAY`, `WAIT_SENSORS`, `UPDATE_OUTPUT`. |
| `simple_480p` | VGA timing generator: pixel coordinates and HSYNC / VSYNC / data-enable for 640x480 @ 60 Hz. |
| `font_rom` | Character bitmap ROM for on-screen text. |
| `VGA_top` | Converts binary values to BCD, builds the text, and draws it; 25 MHz pixel clock derived from the 100 MHz system clock; the button toggles the displayed mode. |
| `pulse_stretcher` | Stretches one-clock status pulses (10 ns) to a visible length (about 0.2 s) for the LEDs. |
| `top_module` | Top level: instantiates all modules, the `IOBUF`, the LEDs, and the ILA. |

## HC-SR04 driver

1. Wait for the `start` pulse.
2. Drive TRIGGER high for 10 µs.
3. Wait for the rising edge of ECHO.
4. Count system-clock cycles while ECHO is high.
5. Convert the pulse width to distance, then pulse `done` and present the result.

The sensor interface decides when to start a measurement. A DHT11 error does not block the distance reading.

## Debugging

Key signals are marked with `mark_debug` and observed in an ILA over JTAG: sensor data and status, control signals, the values formatted for the display, the physical sensor lines, and the data-ready flag. This confirmed the capture of the 40-bit DHT11 packet and the measurement of the ECHO pulse on the running device.

## Simulation

Testbenches cover:

- DHT11 driver with a valid packet and with a corrupted packet (the error flag is raised)
- HC-SR04 driver with test distances
- Sensor interface with and without DHT11 errors
- VGA module (timing, sync signals, color outputs) with test sensor data and the mode button

During VGA debugging, undefined (X / Z) signals in early simulations were traced to missing resets in the pixel-clock divider and counters and to mismatched RGB port widths, and were fixed with explicit resets and `logic [3:0]` color buses.

## Build

The project is built from a Vivado TCL script, which creates the project, adds sources and constraints, and runs synthesis, implementation, and bitstream generation. Program the Arty A7-35T with the generated bitstream.

## Usage

1. Connect the HC-SR04 and DHT11 sensors to the pins defined in `constraints.xdc`.
2. Connect a VGA monitor.
3. Program the board.
4. Press the button to switch between temperature/humidity and distance.

## Team

Team project. Dmitrii Sergeev: independent development of the HC-SR04 driver, and debugging of `top_module` and `sensor_interface`.
