module reg_file (
    input              clk,
    input              rst,
    input              write_en,
    input      [4:0]   write_addr,
    input      [31:0]  write_data,
    input      [4:0]   addr1,
    input      [4:0]   addr2,
    output     [31:0]  data1,
    output     [31:0]  data2
);

reg [31:0] mem [0:31];

always @(posedge clk) begin
    if (write_en)
        mem[write_addr] <= write_data;
end

assign data1 = (!rst) ? 32'd0 : mem[addr1];
assign data2 = (!rst) ? 32'd0 : mem[addr2];

endmodule