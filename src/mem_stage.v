module memory_stage (
    input              clk,
    input              rst,

    // from execute stage
    input              reg_write,
    input      [1:0]   result_src,
    input              mem_write,
    input      [31:0]  alu_result,
    input      [31:0]  write_data,
    input      [4:0]   rdw,
    input      [31:0]  imm_ext,
    input      [31:0]  write_addr,

    // to writeback stage
    output reg         reg_write_o,
    output reg [1:0]   result_src_o,
    output reg [31:0]  alu_result_o,
    output reg [31:0]  imm_ext_o,
    output reg [31:0]  data_out_o,
    output reg [4:0]   rdw_o,

    // to hazard control
    output     [31:0]  result_m_o,
    output     [4:0]   rdw_m_o,
    output             reg_write_m_o
);

wire [31:0] data_out_i;

assign reg_write_m_o = reg_write;
assign rdw_m_o       = rdw;

// result value available for forwarding from MEM stage
assign result_m_o =
       (result_src == 2'b10) ? alu_result :
       (result_src == 2'b01) ? imm_ext    :
       (result_src == 2'b11) ? data_out_i :
                               32'd0;

memory m1 (
    .clk       (clk),
    .rst       (rst),
    .write_en  (mem_write),
    .addr      (write_addr),
    .write_data(write_data),
    .data_out  (data_out_i)
);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        reg_write_o  <= 1'b0;
        result_src_o <= 2'b00;
        alu_result_o <= 32'd0;
        imm_ext_o    <= 32'd0;
        data_out_o   <= 32'd0;
        rdw_o        <= 5'd0;
    end
    else begin
        reg_write_o  <= reg_write;
        result_src_o <= result_src;
        alu_result_o <= alu_result;
        imm_ext_o    <= imm_ext;
        data_out_o   <= data_out_i;
        rdw_o        <= rdw;
    end
end

endmodule