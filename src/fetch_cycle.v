module fetch_stage (
    input              clk,
    input              rst,
    input              jump,
    input      [31:0]  pctarget,
    output reg [31:0]  instr_reg
);

wire [31:0] pc;
wire [31:0] pc_plus_1;
wire [31:0] pc_nxt;
wire [31:0] pc_ref;
wire [31:0] instr_out;
wire [31:0] pctarget_plus_1;

assign pc_plus_1       = pc + 32'd1;
assign pctarget_plus_1 = pctarget + 32'd1;

// next PC after current cycle
assign pc_nxt = jump ? pctarget_plus_1 : pc_plus_1;

// address used for instruction fetch in this cycle
assign pc_ref = jump ? pctarget : pc;

prog_c prog_counter (
    .clk   (clk),
    .rst   (rst),
    .pc_nxt(pc_nxt),
    .pc    (pc)
);

instr_mem inst_mem (
    .rst  (rst),
    .addr (pc_ref),
    .instr(instr_out)
);

always @(posedge clk or negedge rst) begin
    if (!rst)
        instr_reg <= 32'd0;
    else
        instr_reg <= instr_out;
end

endmodule