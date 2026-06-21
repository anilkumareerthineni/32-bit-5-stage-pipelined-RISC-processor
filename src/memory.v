module memory (
    input              clk,
    input              rst,
    input              write_en,
    input      [31:0]  addr,
    input      [31:0]  write_data,
    output     [31:0]  data_out
);

reg [31:0] mem [0:1023];
wire [9:0] A;

assign A        = addr[9:0];
assign data_out = (!rst) ? 32'd0 : mem[A];

always @(posedge clk) begin
    if (write_en)
        mem[A] <= write_data;
end

endmodule