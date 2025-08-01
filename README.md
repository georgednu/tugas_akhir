# Power Hardware-in-the-loop
Power Hardware-in-the-loop (PHIL) is a method of testing power converter circuits by emulating the circuit using the mathematical model of the circuit. This project specifically implements PHIL for DC-DC Converter control system testing. The implementation is targeted on the Eclypse Z7 platform which is equipped with the Zynq-7000 series SoC. This project utilizes the state space equation of the circuit as a lightweight model for the circuit.

$$
\dot{x} = A x + B u
$$
$$
y = C x + D u
$$

## Description
RTL directory stores the RTL verilog files. These Verilog files are copied into Vivado to be synthesized and implemented. The system is designed to be configurable. System configuration can be changed in def.vh file/

constr directory includes the constraint files for the FPGA implementation. These constraints targets the Eclypse Z7 platform with Zmod 1410 and Zmod 1411 as the ADC and DAC. The PMOD can also be used as an alternative of the ADC to get the PWM input.

The app_component directory includes the baremetal C code for the PS side which mainly manage the communication with PC.

## Platform
This project is implemented and tested with these tools:
1. Vivado 2024.1
2. Vitis 2024.1

The system is implemented on Eclypse Z7 SoC board complete with the Zmod 1411 and Zmod 1410 installed on the SYZYGY ports. The board files can be obtained here
https://github.com/Digilent/vivado-boards

To use the Zmod modules, some additional IP has to be added into Vivado.
https://github.com/Digilent/vivado-library/tree/zmod/v2/2019.1-2/ip

## Setup
To start implementing, follow these steps:
1. Create a new project in Vivado. Then copy the RTL and constraint files using the import feature.
2. Get the IP files for the Zmod AWG Controller (DAC Controller) and the Zmod Scope Controller (ADC Controller).
3. Create a block diagram and include the ADC controller, DAC controller, DMA, PS, and the top level of the RTL. Refer to the documentation for the connection.
4. Synthesize, implement, and generate bitstream file. Then export the hardware files with the "include bitsream file" checked.
5. Open Vitis, create new project in the same project directory.
6. Choose the xsa file exported in step 4 as the hardware specification. This step is repeated every time a change is done to the PL side. Make sure the bitstream file inside the IDE directory is changed
7. Copy the app_component c files into the src directory of the app_component.
8. To Run, build the project, connect the Eclypse Z7, turn it on, and click Run. (Make sure the Eclypse Z7 boot mode jumper is set to JTAG)
9. After testing is passed, Build and generate the BOOT files. Insert the BOOT files inside an SD card and insert it into the Eclypse Z7 board. Make sure the boot mode jumper is set to SD instead of JTAG.
