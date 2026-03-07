32-bit Pipelined RISC Processor (Verilog)
Overview

This project implements a 32-bit pipelined RISC processor designed using Verilog HDL. The processor follows a 5-stage pipeline architecture to improve instruction throughput and overall performance. The design includes mechanisms to handle data hazards and control hazards, making it a functional demonstration of a pipelined CPU.

The processor is modular and each stage is implemented and verified individually using task-based testbenches.

Pipeline Architecture

The processor is divided into five pipeline stages:

Instruction Fetch  →  Instruction Decode  →  Execute  →  Memory  →  Writeback
      (IF)                  (ID)              (EX)        (MEM)       (WB)
1. Instruction Fetch (IF)

Fetches instructions from instruction memory

Maintains the program counter (PC)

Computes the next PC value

Handles branch/jump target selection

Main components:

Program Counter

Instruction Memory

Outputs:

Instruction register

PC + 1

2. Instruction Decode (ID)

Decodes the fetched instruction

Reads operands from the register file

Generates control signals

Performs immediate value extension

Main components:

Control Unit

Register File

Sign Extender

Outputs:

Operand data

Control signals

Immediate value

Destination register address

3. Execute (EX)

Performs arithmetic and logical operations

Handles ALU operations

Selects operands using forwarding logic

Computes intermediate results

Main components:

ALU

Forwarding logic

Operand selection logic

Outputs:

ALU result

Flags (zero, carry)

Write data for memory stage

4. Memory (MEM)

Performs data memory read and write operations

Stores results from the execute stage

Main component:

Data Memory

Outputs:

Memory read data

ALU result forwarding

5. Writeback (WB)

Writes results back to the register file

Sources of writeback data:

ALU result

Memory read data

Immediate values

Hazard Handling
Data Hazards

Handled using a forwarding unit.

The forwarding logic checks if the source registers of the current instruction match destination registers of instructions in later pipeline stages.

Possible forwarding sources:

Forward from Memory stage
Forward from Writeback stage

Forwarding control signals:

forward_a
forward_b
Control Hazards

Handled using a branch control unit.

Branch decision is based on ALU flags:

branch_z → branch on zero
branch_c → branch on carry

When a branch condition is satisfied:

PC ← branch target address
Processor Modules

Main modules implemented in the design:

fetch_stage.v
decoder.v
execute.v
memory_stage.v
writeback_stage.v

Supporting modules:

program_counter.v
instruction_memory.v
register_memory.v
alu.v
memory.v
control_unit.v
sign_extender.v

Hazard handling modules:

data_hazard_control.v
control_hazard_sol.v
Testbenches

Each module was verified individually using task-based SystemVerilog testbenches.

Testbenches verify:

Instruction fetch operation

Register file access

ALU functionality

Memory read/write

Hazard forwarding logic

Branch control logic

Example verification approach:

task apply_instruction();
task monitor_outputs();
task test_forwarding();
Features

32-bit RISC architecture

5-stage pipeline

Modular Verilog design

Data hazard handling using forwarding

Control hazard handling for branch instructions

Task-based verification environment

Tools Used

Verilog / SystemVerilog

Simulation tools:

ModelSim / QuestaSim / Verilator

Version control:

Git

GitHub

Future Improvements

Possible enhancements for the processor:

Pipeline stall unit

Branch prediction

Cache memory

Interrupt handling

More instruction types

Full system simulation

Learning Outcomes

Through this project the following concepts were implemented and verified:

Pipelined processor architecture

RTL design using Verilog

Hazard detection and forwarding

Control unit design

Task-based verification

Modular hardware design
