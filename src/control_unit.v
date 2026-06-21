module control_unit (
    input      [4:0] op,
    output           reg_write,
    output           mem_write,
    output     [1:0] result_src,
    output           alusrc,
    output reg [2:0] alucontrol,
    output     [1:0] imm_src,
    output           branch_z,
    output           branch_c
);

//
// op[3:0] meaning
// 0000..0111 : ALU ops
// 1000       : immediate -> register
// 1001       : immediate -> memory
// 1010       : memory -> register
// 1011       : register -> memory
// 1100       : write previous ALU result -> register
// 1101       : branch on carry
// 1110       : branch on zero
//

assign reg_write =
       (op[3:0] == 4'b1000) ||
       (op[3:0] == 4'b1010) ||
       (op[3:0] == 4'b1100);

assign mem_write =
       (op[3:0] == 4'b1001) ||
       (op[3:0] == 4'b1011);

// writeback source select
// 01 = immediate
// 10 = ALU result
// 11 = memory read data
assign result_src =
       (op[3:0] == 4'b1000) ? 2'b01 :
       (op[3:0] == 4'b1100) ? 2'b10 :
       (op[3:0] == 4'b1010) ? 2'b11 :
                              2'b00;

assign alusrc   = op[4];
assign branch_c = (op[3:0] == 4'b1101);
assign branch_z = (op[3:0] == 4'b1110);

// immediate format selector
// 01 = imm to reg (22-bit field)
// 10 = imm to mem (17-bit field)
// 00 = ALU-immediate / default 17-bit field path in decoder
assign imm_src =
       (op[3:0] == 4'b1000) ? 2'b01 :
       (op[3:0] == 4'b1001) ? 2'b10 :
                              2'b00;

always @(*) begin
    case (op[3:0])
        4'd0: alucontrol = 3'd0;
        4'd1: alucontrol = 3'd1;
        4'd2: alucontrol = 3'd2;
        4'd3: alucontrol = 3'd3;
        4'd4: alucontrol = 3'd4;
        4'd5: alucontrol = 3'd5;
        4'd6: alucontrol = 3'd6;
        4'd7: alucontrol = 3'd7;
        default: alucontrol = 3'd0;
    endcase
end

endmodule