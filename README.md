## System Description
This is a SystemVerilog-based 1D ultrasonic radar using the HC-SR04 ultrasonic sensor and a Xilinx Spartan-7 FPGA that outputs real-time distance data for the closest object to the sensor. 

Distance is displayed through a live centimeter-based distance tracker, and a red on-screen 'X' will move along the screen based on the object's live position changes. Positional benchmarks are included for the user. Distance range is 2-400 cm.

Moving within 15 centimeters of the sensor will play an aggressive audio alert on the connected audio device and rapidly flash the screen in red and black.

A demonstration video of the operation of this radar can be found at the bottom of this README.

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

## System Operation
### Breadboard Circuit Operation
The HC-SR04 Ultrasonic Sensor has 4 pins: TRIG, ECHO, Vcc, GND. All pins (except GND) operate at a 5 volt input. I did not have a 5 volt power supply on hand (my FPGA only outputs 3.3 V), so I created a voltage divider circuit to step down a 9 V load to 5 V.
The TRIG pin is the input: a short pulse is sent to the sensor, signaling it to record a measurement. The sensor does this by outputting an 8-cycle sonic burst. Upon reception of the reflected burst, the sensor outputs an ECHO signal that remains high for a duration proportional to the time it took for the 8-cycle burst to come back to the sensor after it was sent. A longer time between sending and receiving indicates the burst traveled a longer distance before it was reflected back by the nearest object, or traveled for less time if the burst came back quicker. Therefore, the longer the ECHO, the farther the object.
   - The trigger is produced by a finite state machine, shown below. It is constantly being generated and sent to the FPGA based on a specific timing schedule, also shown below.

### Data Processing and DSP Filtering
When the FPGA receives the ECHO signal, it is converted into a tick-based raw distance (22 bit-wide register), processed through clock-based (100 MHz) counter logic and the aforementioned FSM. This data is then sent through a variety of DSP filters:
   - A median-of-3 filter, which smooths data by taking the median of the first three incoming distance samples through use of a shift register,
     * A median filter with a greater window e.g. median-of-5 or median-of-7 will provide greater noise removal at the cost of timing.
   - a clamping filter, which removes arbitrary spikes caused by dips in between sensor measurements,
   - and a deadband filter, which silences 1-2 pixel jitters in the on-screen's object position changes.
These filters lead to a greatly effective stabilization of measurement data and smooth out a vast majority of any noise produced by the sensor.

### System Output
The distance is then scaled to fit on a 640-pixel long VGA display, and an object mapper module places a red X on the screen based on the current pixel distance, converted from the filtered distance register. This object mapper module also assigns the left-hand side of the screen to 2 cm and the right-hand side to 400 cm, accurately representing the physical constraints of the sensor. Visual benchmarks in the style of a standard radar or measuring devices are generated for user benefit.

A live counter displays the distance, in centimeters, of the object from the ultrasonic sensor. A font read-only-memory (ROM) is used to draw the dynamically-changing 16x8 pixel ASCII numbers based on a binary (background/foreground) coloring scheme.

A proximity alert module drives an alert signal high whenever the object reaches within 15 centimeters of the sensor. This parameter, calculated via (THRESHOLD_DISTANCE_CM * 2 * 100 / 0.0343 [decimal] --> THRESHOLD_DISTANCE [hex]), can be changed in the proximity alert module if a different threshold is desired.
A tone generator then creates an oscillating square wave at a given frequency, wired to the auxiliary audio outputs of the FPGA (when the alert signal is high) to produce a sustained beep when the object is in proximity. This alert signal is also used in a color mapper module, which creates the color scheme for the on-screen visuals, to flash the screen in red and black every 0.5 seconds. An RGB LED is wired to the alert signal for debugging purposes.

![HC-SR04 Ultrasonic Sensor Timing Diagram](https://github.com/user-attachments/assets/9998927f-5f37-4cfd-b615-ae39f8c4ea55)
Timing diagram of the HC-SR04 ultrasonic sensor

![FSM of Ultrasonic Radar](https://github.com/user-attachments/assets/ec2d3f66-49f0-44a3-9810-d2c4384c2744)
Finite State Machine of the Ultrasonic Radar

## Demo
[Video Demo](https://drive.google.com/file/d/1A6Ar55RKtZArzim9-CnAboWGmMGdUVhR/view?usp=sharing)

## Notes
- In building the sensor circuit, the 9-volt battery can be replaced with a constant 9-volt bench power supply
- No block design or Vitis files are required, just ensure the HDMI/DVI Encoder and Clocking Wizard IPs are instantiated.
  - Clocking wizard should be 100 MHz, single-ended. HDMI/DVI encoder behaves as a VGA to HDMI controller when HDMI is selected in the IP configuration.

## Roadmap
- 2-dimensional version with the use of a rotating servo motor is being researched
- May expand to use Python-based post-processing for DSP filtering rather than using SystemVerilog-based filters
