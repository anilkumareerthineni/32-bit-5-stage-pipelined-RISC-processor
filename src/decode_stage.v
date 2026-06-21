module decoder (
    input              clk,
    input              rst,
    input      [31:0]  instr,

    // from writeback stage
    input              reg_write,
    input      [4:0]   rdw,
    input      [31:0]  result,

    // to execute stage
    output reg         mem_write_o,
    output reg         reg_write_o,
    output reg [1:0]   result_src_o,
    output reg         alu_src_o,
    output reg [2:0]   alucontrol_o,
    output reg [31:0]  data1_o,
    output reg [31:0]  data2_o,
    output reg [31:0]  imm_ext_o,
    output reg [4:0]   rdw_o,
    output reg [3:0]   op,
    output reg [4:0]   addr1_d,
    output reg [4:0]   addr2_d,
    output reg [31:0]  write_addr_d,

    // branch / control-hazard info
    output     [31:0]  pctarget,
    output             branch_z,
    output             branch_c
);

wire        mem_write_i;
wire        reg_write_i;
wire        alu_src_i;
wire [2:0]  alucontrol_i;
wire [1:0]  result_src_i;
wire [1:0]  imm_src;

wire [31:0] data1_i;
wire [31:0] data2_i;
wire [31:0] data1_dec;
wire [31:0] data2_dec;
wire [31:0] imm_ext;
wire [31:0] mem_access_addr;

wire [4:0]  rdw_i;

assign rdw_i    = instr[26:22];
assign pctarget = {5'd0, instr[26:0]};

control_unit control_1 (
    .op        (instr[31:27]),
    .reg_write (reg_write_i),
    .mem_write (mem_write_i),
    .result_src(result_src_i),
    .alusrc    (alu_src_i),
    .alucontrol(alucontrol_i),
    .imm_src   (imm_src),
    .branch_z  (branch_z),
    .branch_c  (branch_c)
);

reg_file reg1 (
    .clk       (clk),
    .rst       (rst),
    .write_en  (reg_write),
    .write_addr(rdw),
    .write_data(result),
    .addr1     (instr[26:22]),
    .addr2     (instr[21:17]),
    .data1     (data1_i),
    .data2     (data2_i)
);

// unified memory address decode for memory-related instructions
assign mem_access_addr =
       (instr[30:27] == 4'b1001) ? {22'd0, instr[26:17]} :  // imm -> mem
       (instr[30:27] == 4'b1011) ? {22'd0, instr[9:0]}   :  // reg -> mem
       (instr[30:27] == 4'b1010) ? {22'd0, instr[9:0]}   :  // mem -> reg
                                   32'd0;

// immediate extension
assign imm_ext =
       (imm_src == 2'b01) ? {10'd0, instr[21:0]} :   // imm->reg
                           {15'd0, instr[16:0]};    // ALU-imm / imm->mem

// writeback bypass into decode to avoid same-cycle regfile RAW issue
assign data1_dec = (reg_write && (rdw == instr[26:22])) ? result : data1_i;
assign data2_dec = (reg_write && (rdw == instr[21:17])) ? result : data2_i;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        mem_write_o  <= 1'b0;
        reg_write_o  <= 1'b0;
        result_src_o <= 2'b00;
        alu_src_o    <= 1'b0;
        alucontrol_o <= 3'd0;
        data1_o      <= 32'd0;
        data2_o      <= 32'd0;
        imm_ext_o    <= 32'd0;
        rdw_o        <= 5'd0;
        op           <= 4'd0;
        addr1_d      <= 5'd0;
        addr2_d      <= 5'd0;
        write_addr_d <= 32'd0;
    end
    else begin
        mem_write_o  <= mem_write_i;
        reg_write_o  <= reg_write_i;
        result_src_o <= result_src_i;
        alu_src_o    <= alu_src_i;
        alucontrol_o <= alucontrol_i;
        data1_o      <= data1_dec;
        data2_o      <= data2_dec;
        imm_ext_o    <= imm_ext;
        rdw_o        <= rdw_i;
        op           <= instr[30:27];
        addr1_d      <= instr[26:22];
        addr2_d      <= instr[21:17];
        write_addr_d <= mem_access_addr;
    end
end

endmodule