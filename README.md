****32-bit Pipelined RISC Processor****

**Overview**

This project implements a 32-bit 5-stage pipelined RISC processor using Verilog HDL.

The processor follows a classic RISC pipeline architecture and incorporates hazard detection and data forwarding mechanisms to ensure correct and efficient instruction execution.

The design is modular, synthesizable, and verified through simulation using Verilog testbenches.


**Key Features**

32-bit RISC architecture

5-stage pipelined design (IF, ID, EX, MEM, WB)

Hardwired control unit

Data hazard handling using forwarding

Pipeline hazard detection and stall logic

Separate instruction and data memory

Synthesizable RTL code

Modular and scalable design


**Pipeline Architecture**
Pipeline Stages

STAGES          	DESCRIPTION

IF	            Instruction Fetch
ID	            Instruction Decode & Register Fetch
EX	            Execute / ALU operations
MEM	            Data Memory Access
WB	            Write Back to Register File

Pipeline registers implemented:

IF/ID

ID/EX

EX/MEM

MEM/WB

Refer to docs/pipeline_architecture.png for the block diagram.


**Instruction Set (ISA – Summary)**

CATEGORY	            INSTRUCTIONS

Arithmetic	          ADD, SUB
Logical	              AND, OR, NOT
Memory	              LOAD, STORE
Control	              JUMP_C, JUMP_Z



**📁 Project Structure**
├── source_codes/        # RTL source files (Verilog)
├── testbenches/         # SystemVerilog testbenches
├── png_diagrams/       # Architecture diagrams and report
├── test_outputs/    # Simulation results (waveforms/images)
└── README.md


**Simulation & Verification**

Testbenches written in Verilog

Functional verification through waveform analysis

Pipeline behavior verified for:

Data hazards

Forwarding paths

Stall conditions

Supported simulators:

Verilator
Iverilog
ModelSim


**Tools & Technologies**

Verilog HDL

SystemVerilog

Iverilog

GTKWave

**How to Run (Example – Iverilog)**
1. Compile Source_code and Testbench using Command prompt
   
   iverilog -g2012 -o cpu_sim \
   src/*.v \
   tb/cpu_tb.v
   
3. Run Sumulation
   
   vvp cpu_sim
   
4. View Waveforms (GTKWave)

   gtkwave wave.vcd


**Results**

Correct execution of supported instructions

Successful pipeline operation with hazard handling

Verified data forwarding and stall logic


**Future Enhancements**

Branch prediction

Interrupt handling

Cache memory integration

Deeper pipelining

Performance analysis (CPI)


