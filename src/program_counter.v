module prog_c (
    input              clk,
    input              rst,
    input      [31:0]  pc_nxt,
    output reg [31:0]  pc
);

always @(posedge clk or negedge rst) begin
    if (!rst)
        pc <= 32'hFFFF_FFFF;   // so first incremented fetch lands on address 0
    else
        pc <= pc_nxt;
end

endmodule