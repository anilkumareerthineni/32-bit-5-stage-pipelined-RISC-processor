module execute (
    input              clk,
    input              rst,

    // from decode stage
    input              reg_write,
    input      [1:0]   result_src,
    input              mem_write,
    input      [2:0]   alucontrol,
    input              alu_src,
    input      [31:0]  data1,
    input      [31:0]  data2,
    input      [4:0]   rdw,
    input      [31:0]  imm_ext,
    input      [3:0]   op,
    input      [4:0]   addr1,
    input      [4:0]   addr2,
    input      [31:0]  write_addr_d,

    // forwarded results
    input      [31:0]  result_w,
    input      [31:0]  result_m,

    // forwarding control
    input      [1:0]   forward_a,
    input      [1:0]   forward_b,

    // to memory stage
    output reg         reg_write_o,
    output reg [1:0]   result_src_o,
    output reg         mem_write_o,
    output reg [31:0]  alu_result_o,
    output reg [31:0]  write_data_o,
    output reg [4:0]   rdw_o,
    output reg [31:0]  imm_ext_o,
    output reg [31:0]  write_addr_e,

    // to hazard unit
    output     [4:0]   addr1_o,
    output     [4:0]   addr2_o,

    // flags
    output             carry,
    output             zero
);

wire [31:0] A;
wire [31:0] B;
wire [31:0] src1;
wire [31:0] src2;
wire [31:0] alu_result_i;
wire        overflow;
wire        sign;

assign A =
       (forward_a == 2'b00) ? data1    :
       (forward_a == 2'b01) ? result_w :
       (forward_a == 2'b10) ? result_m :
                              data1;

assign B =
       (forward_b == 2'b00) ? data2    :
       (forward_b == 2'b01) ? result_w :
       (forward_b == 2'b10) ? result_m :
                              data2;

assign src1 = A;
assign src2 = alu_src ? imm_ext : B;

assign addr1_o = addr1;
assign addr2_o = addr2;

alu a1 (
    .alucontrol(alucontrol),
    .a         (src1),
    .b         (src2),
    .result    (alu_result_i),
    .zero      (zero),
    .carry     (carry),
    .overflow  (overflow),
    .sign      (sign)
);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        reg_write_o  <= 1'b0;
        result_src_o <= 2'b00;
        mem_write_o  <= 1'b0;
        alu_result_o <= 32'd0;
        write_data_o <= 32'd0;
        rdw_o        <= 5'd0;
        imm_ext_o    <= 32'd0;
        write_addr_e <= 32'd0;
    end
    else begin
        reg_write_o  <= reg_write;
        result_src_o <= result_src;
        mem_write_o  <= mem_write;
        rdw_o        <= rdw;
        imm_ext_o    <= imm_ext;
        write_addr_e <= write_addr_d;

        // opcode 1100 means "write previous ALU result to register"
        // so hold the previous ALU result in this pipeline register
        alu_result_o <= (op == 4'b1100) ? alu_result_o : alu_result_i;

        // data written to memory
        // 1001 : imm -> mem
        // 1011 : reg -> mem (must use forwarded A, not raw data1)
        write_data_o <= (op == 4'b1001) ? imm_ext :
                        (op == 4'b1011) ? A       :
                                          32'd0;
    end
end

endmodule