# Custom 5-Stage Pipelined Processor in Verilog

## Overview

This project implements a **custom 32-bit 5-stage pipelined processor** in **Verilog HDL**.
The processor supports a compact custom instruction set for:

* ALU operations
* Immediate-to-register operations
* Immediate-to-memory operations
* Memory-to-register load
* Register-to-memory store
* Conditional branch on **zero**
* Conditional branch on **carry**

The design follows a classic **5-stage pipeline**:

1. **Fetch**
2. **Decode**
3. **Execute**
4. **Memory**
5. **Writeback**

The processor also includes:

* **data forwarding / hazard handling**
* **basic control hazard handling for branches**
* a **self-checking SystemVerilog testbench**
* **waveform-based verification** for important scenarios such as ALU writeback, store/load, store forwarding, and branching

---

# Features

## 1. 5-stage pipelined datapath

The processor is divided into the following stages:

### Fetch Stage

* Holds and updates the **program counter (PC)**
* Fetches instructions from instruction memory
* Supports normal sequential fetch and branch redirection

### Decode Stage

* Decodes the opcode and generates control signals
* Reads operands from the register file
* Generates immediate values
* Passes branch target information

### Execute Stage

* Performs ALU operations
* Selects forwarded operands when needed
* Generates ALU result
* Prepares store data and store address for memory operations

### Memory Stage

* Handles memory read / write operations
* Stores data into memory for store instructions
* Reads memory data for load instructions

### Writeback Stage

* Selects the final result to be written back to the register file
* Supports:

  * immediate writeback
  * ALU result writeback
  * memory data writeback

---

## 2. Hazard handling

The design includes:

### Data hazard forwarding

A forwarding unit is used to resolve read-after-write dependencies by forwarding values from:

* **Memory stage**
* **Writeback stage**

This is especially important for:

* back-to-back ALU instructions
* store instructions using a just-produced register value

### Control hazard handling

Branch instructions are supported using a simple branch control block that checks:

* **zero flag**
* **carry flag**

and redirects the PC to the branch target when the branch condition is satisfied.

---

# Processor Architecture

## Top-level modules

The design is split into the following RTL modules:

* `pipelined_processor.v` – top-level integration of all stages
* `fetch_stage.v` – instruction fetch logic and PC path
* `prog_c.v` – program counter
* `instr_mem.v` – instruction memory
* `decoder.v` – decode stage, register file access, immediate generation
* `control_unit.v` – opcode decode and control generation
* `reg_file.v` – 32-register register file
* `execute.v` – ALU stage, operand selection, forwarding use
* `alu.v` – arithmetic and logic unit
* `memory.v` – data memory
* `memory_stage.v` – memory pipeline stage
* `writeback_stage.v` – final result selection for register writeback
* `data_hazard_control.v` – forwarding control logic
* `control_hazard_sol.v` – branch decision / PC redirection logic

---

# Architecture / Schematic

The project was also viewed in **Vivado RTL / elaborated schematic view** to visualize the overall processor architecture and the pipeline datapath.

## Top-level processor schematic

This view shows the major blocks of the processor and their interconnections:

* `fetch1`
* `decode1`
* `ex1`
* `memst1`
* `wrb1`
* `hazard_control1`
* `control_hazard1`



```md
Schematic.png
```


> **Note:** The schematic images used in this project are from Vivado’s **elaborated / RTL schematic view**. For documentation purposes, this view is often clearer than the synthesized netlist view because it preserves module hierarchy and is easier to understand.

---

# Pipeline Stages

## 1) Fetch Stage

The fetch stage performs:

* PC update
* instruction fetch from instruction memory
* branch redirection when `jump = 1`

### Main signals

* `pc`
* `pc_nxt`
* `pctarget`
* `instr_reg`

---

## 2) Decode Stage

The decode stage:

* decodes the instruction opcode
* reads source registers from the register file
* generates control signals
* generates immediate values
* passes destination register information to the next stage

### Main outputs

* `reg_write_o`
* `mem_write_o`
* `result_src_o`
* `alu_src_o`
* `alucontrol_o`
* `data1_o`
* `data2_o`
* `imm_ext_o`
* `rdw_o`

---

## 3) Execute Stage

The execute stage:

* selects operands for the ALU
* applies forwarding if required
* performs ALU operations
* prepares write data for store instructions
* passes ALU result forward in the pipeline

### Main outputs

* `alu_result_o`
* `write_data_o`
* `write_addr_e`
* `carry`
* `zero`

---

## 4) Memory Stage

The memory stage:

* writes data to memory for store operations
* reads data from memory for load operations
* passes memory result / ALU result to the writeback stage

---

## 5) Writeback Stage

The writeback stage chooses which value should be written into the register file:

* immediate value
* ALU result
* memory read data

---

# Custom Instruction Format

This processor uses a **custom instruction encoding**, not standard RISC-V encoding.

## Common instruction fields

* **bit [31]**: selects instruction type / immediate ALU behavior depending on opcode usage
* **bits [30:27]**: main opcode
* other fields are interpreted differently depending on instruction type

---

# Supported Operations

## ALU Operations

The following ALU operations are supported:

| ALU Op | Meaning     |
| ------ | ----------- |
| `0000` | Pass A      |
| `0001` | Add         |
| `0010` | Subtract    |
| `0011` | AND         |
| `0100` | OR          |
| `0101` | NOT         |
| `0110` | Shift Left  |
| `0111` | Shift Right |

---

# High-level Instruction Classes

## 1. Immediate to Register

Loads an immediate value into a register.

## 2. Immediate to Memory

Stores an immediate value directly into memory.

## 3. Memory to Register

Loads data from memory into a register.

## 4. Register to Memory

Stores register data into memory.

## 5. ALU Operation

Performs an ALU operation on source operands.

## 6. ALU Result Writeback

Writes the previously generated ALU result into the destination register.

## 7. Branch on Zero

Branches to target when zero flag is set.

## 8. Branch on Carry

Branches to target when carry flag is set.

---

# Register File

The register file contains **32 registers**, each **32 bits wide**.

* two read ports
* one write port
* synchronous write
* combinational read

---

# Memory

The processor uses a simple memory array for data storage.

* word-oriented access
* used for both store and load verification scenarios
* memory address is derived from the encoded instruction / pipeline control logic depending on instruction type

---

# Verification

## Testbench

Verification is done using a **self-checking SystemVerilog testbench**:

* `tb_pipelined_processor.sv`

The testbench:

* initializes instruction memory and data memory
* loads custom-encoded instructions
* runs the processor for a fixed number of cycles
* checks register and memory contents automatically
* reports PASS / FAIL messages for each test

---

# Verified Test Scenarios

The following scenarios were verified successfully:

## 1. Reset

Checks reset behavior of the processor and pipeline state.

## 2. Immediate to Register

Verifies immediate values are correctly written into registers.

## 3. Immediate to Memory

Verifies immediate data can be stored into memory.

## 4. Memory to Register

Verifies memory read and register writeback path.

## 5. ADD + Writeback

Verifies:

* ALU add operation
* ALU result propagation through pipeline
* writeback into destination register

## 6. SUB + Writeback

Verifies subtraction and ALU result writeback.

## 7. Logic Operations

Verifies:

* AND
* OR
* NOT
* Shift Left

## 8. Store then Load

Verifies correct store to memory followed by load back into register.

## 9. Register to Memory

Verifies storing register data into memory.

## 10. Store Forwarding

Verifies forwarding of a newly generated register value into a store operation without waiting for full register writeback.

## 11. Shift Right

Verifies right-shift operation.

## 12. Branch Zero Not Taken

Verifies correct non-taken branch behavior.

## 13. Branch Carry

Verifies branch behavior based on carry flag.

## 14. Back-to-Back ALU Chain

Verifies forwarding and correct operation for dependent ALU instructions.

## 15. Same Register as Both Operands

Verifies correct behavior when the same register is used as both source operands.

---

# Waveform Verification

Waveforms were captured for key scenarios to verify datapath behavior and hazard handling.

## Waveforms captured

* **ADD + Writeback**
* **Store then Load**
* **Store Forwarding**
* **Branch Zero**
* **Back-to-Back ALU Chain**

These waveforms demonstrate:

* PC progression
* instruction flow through the pipeline
* ALU result generation
* register writeback
* memory store / load path
* forwarding behavior
* branch redirection

---

# Simulation Output

The processor was verified using the self-checking testbench, and the final simulation output showed successful execution of the implemented tests.

Add the final console result screenshot here:

```md
![All Tests Passed](outputs/all_tests_passed.png)
```

---

# Folder Structure

```text
RISC-V/
├─ src/
│  ├─ pipelined_processor.v
│  ├─ fetch_stage.v
│  ├─ prog_c.v
│  ├─ instr_mem.v
│  ├─ decoder.v
│  ├─ control_unit.v
│  ├─ reg_file.v
│  ├─ alu.v
│  ├─ execute.v
│  ├─ memory.v
│  ├─ memory_stage.v
│  ├─ writeback_stage.v
│  ├─ data_hazard_control.v
│  └─ control_hazard_sol.v
│
├─ tb/
│  └─ tb_pipelined_processor.sv
│
├─ waveforms/
│  ├─ add_writeback_waveform.png
│  ├─ store_load_waveform.png
│  ├─ store_forwarding_waveform.png
│  ├─ branch_zero_waveform.png
│  └─ back_to_back_alu_chain.png
│
├─ outputs/
│  └─ all_tests_passed.png
│
├─ docs/
│  ├─ top_level_schematic.png
│  └─ pipeline_datapath_schematic.png
│
└─ README.md
```

---

# How to Run

The design was simulated in **Vivado / XSim**.

## Basic flow

1. Add all RTL files in `src/`
2. Add `tb/tb_pipelined_processor.sv` as simulation source
3. Launch behavioral simulation
4. Run the testbench
5. Observe PASS / FAIL results in the console
6. Inspect waveform screenshots for key scenarios
7. Open the Vivado elaborated schematic if you want a visual view of the architecture

---

# Future Improvements

Possible next improvements for this processor include:

* load-use hazard stall handling
* more complete branch handling / flushing
* larger instruction set
* parameterized memory/register sizes
* cleaner ISA specification document
* constrained-random / coverage-driven verification
* UVM-based verification environment
* formal verification of control / hazard logic

---

# Notes

This is a **custom educational pipelined processor project** intended to demonstrate:

* pipeline design
* hazard handling
* ALU / memory / writeback datapaths
* instruction execution flow
* testbench-based verification in Verilog/SystemVerilog

It is **not a standard RISC-V implementation**, even though the repository name may still contain “RISC-V” from the project setup.
