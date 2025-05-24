# FPGA-UltrasonicRadar
1-dimensional object mapper created in SystemVerilog using a Xilinx Spartan-7 FPGA board and an HC-SR04 Ultrasonic Sensor. Displays real-time object position on an HDMI or VGA display.

## System Description
This is a SystemVerilog-based 1D ultrasonic radar using the HC-SR04 ultrasonic sensor and a Xilinx Spartan-7 FPGA that outputs real-time distance data for the closest object to the sensor. 

Distance is displayed through a live centimeter-based distance tracker, and a red on-screen 'X' will move along the screen based on the object's live position changes. Positional benchmarks are included for the user. Distance range is 2-400 cm.

Moving within 15 centimeters of the sensor will play an aggressive audio alert on the connected audio device and rapidly flash the screen in red and black.

## Setup
1. Plug in programming cable to a system running Xilinx Vivado.
2. Wire 9 V power supply to breadboard circuit as shown in circuit diagram.
3. Wire TRIG (green wire) and ECHO (orange wire) to the J13 and J14 (JA3_P, JA3_N) GPIO connectors on the FPGA, respectively.
   - **Note**: This implementation is for the RealDigital Urbana Board. Using any other board's GPIO pins will require the constraints (.xdc) file to be modified accordingly.
4. Connect an audio output device e.g. headphones, speaker to the audio output port of the FPGA.
5. Load .xpr project file in Vivado (or all necessary source files if using a different development platform).
6. Connect board through Hardware Manager and generate bitstream.

## Usage
1. Take an object and move it back and forth in front of the HC-SR04 sensor.
   - For best results, use an object with a relatively large surface area made of solid material, such as cardboard or plastic.
2. Observe the changes in the live distance tracker as the on-screen object moves across the centimeter benchmarks.
3. Visual and audio alerts will trigger upon moving within 15 centimeters of the sensor.
4. Pressing BTN0 (again, change constraints if using a different board) will reset the system.

## Circuit Diagram and Schematic

### Breadboard Layout
![Breadboard Layout](https://github.com/user-attachments/assets/e7e663dd-c9e9-471b-9674-2df4a22da511)

### Circuit Schematic
![Circuit Schematic](https://github.com/user-attachments/assets/d9ce0682-4f70-4247-b644-87e5b839d4fd)

## Demo
[Video Demo](https://drive.google.com/file/d/1A6Ar55RKtZArzim9-CnAboWGmMGdUVhR/view?usp=sharing)

## Notes
- In building the sensor circuit, the 9-volt battery can be replaced with a constant 9-volt bench power supply
- No block design or Vitis files are required, just ensure the HDMI/DVI Encoder and Clocking Wizard IPs are instantiated.
  - Clocking wizard should be 100 MHz, single-ended. HDMI/DVI encoder behaves as a VGA to HDMI controller when HDMI is selected in the IP configuration.

## Roadmap
- 2-dimensional version with the use of a rotating servo motor is being researched
- May expand to use Python-based post-processing for DSP filtering rather than using SystemVerilog-based filters
