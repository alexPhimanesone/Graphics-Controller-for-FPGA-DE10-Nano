# Graphics Controller for FPGA DE10-Nano

The DE10-Nano is based on a Cyclone V SoC FPGA. This circuit has the characteristic of regrouping in the same box a classic FPGA architecture and a microprocessor block named HPS (for Hard Processor System) composed of a double ARM Cortex A9 processor.

This project aims to display on an LCD screen the images sent by the microprocessor integrated into the circuit. The control is handled by the FPGA.

* A Linux system (on the HPS) transmits to the FPGA a video stream.
* The FPGA tries to write the video stream into the image memory.
* The graphics controller part of the FPGA reads into the image memory (via a Wishbone interface).
* An arbiter shares memory access between the graphics controller and the video stream.
* After having read, the graphics controller displays the images on an LCD screen. Reading and displaying operate at 2 different clock frequencies, a FIFO buffer memory is used to make the two processes communicate.
