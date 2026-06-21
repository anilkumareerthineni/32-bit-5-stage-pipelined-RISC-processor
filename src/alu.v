module alu (
    input      [2:0]  alucontrol,
    input      [31:0] a,
    input      [31:0] b,
    output reg [31:0] result,
    output            zero,
    output            carry,
    output            overflow,
    output            sign
);

wire [31:0] sum;
wire [32:0] ad;
wire [32:0] sb;

assign sum = a + b;
assign ad  = {1'b0, a} + {1'b0, b};
assign sb  = {1'b0, a} - {1'b0, b};

always @(*) begin
    case (alucontrol)
        3'd0: result = a;
        3'd1: result = sum;
        3'd2: result = a - b;
        3'd3: result = a & b;
        3'd4: result = a | b;
        3'd5: result = ~a;
        3'd6: result = a << b;
        3'd7: result = a >> b;
        default: result = 32'd0;
    endcase
end

assign zero = (result == 32'd0);
assign sign = result[31];

assign carry =
       (alucontrol == 3'b001) ? ad[32] :
       (alucontrol == 3'b010) ? sb[32] :
                                1'b0;

assign overflow =
       ((alucontrol == 3'b001) &&
        (~(a[31] ^ b[31]) && (a[31] ^ result[31]))) ? 1'b1 :

       ((alucontrol == 3'b010) &&
        ((a[31] ^ b[31]) && (a[31] ^ result[31]))) ? 1'b1 :
                                                      1'b0;

endmodule