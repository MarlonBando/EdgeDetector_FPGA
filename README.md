# Edge Detection and Pixel Inversion Project

This project implements an edge detector and a pixel inversion system. These systems are used to process images on FPGA hardware, specifically the Nexys 4 DDR board. All details about the implementation and design are documented in the attached PDF report.

## What is an Edge Detector?

An edge detector is a tool used in image processing to identify boundaries or edges within an image. The implemented edge detector in this project utilizes the Sobel operator to calculate gradients and detect significant intensity changes, which correspond to edges in the image.

## Project Overview

The project contains the following components:

- **`inverter/`**  
  Contains the files required to perform pixel inversion. The inversion transforms each pixel in an image using the formula `255 - pixel_value`.

- **`edge_detector/`**  
  Contains all the files necessary to run the edge detection system, including the Sobel operator implementation.

- **`doc/`**  
  Includes the project requirements and the detailed report (`Group_25_Design_Of_Digital_Systems_Assignment_2.pdf`) explaining the implementation, methodology, and results.

- **`other_images/`**  
  Provides a set of sample images that can be used for testing the edge detection system.

## Inputs and Outputs

- **Inputs:**  
  - Images in a compatible format are used as input for the pixel inversion and edge detection systems.
  - Control signals (start, clock, etc.) to initiate and manage processing on the FPGA.

- **Outputs:**  
  - Processed images, with inverted pixels or edges detected, are stored back in memory or displayed based on the application setup.

## How to Run

1. Open the project in **Vivado** (tested on version 2024.x or later).
2. Load the provided design files for simulation or synthesis.
3. Select the target hardware: **Nexys 4 DDR** FPGA board.
4. Use the testbench files to simulate the system in Vivado or program the FPGA for real-time testing.

## Additional Information

- All details about the design, functionality, and performance analysis are available in the provided PDF report: [`Group_25_Design_Of_Digital_Systems_Assignment_2.pdf`](Group_25_Design_Of_Digital_Systems_Assignment_2.pdf).
- Refer to the `doc/` directory for more insights into the project requirements and specifications.

---

## Authors

- **Myrsini Gkolemi** (s233091)  
- **Christopher Mardones-Andersen** (s205119)  
- **Michele Bandini** (s243121)  

For any questions or issues, feel free to contact the authors listed above.
