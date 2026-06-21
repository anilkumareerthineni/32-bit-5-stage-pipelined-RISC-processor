# Custom 5-Stage Pipelined Processor in Verilog

## Overview

This project implements a **custom 32-bit 5-stage pipelined processor** in **Verilog HDL**. The processor supports a compact custom instruction set for arithmetic, logic, memory access, and branching. The goal of the project is to build and verify a simple pipelined processor from scratch while also handling practical pipeline issues such as **data hazards** and **control hazards**.

The design follows a classic **5-stage pipeline**:

1. **Fetch**
2. **Decode**
3. **Execute**
4. **Memory**
5. **Writeback**

The processor supports the following categories of operations:

* ALU operations
* Immediate-to-register operations
* Immediate-to-memory operations
* Memory-to-register load operations
* Register-to-memory store operations
* Conditional branch on **zero**
* Conditional branch on **carry**

In addition to the datapath, the design also includes:

* **data forwarding / hazard handling**
* **basic control hazard handling for branches**
* a **self-checking SystemVerilog testbench**
* **waveform-based verification** for datapath, forwarding, memory, and branch behavior

---

# Features

## 1. 5-stage pipelined datapath

The processor is organized as a five-stage pipeline:

### Fetch Stage

* Holds and updates the **program counter (PC)**
* Fetches instructions from instruction memory
* Supports both sequential instruction fetch and branch redirection

### Decode Stage

* Decodes the instruction opcode
* Generates control signals for later stages
* Reads operands from the register file
* Generates immediate values
* Passes branch target information

### Execute Stage

* Performs ALU operations
* Selects the correct ALU operands
* Uses forwarded values when needed
* Generates the ALU result
* Prepares data and addresses for memory operations

### Memory Stage

* Handles memory read and memory write operations
* Writes data into memory for store instructions
* Reads data from memory for load instructions

### Writeback Stage

* Selects the final value to be written into the register file
* Supports:

  * immediate writeback
  * ALU result writeback
  * memory data writeback

---

## 2. Hazard handling

### Data hazard forwarding

The design includes a forwarding unit to resolve **read-after-write dependencies**. Instead of waiting for a value to be written back into the register file, dependent instructions can receive the value directly from a later pipeline stage.

Forwarding is used from:

* **Memory stage**
* **Writeback stage**

This is especially important for:

* back-to-back ALU instructions
* store instructions that need a just-produced register value

### Control hazard handling

Branch instructions are supported using a simple control hazard block. The block checks ALU status flags and redirects the program counter when the branch condition is satisfied.

Supported branch conditions:

* **branch on zero**
* **branch on carry**

---

# Processor Architecture

## Top-level modules

The design is split into the following RTL modules:

* `pipelined_processor.v` – top-level integration of the processor
* `fetch_stage.v` – fetch stage logic and PC path
* `prog_c.v` – program counter
* `instr_mem.v` – instruction memory
* `decoder.v` – decode stage, register file access, immediate generation
* `control_unit.v` – opcode decode and control signal generation
* `reg_file.v` – 32-register register file
* `execute.v` – execute stage and operand forwarding integration
* `alu.v` – arithmetic and logic unit
* `memory.v` – data memory
* `memory_stage.v` – memory pipeline stage
* `writeback_stage.v` – final writeback result selection
* `data_hazard_control.v` – forwarding control logic
* `control_hazard_sol.v` – branch decision and PC redirection logic

---

# Architecture Description

The processor is built as a pipelined datapath with separate blocks for instruction fetch, decode, execution, memory access, and writeback. Each stage passes its outputs to the next stage through registered stage outputs.

At the top level, the processor contains the following major functional blocks:

* **Fetch stage** for PC update and instruction fetch
* **Decode stage** for register access, immediate generation, and control signal generation
* **Execute stage** for ALU operations and forwarded operand selection
* **Memory stage** for data memory access
* **Writeback stage** for selecting the final register writeback value
* **Data hazard control** for forwarding
* **Control hazard logic** for branch handling

This modular organization makes it easier to debug the processor stage by stage and verify that instruction flow through the pipeline is correct.

---

# Pipeline Stages

## 1) Fetch Stage

The fetch stage is responsible for program counter control and instruction fetch.

### Main responsibilities

* update the PC every cycle
* fetch the current instruction from instruction memory
* redirect instruction fetch when a branch is taken

### Main signals

* `pc`
* `pc_nxt`
* `pctarget`
* `instr_reg`

The PC normally increments by 1 for the next instruction. If a branch is taken, the PC is redirected to the branch target.

---

## 2) Decode Stage

The decode stage interprets the instruction and prepares the inputs needed by the execute stage.

### Main responsibilities

* decode the instruction opcode
* generate control signals
* read source operands from the register file
* generate immediate values
* pass destination register information
* generate branch target information

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

The decode stage also performs register-file-based operand fetch and passes source register addresses to the forwarding logic.

---

## 3) Execute Stage

The execute stage performs ALU operations and prepares store data for memory operations.

### Main responsibilities

* choose ALU operands
* apply forwarding when required
* perform arithmetic / logic operations
* generate status flags such as zero and carry
* prepare memory write data
* pass ALU results to the next stage

### Main outputs

* `alu_result_o`
* `write_data_o`
* `write_addr_e`
* `carry`
* `zero`

The execute stage is the main computational stage of the processor.

---

## 4) Memory Stage

The memory stage interfaces with the data memory.

### Main responsibilities

* write data into memory for store instructions
* read data from memory for load instructions
* pass memory output and pipeline values to writeback

The memory stage also produces the forwarded result used by the data hazard control logic when the next instruction depends on a value still in the memory stage.

---

## 5) Writeback Stage

The writeback stage selects the final value that should be written into the register file.

### Writeback sources

* immediate value
* ALU result
* memory read data

This stage produces:

* the value to be written into the register file
* the destination register number
* the register write enable signal

---

# Custom Instruction Format

This processor uses a **custom instruction encoding**, not standard RISC-V encoding.

## Common instruction fields

* **bit [31]**: used as part of the instruction type / immediate ALU behavior depending on opcode usage
* **bits [30:27]**: primary opcode field
* remaining fields are interpreted differently depending on the instruction class

Because the encoding is custom, field usage depends on the operation being performed. For example, memory operations and ALU operations do not necessarily interpret the lower bits in the same way.

---

# Supported Operations

## ALU Operations

The ALU supports the following operations:

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

Loads an immediate value into a destination register.

## 2. Immediate to Memory

Stores an immediate value directly into memory.

## 3. Memory to Register

Loads a value from memory and writes it into a register.

## 4. Register to Memory

Stores a register value into memory.

## 5. ALU Operation

Performs an ALU operation on source operands.

## 6. ALU Result Writeback

Writes the previously generated ALU result into a destination register.

## 7. Branch on Zero

Branches to a target address if the zero flag is asserted.

## 8. Branch on Carry

Branches to a target address if the carry flag is asserted.

---

# Register File

The processor contains a **32-register register file**, with each register being **32 bits wide**.

### Register file properties

* two read ports
* one write port
* synchronous write
* combinational read

The decode stage reads operands from the register file, and the writeback stage writes the final result back into the register file.

---

# Memory

The processor uses a simple memory array for data storage.

### Memory characteristics

* word-oriented access
* used for both load and store verification scenarios
* memory address is derived from the instruction format and the decode/execute pipeline logic

Separate instruction memory and data memory behavior are modeled in the RTL.

---

# Hazard Handling Details

## Data hazard control

The `data_hazard_control` block compares source register addresses in the execute stage with destination registers from later pipeline stages. If a match is found and the later stage will write a result, forwarding is enabled.

### Forwarding sources

* **Memory stage result**
* **Writeback stage result**

### Forwarding targets

* ALU source operand A
* ALU source operand B
* store data path when a store depends on a just-computed register value

This avoids unnecessary waiting in many common dependency cases.

---

## Control hazard control

The `control_hazard_sol` block handles branch decisions.

It receives:

* branch control signals from the decode stage
* zero and carry flags from the execute stage

Based on these, it decides whether the branch should be taken and provides the PC redirection target.

---

# Verification

## Testbench

The processor is verified using a **self-checking SystemVerilog testbench**:

* `tb_pipelined_processor.sv`

The testbench:

* initializes instruction memory and data memory
* loads custom-encoded instructions into instruction memory
* runs the processor for a fixed number of cycles
* checks register and memory contents automatically
* reports PASS / FAIL results in the simulator console

This allows verification to be automated rather than relying only on manual waveform inspection.

---

# Verified Test Scenarios

The following test scenarios were executed successfully.

## 1. Reset

Checks reset behavior of the processor and confirms that the pipeline starts from a known state.

## 2. Immediate to Register

Verifies that immediate values can be correctly loaded into registers.

## 3. Immediate to Memory

Verifies that an immediate value can be stored directly into memory.

## 4. Memory to Register

Verifies the load path from memory to the register file.

## 5. ADD + Writeback

Verifies:

* immediate value loading into source registers
* ALU addition
* propagation of the ALU result through the pipeline
* correct writeback of the ALU result into the destination register

## 6. SUB + Writeback

Verifies subtraction and ALU result writeback.

## 7. Logic Operations

Verifies:

* AND
* OR
* NOT
* Shift Left

## 8. Store then Load

Verifies that a value can be stored into memory and later loaded back into a register.

## 9. Register to Memory

Verifies that register data can be stored into memory.

## 10. Store Forwarding

Verifies that a store instruction can use a just-generated register value through forwarding instead of waiting for register writeback.

## 11. Shift Right

Verifies the right-shift ALU operation.

## 12. Branch Zero Not Taken

Verifies that the processor behaves correctly when a zero-based branch condition is false.

## 13. Branch Carry

Verifies branch behavior based on the carry flag.

## 14. Back-to-Back ALU Chain

Verifies forwarding across dependent ALU instructions executed in consecutive cycles.

## 15. Same Register as Both Operands

Verifies correct operation when both source operands refer to the same register.

---

# Waveform Verification

Waveforms were used to observe the dynamic behavior of the processor during simulation. This was useful for confirming not just the final register/memory values, but also the internal pipeline behavior cycle by cycle.

Waveform inspection was used to study:

* PC progression
* instruction flow through the pipeline
* operand movement from decode to execute
* ALU result generation
* writeback behavior
* memory store and memory load paths
* forwarding during dependent instructions
* branch redirection behavior

## Important waveform scenarios

### ADD + Writeback

Used to verify the basic datapath:

* immediate load into registers
* ALU add execution
* ALU result propagation
* ALU result writeback into a register

### Store then Load

Used to verify the memory datapath:

* correct memory write address generation
* memory write operation
* later memory read
* register writeback of loaded data

### Store Forwarding

Used to verify that store instructions can use forwarded values when the required register data is not yet available in the register file.

### Branch Zero

Used to verify:

* zero flag generation
* branch decision logic
* PC redirection when the branch is taken

### Back-to-Back ALU Chain

Used to verify forwarding across dependent ALU instructions without waiting for full writeback.

---

# Simulation Output

The self-checking testbench prints PASS / FAIL results for each test scenario. Correctness is therefore checked in two ways:

1. **Architectural result checking** using automatic register/memory comparisons in the testbench
2. **Waveform inspection** to observe the actual pipeline behavior during execution

The final simulation confirmed successful execution of:

* arithmetic and logic operations
* memory store and load behavior
* ALU writeback behavior
* forwarding behavior
* branch behavior
* dependent instruction handling

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
5. Observe PASS / FAIL results in the simulator console
6. Use waveforms if you want to inspect the internal pipeline behavior

---

# Future Improvements

Possible next improvements for this processor include:

* load-use hazard stall handling
* more complete branch flushing / control hazard handling
* additional instruction types
* cleaner ISA specification document
* parameterized memory/register sizes
* constrained-random verification
* coverage-driven verification
* UVM-based verification environment
* formal verification of hazard and control logic

---

# Notes

This is a **custom educational pipelined processor project** intended to demonstrate:

* pipeline design
* ALU / memory / writeback datapaths
* hazard handling
* instruction execution flow
* self-checking testbench verification
* waveform-based debugging of pipeline behavior

This is **not a standard RISC-V implementation**, even though the repository name may still contain “RISC-V” from the original project setup.
