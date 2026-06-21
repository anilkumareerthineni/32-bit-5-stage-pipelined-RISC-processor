`timescale 1ns/1ps

module tb_pipelined_processor;

  reg clk;
  reg rst;
  integer i;

  pipelined_processor dut (
    .clk(clk),
    .rst(rst)
  );

  //========================================================
  // CLOCK
  //========================================================
  initial clk = 1'b0;
  always #5 clk = ~clk;

  //========================================================
  // -------------------- TASKS ----------------------------
  //========================================================

  task reset_dut;
    begin
      rst = 1'b0;
      repeat(3) @(posedge clk);
      rst = 1'b1;
      repeat(2) @(posedge clk);
    end
  endtask

  task run_cycles(input integer n);
    begin
      repeat(n) @(posedge clk);
    end
  endtask

  task clear_imem;
    begin
      for (i = 0; i < 1024; i = i + 1)
        dut.fetch1.inst_mem.mem[i] = 32'd0;
    end
  endtask

  task clear_dmem;
    begin
      for (i = 0; i < 1024; i = i + 1)
        dut.memst1.m1.mem[i] = 32'd0;
    end
  endtask

  task clear_regfile;
    begin
      for (i = 0; i < 32; i = i + 1)
        dut.decode1.reg1.mem[i] = 32'd0;
    end
  endtask

  task init_all;
    begin
      clear_imem();
      clear_dmem();
      clear_regfile();
    end
  endtask

  task load_instr(input integer addr, input [31:0] instr);
    begin
      dut.fetch1.inst_mem.mem[addr] = instr;
    end
  endtask

  task load_data(input integer addr, input [31:0] data);
    begin
      dut.memst1.m1.mem[addr] = data;
    end
  endtask

  task check_reg(input integer regnum, input [31:0] expected);
    begin
      if (dut.decode1.reg1.mem[regnum] !== expected) begin
        $display("[FAIL] REG[%0d] = %0d (0x%08h), expected %0d (0x%08h) @ %0t",
                  regnum,
                  dut.decode1.reg1.mem[regnum],
                  dut.decode1.reg1.mem[regnum],
                  expected,
                  expected,
                  $time);
      end
      else begin
        $display("[PASS] REG[%0d] = %0d (0x%08h)",
                  regnum,
                  expected,
                  expected);
      end
    end
  endtask

  task check_mem(input integer addr, input [31:0] expected);
    begin
      if (dut.memst1.m1.mem[addr] !== expected) begin
        $display("[FAIL] MEM[%0d] = %0d (0x%08h), expected %0d (0x%08h) @ %0t",
                  addr,
                  dut.memst1.m1.mem[addr],
                  dut.memst1.m1.mem[addr],
                  expected,
                  expected,
                  $time);
      end
      else begin
        $display("[PASS] MEM[%0d] = %0d (0x%08h)",
                  addr,
                  expected,
                  expected);
      end
    end
  endtask

  task dump_regs;
    begin
      $display("--------------- REG DUMP ---------------");
      for (i = 0; i < 16; i = i + 1)
        $display("R[%0d] = %0d (0x%08h)", i, dut.decode1.reg1.mem[i], dut.decode1.reg1.mem[i]);
      $display("----------------------------------------");
    end
  endtask

  //========================================================
  // ------------ INSTRUCTION ENCODER FUNCTIONS ------------
  //========================================================
  //
  // ISA used here:
  //
  // instr[31]    = alu_src
  // instr[30:27] = opcode
  //
  // ALU ops 0000..0111:
  //   src1 addr = [26:22]
  //   src2 addr = [21:17]
  //   if alu_src=1 => imm_ext used as second operand
  //
  // 1000 : immediate to register
  //   rd = [26:22], imm = [21:0]
  //
  // 1001 : immediate to memory
  //   mem addr = [26:17]
  //   imm data = [16:0]
  //
  // 1010 : memory to register
  //   rd = [26:22]
  //   mem addr = [16:0]
  //
  // 1011 : register to memory
  //   source reg = [26:22]
  //   mem addr    = [9:0]
  //
  // 1100 : write previous ALU result to register
  //   rd = [26:22]
  //
  // 1101 : branch on carry
  // 1110 : branch on zero
  //   pctarget = [26:0]
  //
  //========================================================

  //-------------------------------
  // ALU register-register compute
  //-------------------------------
  function automatic [31:0] enc_alu_rr(
      input [3:0] aluop,
      input [4:0] src1,
      input [4:0] src2
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b0;
      instr[30:27] = aluop;
      instr[26:22] = src1;
      instr[21:17] = src2;
      enc_alu_rr   = instr;
    end
  endfunction

  //-------------------------------
  // ALU register-immediate compute
  //-------------------------------
  function automatic [31:0] enc_alu_ri(
      input [3:0] aluop,
      input [4:0] src1,
      input [16:0] imm
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b1;
      instr[30:27] = aluop;
      instr[26:22] = src1;
      instr[16:0]  = imm;
      enc_alu_ri   = instr;
    end
  endfunction

  //-------------------------------
  // Write previous ALU result to register
  //-------------------------------
  function automatic [31:0] enc_wb_reg(
      input [4:0] rd
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b0;
      instr[30:27] = 4'b1100;
      instr[26:22] = rd;
      enc_wb_reg   = instr;
    end
  endfunction

  //-------------------------------
  // Immediate to register
  //-------------------------------
  function automatic [31:0] enc_imm_to_reg(
      input [4:0] rd,
      input [21:0] imm
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b1;
      instr[30:27] = 4'b1000;
      instr[26:22] = rd;
      instr[21:0]  = imm;
      enc_imm_to_reg = instr;
    end
  endfunction

  //-------------------------------
  // Immediate to memory
  // MEM[mem_addr] = imm
  //-------------------------------
  function automatic [31:0] enc_imm_to_mem(
      input [9:0] mem_addr,
      input [16:0] imm
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b1;
      instr[30:27] = 4'b1001;
      instr[26:17] = mem_addr;
      instr[16:0]  = imm;
      enc_imm_to_mem = instr;
    end
  endfunction

  //-------------------------------
  // Memory to register
  // REG[rd] = MEM[mem_addr]
  //-------------------------------
  function automatic [31:0] enc_mem_to_reg(
    input [4:0] rd,
    input [9:0] mem_addr
);
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b1;
      instr[30:27] = 4'b1010;
      instr[26:22] = rd;
      instr[9:0]   = mem_addr;
      enc_mem_to_reg = instr;
    end
endfunction

  //-------------------------------
  // Register to memory
  // MEM[mem_addr] = REG[src]
  //-------------------------------
  function automatic [31:0] enc_reg_to_mem(
      input [4:0] src,
      input [9:0] mem_addr
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b1;
      instr[30:27] = 4'b1011;
      instr[26:22] = src;
      instr[9:0]   = mem_addr;
      enc_reg_to_mem = instr;
    end
  endfunction

  //-------------------------------
  // Branch zero
  //-------------------------------
  function automatic [31:0] enc_branch_zero(
      input [26:0] target
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b0;
      instr[30:27] = 4'b1110;
      instr[26:0]  = target;
      enc_branch_zero = instr;
    end
  endfunction

  //-------------------------------
  // Branch carry
  //-------------------------------
  function automatic [31:0] enc_branch_carry(
      input [26:0] target
  );
    reg [31:0] instr;
    begin
      instr = 32'd0;
      instr[31]    = 1'b0;
      instr[30:27] = 4'b1101;
      instr[26:0]  = target;
      enc_branch_carry = instr;
    end
  endfunction

  //========================================================
  // ALU opcodes
  //========================================================
  localparam ALU_PASSA = 4'd0;
  localparam ALU_ADD   = 4'd1;
  localparam ALU_SUB   = 4'd2;
  localparam ALU_AND   = 4'd3;
  localparam ALU_OR    = 4'd4;
  localparam ALU_NOT   = 4'd5;
  localparam ALU_SHL   = 4'd6;
  localparam ALU_SHR   = 4'd7;

  //========================================================
  // -------------------- TEST CASES -----------------------
  //========================================================

  //========================================================
  // TEST 1: reset smoke
  //========================================================
  task test_reset;
    begin
      $display("\n================ TEST 1 : RESET ================");
      init_all();
      rst = 1'b0;
      run_cycles(3);
      rst = 1'b1;
      run_cycles(2);
      $display("[INFO] Reset smoke complete.");
    end
  endtask

  //========================================================
  // TEST 2: immediate -> register
  //========================================================
  task test_imm_to_reg_basic;
    begin
      $display("\n================ TEST 2 : IMM -> REG ================");
      init_all();

      load_instr(0, enc_imm_to_reg(5'd1, 22'd5));
      load_instr(1, enc_imm_to_reg(5'd2, 22'd9));

      reset_dut();
      run_cycles(20);

      check_reg(1, 32'd5);
      check_reg(2, 32'd9);
    end
  endtask

  //========================================================
  // TEST 3: immediate -> memory
  // MEM[3] = 25
  //========================================================
  task test_imm_to_mem_basic;
    begin
      $display("\n================ TEST 3 : IMM -> MEM ================");
      init_all();

      load_instr(0, enc_imm_to_mem(10'd3, 17'd25));

      reset_dut();
      run_cycles(20);

      check_mem(3, 32'd25);
    end
  endtask

  //========================================================
  // TEST 4: memory -> register
  // preload MEM[7] = 123
  // R4 = MEM[7]
  //========================================================
  task test_mem_to_reg_basic;
    begin
      $display("\n================ TEST 4 : MEM -> REG ================");
      init_all();

      load_data(7, 32'd123);
      load_instr(0, enc_mem_to_reg(5'd4, 17'd7));

      reset_dut();
      run_cycles(25);

      check_reg(4, 32'd123);
    end
  endtask

  //========================================================
  // TEST 5: ADD + writeback
  // R3 = R1 + R2
  //========================================================
  task test_add_writeback;
  begin
    $display("\n================ TEST 5 : ADD + WB ================");
    init_all();

    load_instr(0, enc_imm_to_reg(5'd1, 22'd10));
    load_instr(1, enc_imm_to_reg(5'd2, 22'd20));
    load_instr(2, enc_alu_rr(ALU_ADD, 5'd1, 5'd2));
    load_instr(3, enc_wb_reg(5'd3));

    reset_dut();

    run_cycles(30);

    check_reg(1, 32'd10);
    check_reg(2, 32'd20);
    check_reg(3, 32'd30);
  end
endtask

  //========================================================
  // TEST 6: SUB + writeback
  // R5 = R1 - R2 = 22
  //========================================================
  task test_sub_writeback;
    begin
      $display("\n================ TEST 6 : SUB + WB ================");
      init_all();

      load_instr(0, enc_imm_to_reg(5'd1, 22'd30));
      load_instr(1, enc_imm_to_reg(5'd2, 22'd8));
      load_instr(2, enc_alu_rr(ALU_SUB, 5'd1, 5'd2));
      load_instr(3, enc_wb_reg(5'd5));

      reset_dut();
      run_cycles(30);

      check_reg(5, 32'd22);
    end
  endtask

  //========================================================
  // TEST 7: logic ops
  //========================================================
  task test_logic_ops;
    begin
      $display("\n================ TEST 7 : LOGIC OPS ================");
      init_all();

      load_instr(0, enc_imm_to_reg(5'd1, 22'd12)); // 1100
      load_instr(1, enc_imm_to_reg(5'd2, 22'd10)); // 1010

      // R6 = R1 & R2 = 8
      load_instr(2, enc_alu_rr(ALU_AND, 5'd1, 5'd2));
      load_instr(3, enc_wb_reg(5'd6));

      // R7 = R1 | R2 = 14
      load_instr(4, enc_alu_rr(ALU_OR, 5'd1, 5'd2));
      load_instr(5, enc_wb_reg(5'd7));

      // R8 = ~R1
      load_instr(6, enc_alu_rr(ALU_NOT, 5'd1, 5'd0));
      load_instr(7, enc_wb_reg(5'd8));

      // R9 = R2 << 1 = 20
      load_instr(8, enc_alu_ri(ALU_SHL, 5'd2, 17'd1));
      load_instr(9, enc_wb_reg(5'd9));

      reset_dut();
      run_cycles(60);

      check_reg(6, 32'd8);
      check_reg(7, 32'd14);
      check_reg(8, ~32'd12);
      check_reg(9, 32'd20);
    end
  endtask

  //========================================================
  // TEST 8: immediate store then load
  // MEM[12] = 77 ; R10 = MEM[12]
  //========================================================
  task test_store_then_load;
    begin
      $display("\n================ TEST 8 : STORE THEN LOAD ================");
      init_all();

      load_instr(0, enc_imm_to_mem(10'd12, 17'd77));
      load_instr(1, enc_mem_to_reg(5'd10, 17'd12));

      reset_dut();
      run_cycles(30);

      check_mem(12, 32'd77);
      check_reg(10, 32'd77);
    end
  endtask

  //========================================================
  // TEST 9: register -> memory
  //
  // R1 = 55
  // MEM[20] = R1
  // R11 = MEM[20]
  //========================================================
  task test_reg_to_mem;
    begin
      $display("\n================ TEST 9 : REG -> MEM ================");
      init_all();

      load_instr(0, enc_imm_to_reg(5'd1, 22'd55));
      load_instr(1, enc_reg_to_mem(5'd1, 10'd20));
      load_instr(2, enc_mem_to_reg(5'd11, 17'd20));

      reset_dut();
      run_cycles(35);

      check_mem(20, 32'd55);
      check_reg(11, 32'd55);
    end
  endtask

  //========================================================
  // TEST 10: store with forwarding dependency
  //
  // R1 = 5
  // R2 = 6
  // R3 = R1 + R2 = 11
  // MEM[30] = R3   (store immediately after WB/producer sequence)
  // R12 = MEM[30]
  //
  // This is the test that benefits from using A instead of data1
  // in execute for opcode 1011.
  //========================================================
  task test_store_forwarding;
    begin
      $display("\n================ TEST 10 : STORE FORWARDING ================");
      init_all();

      load_instr(0, enc_imm_to_reg(5'd1, 22'd5));
      load_instr(1, enc_imm_to_reg(5'd2, 22'd6));

      // produce R3 = 11
      load_instr(2, enc_alu_rr(ALU_ADD, 5'd1, 5'd2));
      load_instr(3, enc_wb_reg(5'd3));

      // store R3 -> MEM[30]
      load_instr(4, enc_reg_to_mem(5'd3, 10'd30));

      // load back into R12
      load_instr(5, enc_mem_to_reg(5'd12, 17'd30));

      reset_dut();
      run_cycles(50);

      check_reg(3, 32'd11);
      check_mem(30, 32'd11);
      check_reg(12, 32'd11);
    end
  endtask

  //========================================================
  // OPTIONAL: branch zero test
  //
  // Keep this separate because branch timing may need one extra
  // bubble/NOP depending on your decode/execute interaction.
  //========================================================
  task test_branch_zero;
    begin
      $display("\n================ EXTRA : BRANCH ZERO ================");
      init_all();

      load_instr(0, enc_imm_to_reg(5'd1, 22'd9));
      load_instr(1, enc_imm_to_reg(5'd2, 22'd9));
      load_instr(2, enc_alu_rr(ALU_SUB, 5'd1, 5'd2)); // zero expected
      load_instr(3, enc_branch_zero(27'd6));
      load_instr(4, enc_imm_to_reg(5'd13, 22'd111)); // should skip if branch works
      load_instr(5, enc_imm_to_reg(5'd14, 22'd55));  // filler
      load_instr(6, enc_imm_to_reg(5'd15, 22'd222));

      reset_dut();
      run_cycles(60);

      check_reg(15, 32'd222);
      $display("[INFO] If branch control works as intended, R13 should remain 0.");
      check_reg(13, 32'd0);
    end
  endtask
  
  
  task test_shr;
  begin
    $display("\n================ TEST 11 : SHR ================");
    init_all();

    // R1 = 40
    load_instr(0, enc_imm_to_reg(5'd1, 22'd40));

    // ALU: R1 >> 2 = 10
    load_instr(1, enc_alu_ri(ALU_SHR, 5'd1, 17'd2));
    load_instr(2, enc_wb_reg(5'd16));

    reset_dut();
    run_cycles(25);

    check_reg(16, 32'd10);
  end
endtask


task test_branch_zero_not_taken;
  begin
    $display("\n================ TEST 12 : BRANCH ZERO NOT TAKEN ================");
    init_all();

    // R1 = 9, R2 = 5
    load_instr(0, enc_imm_to_reg(5'd1, 22'd9));
    load_instr(1, enc_imm_to_reg(5'd2, 22'd5));

    // SUB => 9 - 5 = 4, so zero = 0
    load_instr(2, enc_alu_rr(ALU_SUB, 5'd1, 5'd2));

    // branch_zero should NOT jump
    load_instr(3, enc_branch_zero(27'd6));

    // if branch not taken, these should execute
    load_instr(4, enc_imm_to_reg(5'd17, 22'd111));
    load_instr(5, enc_imm_to_reg(5'd18, 22'd222));

    // target location
    load_instr(6, enc_imm_to_reg(5'd19, 22'd333));

    reset_dut();
    run_cycles(60);

    check_reg(17, 32'd111);
    check_reg(18, 32'd222);
    check_reg(19, 32'd333);
  end
endtask


task test_branch_carry;
  begin
    $display("\n================ TEST 13 : BRANCH CARRY ================");
    init_all();

    // preload registers directly for full-width carry case
    dut.decode1.reg1.mem[1] = 32'hFFFF_FFFF;
    dut.decode1.reg1.mem[2] = 32'h0000_0001;

    load_instr(0, enc_alu_rr(ALU_ADD, 5'd1, 5'd2));   // carry expected
    load_instr(1, enc_branch_carry(27'd4));

    // should be skipped if branch taken
    load_instr(2, enc_imm_to_reg(5'd20, 22'd111));
    load_instr(3, enc_imm_to_reg(5'd21, 22'd222));

    // branch target
    load_instr(4, enc_imm_to_reg(5'd22, 22'd333));

    reset_dut();
    run_cycles(60);

    check_reg(20, 32'd0);      // skipped
    check_reg(22, 32'd333);    // executed at target
  end
endtask


task test_back_to_back_alu_chain;
  begin
    $display("\n================ TEST 14 : BACK-TO-BACK ALU CHAIN ================");
    init_all();

    // R1 = 4, R2 = 7
    load_instr(0, enc_imm_to_reg(5'd1, 22'd4));
    load_instr(1, enc_imm_to_reg(5'd2, 22'd7));

    // R3 = R1 + R2 = 11
    load_instr(2, enc_alu_rr(ALU_ADD, 5'd1, 5'd2));
    load_instr(3, enc_wb_reg(5'd3));

    // R4 = R3 + R2 = 18
    load_instr(4, enc_alu_rr(ALU_ADD, 5'd3, 5'd2));
    load_instr(5, enc_wb_reg(5'd4));

    reset_dut();
    run_cycles(60);

    check_reg(3, 32'd11);
    check_reg(4, 32'd18);
  end
endtask


task test_same_reg_both_operands;
  begin
    $display("\n================ TEST 15 : SAME REG BOTH OPERANDS ================");
    init_all();

    // R5 = 13
    load_instr(0, enc_imm_to_reg(5'd5, 22'd13));

    // R23 = R5 + R5 = 26
    load_instr(1, enc_alu_rr(ALU_ADD, 5'd5, 5'd5));
    load_instr(2, enc_wb_reg(5'd23));

    // R24 = R5 & R5 = 13
    load_instr(3, enc_alu_rr(ALU_AND, 5'd5, 5'd5));
    load_instr(4, enc_wb_reg(5'd24));

    reset_dut();
    run_cycles(50);

    check_reg(23, 32'd26);
    check_reg(24, 32'd13);
  end
endtask



  //========================================================
  // MAIN
  //========================================================
initial begin
  #5000000;
  $display("TIMEOUT: simulation stuck at time %0t", $time);
  $finish;
end
  initial begin
    $display("====================================================");
    $display("      TESTBENCH FOR CUSTOM PIPELINED PROCESSOR      ");
    $display("====================================================");

    rst = 1'b1;

    test_reset();
    test_imm_to_reg_basic();
    test_imm_to_mem_basic();
    test_mem_to_reg_basic();
    test_add_writeback();
    test_reg_to_mem();
    
    test_sub_writeback();
    test_logic_ops();
    test_store_then_load();
    test_store_forwarding(); 

    
    test_branch_zero();
    
    
    test_shr();
    test_branch_zero_not_taken();
    test_branch_carry();
    test_back_to_back_alu_chain();
    test_same_reg_both_operands();
    

    $display("\n================ ALL TESTS FINISHED ================\n");
    dump_regs();
    #20;
    $finish;
  end

endmodule
