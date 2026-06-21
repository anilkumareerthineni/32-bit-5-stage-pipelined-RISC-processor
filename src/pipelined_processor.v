module pipelined_processor (
    input clk,
    input rst
);

wire [31:0] instr;
wire [31:0] pctarget;
wire [31:0] pc;

wire        jump;
wire        branch_z;
wire        branch_c;
wire        carry;
wire        zero;

wire        reg_write_d;
wire        reg_write_e;
wire        reg_write_m;
wire        reg_write_w;
wire        reg_write_m_o;

wire        mem_write_d;
wire        mem_write_e;

wire        alu_src_d;
wire [2:0]  alucontrol_d;
wire [3:0]  op;

wire [1:0]  result_src_d;
wire [1:0]  result_src_e;
wire [1:0]  result_src_m;

wire [31:0] data_1;
wire [31:0] data_2;
wire [31:0] imm_ext_d;
wire [31:0] imm_ext_e;
wire [31:0] imm_ext_m;

wire [4:0]  rdw_d;
wire [4:0]  rdw_e;
wire [4:0]  rdw_m;
wire [4:0]  rdw_w;

wire [4:0]  addr1_d;
wire [4:0]  addr2_d;
wire [4:0]  addr1_e;
wire [4:0]  addr2_e;

wire [31:0] write_addr_d;
wire [31:0] write_addr_e;

wire [31:0] alu_result_e;
wire [31:0] alu_result_m;
wire [31:0] write_data_e;
wire [31:0] read_data;

wire [31:0] result;
wire [31:0] result_mf;

wire [4:0]  rdw_m_o;
wire [1:0]  forward_a;
wire [1:0]  forward_b;

fetch_stage fetch1 (
    .clk      (clk),
    .rst      (rst),
    .jump     (jump),
    .pctarget (pc),
    .instr_reg(instr)
);

decoder decode1 (
    .clk         (clk),
    .rst         (rst),
    .instr       (instr),

    .reg_write   (reg_write_w),
    .rdw         (rdw_w),
    .result      (result),

    .mem_write_o (mem_write_d),
    .reg_write_o (reg_write_d),
    .result_src_o(result_src_d),
    .alu_src_o   (alu_src_d),
    .alucontrol_o(alucontrol_d),
    .data1_o     (data_1),
    .data2_o     (data_2),
    .imm_ext_o   (imm_ext_d),
    .rdw_o       (rdw_d),
    .op          (op),
    .addr1_d     (addr1_d),
    .addr2_d     (addr2_d),
    .write_addr_d(write_addr_d),

    .pctarget    (pctarget),
    .branch_z    (branch_z),
    .branch_c    (branch_c)
);

execute ex1 (
    .clk         (clk),
    .rst         (rst),

    .reg_write   (reg_write_d),
    .result_src  (result_src_d),
    .mem_write   (mem_write_d),
    .alucontrol  (alucontrol_d),
    .alu_src     (alu_src_d),
    .data1       (data_1),
    .data2       (data_2),
    .rdw         (rdw_d),
    .imm_ext     (imm_ext_d),
    .op          (op),
    .addr1       (addr1_d),
    .addr2       (addr2_d),
    .write_addr_d(write_addr_d),

    .result_w    (result),
    .result_m    (result_mf),

    .forward_a   (forward_a),
    .forward_b   (forward_b),

    .reg_write_o (reg_write_e),
    .result_src_o(result_src_e),
    .mem_write_o (mem_write_e),
    .alu_result_o(alu_result_e),
    .write_data_o(write_data_e),
    .rdw_o       (rdw_e),
    .imm_ext_o   (imm_ext_e),
    .write_addr_e(write_addr_e),

    .addr1_o     (addr1_e),
    .addr2_o     (addr2_e),
    .carry       (carry),
    .zero        (zero)
);

memory_stage memst1 (
    .clk         (clk),
    .rst         (rst),

    .reg_write   (reg_write_e),
    .result_src  (result_src_e),
    .mem_write   (mem_write_e),
    .alu_result  (alu_result_e),
    .write_data  (write_data_e),
    .rdw         (rdw_e),
    .imm_ext     (imm_ext_e),
    .write_addr  (write_addr_e),

    .reg_write_o (reg_write_m),
    .result_src_o(result_src_m),
    .alu_result_o(alu_result_m),
    .imm_ext_o   (imm_ext_m),
    .data_out_o  (read_data),
    .rdw_o       (rdw_m),

    .result_m_o  (result_mf),
    .rdw_m_o     (rdw_m_o),
    .reg_write_m_o(reg_write_m_o)
);

writeback_stage wrb1 (
    .reg_write   (reg_write_m),
    .result_src  (result_src_m),
    .alu_result  (alu_result_m),
    .read_data   (read_data),
    .rdw         (rdw_m),
    .imm_ext     (imm_ext_m),

    .reg_write_o (reg_write_w),
    .result_o    (result),
    .rdw_o       (rdw_w)
);

data_hazard_control hazard_control1 (
    .rst         (rst),
    .reg_write_w (reg_write_w),
    .rdw_w       (rdw_w),
    .reg_write_m (reg_write_m_o),
    .rdw_m       (rdw_m_o),
    .addr1_e     (addr1_e),
    .addr2_e     (addr2_e),
    .forward_a   (forward_a),
    .forward_b   (forward_b)
);

control_hazard_sol control_hazard1 (
    .branch_z(branch_z),
    .branch_c(branch_c),
    .pctarget(pctarget),
    .zero    (zero),
    .carry   (carry),
    .pc      (pc),
    .jump    (jump)
);

endmodule
