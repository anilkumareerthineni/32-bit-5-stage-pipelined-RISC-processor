module writeback_stage (
    input              reg_write,
    input      [1:0]   result_src,
    input      [31:0]  alu_result,
    input      [31:0]  read_data,
    input      [4:0]   rdw,
    input      [31:0]  imm_ext,

    output             reg_write_o,
    output     [31:0]  result_o,
    output     [4:0]   rdw_o
);

assign reg_write_o = reg_write;
assign rdw_o       = rdw;

assign result_o =
       (result_src == 2'b10) ? alu_result :
       (result_src == 2'b01) ? imm_ext    :
       (result_src == 2'b11) ? read_data  :
                               32'd0;

endmodule