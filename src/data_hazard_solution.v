module data_hazard_control (
    input             rst,

    // writeback stage
    input             reg_write_w,
    input      [4:0]  rdw_w,

    // memory stage
    input             reg_write_m,
    input      [4:0]  rdw_m,

    // execute stage source register addresses
    input      [4:0]  addr1_e,
    input      [4:0]  addr2_e,

    // forwarding select to execute stage
    output reg [1:0]  forward_a,
    output reg [1:0]  forward_b
);

// forward A
always @(*) begin
    if (!rst)
        forward_a = 2'b00;
    else if (reg_write_m && (rdw_m == addr1_e))
        forward_a = 2'b10;
    else if (reg_write_w && (rdw_w == addr1_e))
        forward_a = 2'b01;
    else
        forward_a = 2'b00;
end

// forward B
always @(*) begin
    if (!rst)
        forward_b = 2'b00;
    else if (reg_write_m && (rdw_m == addr2_e))
        forward_b = 2'b10;
    else if (reg_write_w && (rdw_w == addr2_e))
        forward_b = 2'b01;
    else
        forward_b = 2'b00;
end

endmodule