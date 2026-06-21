module instr_mem (
    input      rst,
    input [31:0] addr,
    output [31:0] instr
);

reg [31:0] mem [0:1023];

assign instr = (!rst) ? 32'd0 : mem[addr[9:0]];

endmodule