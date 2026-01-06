# fpga-ip-sensor-arty7
FPGA sensor IP cores (BH1750 &amp; DHT11) implemented in VHDL on Arty A7-35 platform.

[![DEMO ON YouTube](https://img.youtube.com/vi/fp8oZTBzxIA/0.jpg)](https://youtu.be/fp8oZTBzxIA)

# FPGA IP Sensor System on Arty A7

This repository contains an FPGA-based sensor interface system designed and implemented on the **Digilent Arty A7** development board.  
The project focuses on designing **custom hardware IP cores** for environmental sensors and integrating them into a modular FPGA system.

## 📌 Project Overview

The main objective of this project is to design sensor reading modules that operate **independently of software**, using hardware logic and finite state machines (FSMs).  
Sensor data is collected periodically and made available to the processing system through memory-mapped registers.

The project is developed as part of an academic FPGA / digital system design course.

## 🧩 Implemented Sensor IP Cores

### 1. BH1750 Light Sensor IP
- Digital light intensity sensor
- I²C communication protocol
- Hardware-based I²C controller (bit-banging)
- Finite State Machine (FSM) following the datasheet measurement procedure
- Outputs raw light data (16-bit) and data valid signal
- Designed to work with an external IP Timer for periodic measurement

### 2. DHT11 Temperature & Humidity Sensor IP
- Single-wire bidirectional communication protocol
- Fully hardware-controlled timing and data acquisition
- FSM-based implementation strictly following DHT11 timing specifications
- Reads:
  - Humidity (integer part)
  - Temperature (integer part)
  - Checksum for data validation
- Designed to operate without CPU intervention

## ⚙️ System Architecture

The system is composed of:
- **IP Timer**: Generates periodic trigger signals
- **Sensor IP cores**: BH1750 and DHT11
- **AXI4-Lite Interface** (optional): Allows software access to sensor data
- **Finite State Machines (FSMs)**: Control all sensor communication sequences

All sensor communication is handled entirely in hardware, improving system determinism and reducing processor load.

## 🛠 Development Environment

- FPGA Board: Digilent Arty A7
- Language: VHDL,C
- Tools:
  - Xilinx Vivado, Vitis
  - Git & GitHub
  - draw.io (FSM diagrams)
  - LaTeX (technical report)
## 📖 Documentation

- FSM diagrams are drawn based on official sensor datasheets
- Timing parameters strictly follow manufacturer specifications
- Code is written for clarity and educational purposes

## 🚀 Future Improvements

- Add AXI4-Lite register interface for all sensor IPs
- Implement CRC checking for DHT11 data
- Extend system to support additional sensors
- Optimize I²C clock generation logic

## 👤 Author

- **GitHub**: [dathavan1523](https://github.com/dathavan1523)
- Project developed for academic and learning purposes

---

## 📜 License

This project is intended for educational use.  
Feel free to study, modify, and reuse the code without proper attribution.


