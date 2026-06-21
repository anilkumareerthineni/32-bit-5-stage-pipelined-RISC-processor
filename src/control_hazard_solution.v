module control_hazard_sol (
    // from decode stage
    input      branch_z,
    input      branch_c,
    input [31:0] pctarget,

    // from execute stage
    input      zero,
    input      carry,

    // to fetch stage
    output [31:0] pc,
    output        jump
);

wire jump_z;
wire jump_c;

assign jump_z = branch_z & zero;
assign jump_c = branch_c & carry;
assign jump   = jump_z | jump_c;

assign pc = pctarget;

endmodule