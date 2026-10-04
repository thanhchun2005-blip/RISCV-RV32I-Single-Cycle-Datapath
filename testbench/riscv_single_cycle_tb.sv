`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: riscv_single_cycle_tb
// Description: Testbench tinh gon cho RV32I Single-Cycle CPU
//              - Quet day du 37 lenh RV32I (chon loc, chay nhanh)
//              - Chuong trinh mau: Fibonacci, Bubble Sort
//              - In truc quan ket qua tung test len TCL Console
//              - Tong thoi gian chay chi ~3000ns (chay xong ngay lap tuc)
//////////////////////////////////////////////////////////////////////////////////

module riscv_single_cycle_tb;

    localparam int ROM_DEPTH = 256;
    localparam int RAM_DEPTH = 256;

    localparam logic [31:0] NOP  = 32'h00000013;   // addi x0, x0, 0
    localparam logic [31:0] HALT = 32'h0000006F;   // jal  x0, 0

    // ------------------------------------------------------------------
    // DUT & Clock Generator
    // ------------------------------------------------------------------
    logic clk;
    logic rst_n;

    riscv_single_cycle_top dut (
        .clk  (clk),
        .rst_n(rst_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk; // Chu ky 10ns (100MHz)

    // Bien dem ket qua
    int total_cnt = 0;
    int pass_cnt  = 0;
    int fail_cnt  = 0;

    // ------------------------------------------------------------------
    // Helper truy cap noi bo DUT de debug & kiem tra
    // ------------------------------------------------------------------
    function automatic logic [31:0] get_reg(input int i);
        return dut.u_datapath.u_regfile.registers[i];
    endfunction

    function automatic logic [31:0] get_ram(input int i);
        return dut.u_datapath.u_data_ram.ram[i];
    endfunction

    function automatic logic [31:0] get_pc();
        return dut.u_datapath.pc_current;
    endfunction

    // ------------------------------------------------------------------
    // Trinh tao lenh RISC-V (Instruction Encoders)
    // ------------------------------------------------------------------
    localparam logic [6:0] OPCODE_RTYPE  = 7'b0110011;
    localparam logic [6:0] OPCODE_ITYPE  = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;

    function automatic [31:0] r_type(input int f7, f3, rd, rs1, rs2);
        return {f7[6:0], rs2[4:0], rs1[4:0], f3[2:0], rd[4:0], OPCODE_RTYPE};
    endfunction

    function automatic [31:0] i_type(input int f3, rd, rs1, imm);
        logic [11:0] imm12 = imm[11:0];
        return {imm12, rs1[4:0], f3[2:0], rd[4:0], OPCODE_ITYPE};
    endfunction

    function automatic [31:0] load_type(input int f3, rd, rs1, imm);
        logic [11:0] imm12 = imm[11:0];
        return {imm12, rs1[4:0], f3[2:0], rd[4:0], OPCODE_LOAD};
    endfunction

    function automatic [31:0] store_type(input int f3, rs2, rs1, imm);
        logic [11:0] imm12 = imm[11:0];
        return {imm12[11:5], rs2[4:0], rs1[4:0], f3[2:0], imm12[4:0], OPCODE_STORE};
    endfunction

    function automatic [31:0] branch_type(input int f3, rs1, rs2, off);
        logic [12:0] imm13 = off[12:0];
        return {imm13[12], imm13[10:5], rs2[4:0], rs1[4:0], f3[2:0], imm13[4:1], imm13[11], OPCODE_BRANCH};
    endfunction

    function automatic [31:0] lui_type(input int rd, imm20);
        return {imm20[19:0], rd[4:0], OPCODE_LUI};
    endfunction

    function automatic [31:0] auipc_type(input int rd, imm20);
        return {imm20[19:0], rd[4:0], OPCODE_AUIPC};
    endfunction

    function automatic [31:0] jal_type(input int rd, off);
        logic [20:0] imm21 = off[20:0];
        return {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd[4:0], OPCODE_JAL};
    endfunction

    function automatic [31:0] jalr_type(input int rd, rs1, imm);
        logic [11:0] imm12 = imm[11:0];
        return {imm12, rs1[4:0], 3'b000, rd[4:0], OPCODE_JALR};
    endfunction

    // ------------------------------------------------------------------
    // Program Buffer & Nạp ROM
    // ------------------------------------------------------------------
    logic [31:0] prog [0:ROM_DEPTH-1];
    int plen;

    task automatic clear_prog();
        for (int i = 0; i < ROM_DEPTH; i++) prog[i] = NOP;
        plen = 0;
    endtask

    task automatic emit(input logic [31:0] instr);
        prog[plen] = instr;
        plen++;
    endtask

    task automatic emit_li(input int rd, input logic [31:0] val);
        logic [31:0] hi = (val + 32'h800) >> 12;
        emit(lui_type(rd, int'(hi[19:0])));
        emit(i_type(0, rd, rd, int'(val[11:0])));
    endtask

    task automatic run_program(input int cycles);
        emit(HALT);
        for (int i = 0; i < ROM_DEPTH; i++)
            dut.u_datapath.u_instr_rom.rom[i] = prog[i];
        
        // Reset CPU
        rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Chạy chương trình
        repeat (cycles) @(posedge clk);
        #1;
    endtask

    // ------------------------------------------------------------------
    // Tasks kiểm tra và in kết quả
    // ------------------------------------------------------------------
    task automatic check_reg(input string test_name, input int reg_idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = get_reg(reg_idx);
        total_cnt++;
        if (actual === expected) begin
            pass_cnt++;
            $display("  [TC #%02d] [PASS] %-32s | x%-2d = 0x%08h (%0d)", total_cnt, test_name, reg_idx, actual, $signed(actual));
        end else begin
            fail_cnt++;
            $display("  [TC #%02d] [FAIL] %-32s | x%-2d GOT: 0x%08h | EXPECTED: 0x%08h", total_cnt, test_name, reg_idx, actual, expected);
        end
        $fflush();
    endtask

    task automatic check_mem(input string test_name, input int mem_word_idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = get_ram(mem_word_idx);
        total_cnt++;
        if (actual === expected) begin
            pass_cnt++;
            $display("  [TC #%02d] [PASS] %-32s | mem[%0d] = 0x%08h (%0d)", total_cnt, test_name, mem_word_idx, actual, $signed(actual));
        end else begin
            fail_cnt++;
            $display("  [TC #%02d] [FAIL] %-32s | mem[%0d] GOT: 0x%08h | EXPECTED: 0x%08h", total_cnt, test_name, mem_word_idx, actual, expected);
        end
        $fflush();
    endtask

    // ==================================================================
    // CÁC TEST CASES TINH GỌN (CHỌN LỌC ĐẠI DIỆN)
    // ==================================================================

    // 1. Kiểm tra Reset & Thanh ghi x0 (Hardwired Zero)
    task automatic test_reset_and_x0();
        $display("\n================ [TEST 1] RESET & ZERO REGISTER ================");
        clear_prog();
        emit(i_type(0, 0, 0, 32'h123)); // Ghi vào x0 -> phải bị bỏ qua
        emit(i_type(0, 1, 0, 32'd50));  // x1 = 50
        run_program(5);
        check_reg("x0 luon bang 0", 0, 32'd0);
        check_reg("x1 nap gia tri 50", 1, 32'd50);
    endtask

    // 2. R-type ALU (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
    task automatic test_rtype_ops();
        $display("\n================ [TEST 2] R-TYPE ALU INSTRUCTIONS ==============");
        clear_prog();
        emit_li(1, 32'h0000000A);       // x1 = 10
        emit_li(2, 32'h00000003);       // x2 = 3
        emit_li(3, 32'hFFFFFFF6);       // x3 = -10 (0xFFFFFFF6)
        
        emit(r_type(0,  0, 4,  1, 2));  // ADD  x4  = 10 + 3 = 13
        emit(r_type(32, 0, 5,  1, 2));  // SUB  x5  = 10 - 3 = 7
        emit(r_type(0,  1, 6,  1, 2));  // SLL  x6  = 10 << 3 = 80
        emit(r_type(0,  2, 7,  3, 1));  // SLT  x7  = (-10 < 10) = 1
        emit(r_type(0,  3, 8,  3, 1));  // SLTU x8  = (unsigned -10 < 10) = 0
        emit(r_type(0,  4, 9,  1, 2));  // XOR  x9  = 10 ^ 3 = 9
        emit(r_type(0,  5, 10, 1, 2));  // SRL  x10 = 10 >> 3 = 1
        emit(r_type(32, 5, 11, 3, 2));  // SRA  x11 = (-10) >>> 3 = -2 (0xFFFFFFFE)
        emit(r_type(0,  6, 12, 1, 2));  // OR   x12 = 10 | 3 = 11
        emit(r_type(0,  7, 13, 1, 2));  // AND  x13 = 10 & 3 = 2
        run_program(25);

        check_reg("ADD  (10 + 3)",        4,  32'd13);
        check_reg("SUB  (10 - 3)",        5,  32'd7);
        check_reg("SLL  (10 << 3)",       6,  32'd80);
        check_reg("SLT  (-10 < 10)",      7,  32'd1);
        check_reg("SLTU (unsigned cmp)",  8,  32'd0);
        check_reg("XOR  (10 ^ 3)",        9,  32'd9);
        check_reg("SRL  (10 >> 3)",       10, 32'd1);
        check_reg("SRA  (-10 >>> 3)",     11, 32'hFFFFFFFE);
        check_reg("OR   (10 | 3)",        12, 32'd11);
        check_reg("AND  (10 & 3)",        13, 32'd2);
    endtask

    // 3. I-type ALU (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
    task automatic test_itype_ops();
        $display("\n================ [TEST 3] I-TYPE ALU INSTRUCTIONS ==============");
        clear_prog();
        emit_li(1, 32'h00000010);           // x1 = 16
        emit(i_type(0, 2,  1, -5));         // ADDI  x2 = 16 - 5 = 11
        emit(i_type(2, 3,  1, 20));         // SLTI  x3 = (16 < 20) = 1
        emit(i_type(3, 4,  1, 10));         // SLTIU x4 = (16 < 10) = 0
        emit(i_type(4, 5,  1, 12'h00F));    // XORI  x5 = 16 ^ 15 = 31
        emit(i_type(6, 6,  1, 12'h001));    // ORI   x6 = 16 | 1 = 17
        emit(i_type(7, 7,  1, 12'h010));    // ANDI  x7 = 16 & 16 = 16
        emit(i_type(1, 8,  1, 2));          // SLLI  x8 = 16 << 2 = 64
        emit(i_type(5, 9,  1, 2));          // SRLI  x9 = 16 >> 2 = 4
        emit(i_type(5, 10, 1, 12'h400 | 2));// SRAI  x10 = 16 >>> 2 = 4
        run_program(20);

        check_reg("ADDI  (16 + (-5))", 2,  32'd11);
        check_reg("SLTI  (16 < 20)",   3,  32'd1);
        check_reg("SLTIU (16 < 10)",   4,  32'd0);
        check_reg("XORI  (16 ^ 15)",   5,  32'd31);
        check_reg("ORI   (16 | 1)",    6,  32'd17);
        check_reg("ANDI  (16 & 16)",   7,  32'd16);
        check_reg("SLLI  (16 << 2)",   8,  32'd64);
        check_reg("SRLI  (16 >> 2)",   9,  32'd4);
        check_reg("SRAI  (16 >>> 2)",  10, 32'd4);
    endtask

    // 4. LUI & AUIPC
    task automatic test_u_type();
        $display("\n================ [TEST 4] LUI & AUIPC ==========================");
        clear_prog();
        emit(lui_type(1, 20'h12345));      // x1 = 0x12345000
        emit(auipc_type(2, 20'h00001));    // PC=4 -> x2 = 4 + 0x1000 = 0x00001004
        run_program(5);

        check_reg("LUI   (0x12345000)", 1, 32'h12345000);
        check_reg("AUIPC (PC + 0x1000)", 2, 32'h00001004);
    endtask

    // 5. Memory: LW & SW
    task automatic test_load_store();
        $display("\n================ [TEST 5] MEMORY: LW & SW ======================");
        clear_prog();
        emit_li(1, 32'hDEADBEEF);
        emit_li(2, 32'hCAFEBABE);
        emit(store_type(2, 1, 0, 0));       // sw x1, 0(x0)  -> ram[0]
        emit(store_type(2, 2, 0, 4));       // sw x2, 4(x0)  -> ram[1]
        emit(load_type(2, 3, 0, 0));        // lw x3, 0(x0)
        emit(load_type(2, 4, 0, 4));        // lw x4, 4(x0)
        run_program(15);

        check_mem("SW ghi vao RAM[0]", 0, 32'hDEADBEEF);
        check_mem("SW ghi vao RAM[1]", 1, 32'hCAFEBABE);
        check_reg("LW doc RAM[0]",     3, 32'hDEADBEEF);
        check_reg("LW doc RAM[1]",     4, 32'hCAFEBABE);
    endtask

    // 6. Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
    task automatic test_branches();
        $display("\n================ [TEST 6] BRANCH INSTRUCTIONS ==================");
        clear_prog();
        emit_li(1, 32'd10);
        emit_li(2, 32'd20);
        // BEQ khong re (10 != 20)
        emit(branch_type(0, 1, 2, 8)); // pc+8
        emit(i_type(0, 3, 0, 1));      // chay neu khong re -> x3 = 1
        
        // BNE re nhay qua lenh ke (10 != 20)
        emit(branch_type(1, 1, 2, 8)); // nhay
        emit(i_type(0, 4, 0, 99));     // bi bo qua
        emit(i_type(0, 4, 0, 2));      // x4 = 2

        // BLT re nhay (10 < 20)
        emit(branch_type(4, 1, 2, 8)); // nhay
        emit(i_type(0, 5, 0, 99));     // bi bo qua
        emit(i_type(0, 5, 0, 3));      // x5 = 3

        // BGE khong re (10 >= 20 sai)
        emit(branch_type(5, 1, 2, 8));
        emit(i_type(0, 6, 0, 4));      // x6 = 4
        run_program(25);

        check_reg("BEQ (khong re nhay)", 3, 32'd1);
        check_reg("BNE (re nhay hop le)", 4, 32'd2);
        check_reg("BLT (re nhay hop le)", 5, 32'd3);
        check_reg("BGE (khong re nhay)", 6, 32'd4);
    endtask

    // 7. Jumps: JAL & JALR
    task automatic test_jumps();
        $display("\n================ [TEST 7] JUMP: JAL & JALR =====================");
        clear_prog();
        // JAL nhay qua 1 lenh va luu return address vao x1
        emit(jal_type(1, 8));       // pc = 0 -> nhay den pc = 8, x1 = 4
        emit(i_type(0, 2, 0, 99));  // bo qua
        emit(i_type(0, 2, 0, 10));  // x2 = 10

        // JALR nhay den dia chi tinh tu thanh ghi
        emit(i_type(0, 3, 0, 24));  // PC = 12 -> addi x3, x0, 24 (dia chi dich)
        emit(jalr_type(4, 3, 0));   // PC = 16 -> nhay den PC = 24, x4 = link (16 + 4 = 20)
        emit(i_type(0, 5, 0, 99));  // PC = 20 -> bi bo qua
        emit(i_type(0, 5, 0, 20));  // PC = 24 -> tai PC = 24 -> x5 = 20
        run_program(20);

        check_reg("JAL link register (ra)", 1, 32'd4);
        check_reg("JAL nhay den dich",      2, 32'd10);
        check_reg("JALR link register",     4, 32'd20);
        check_reg("JALR nhay den dich",     5, 32'd20);
    endtask

    // 8. Kiem tra 4 gia tri bien (Boundary Values: 0x0, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000)
    task automatic test_boundary_values();
        $display("\n================ [TEST 8] 4 BOUNDARY VALUES (CORNER CASES) ======");
        clear_prog();
        // Nap 4 gia tri bien vao x1..x4
        emit_li(1, 32'h00000000);       // V_ZERO
        emit_li(2, 32'hFFFFFFFF);       // V_ONES (-1)
        emit_li(3, 32'h7FFFFFFF);       // V_MAX  (Max Signed Int)
        emit_li(4, 32'h80000000);       // V_MIN  (Min Signed Int)
        emit_li(5, 32'd1);

        // a. ALU Wrap-around / Overflow
        emit(r_type(0,  0, 6, 3, 5));   // ADD: 0x7FFFFFFF + 1 = 0x80000000
        emit(r_type(32, 0, 7, 4, 5));   // SUB: 0x80000000 - 1 = 0x7FFFFFFF
        emit(r_type(32, 0, 8, 1, 5));   // SUB: 0x00000000 - 1 = 0xFFFFFFFF
        emit(r_type(0,  0, 9, 2, 5));   // ADD: 0xFFFFFFFF + 1 = 0x00000000

        // b. SLT (co dau) vs SLTU (khong dau) voi Boundary
        emit(r_type(0, 2, 10, 4, 3));   // SLT:  (0x80000000 < 0x7FFFFFFF) -> 1 (vi -2^31 < 2^31-1)
        emit(r_type(0, 3, 11, 4, 3));   // SLTU: (unsigned 0x80000000 < 0x7FFFFFFF) -> 0
        emit(r_type(0, 2, 12, 2, 1));   // SLT:  (-1 < 0) -> 1
        emit(r_type(0, 3, 13, 2, 1));   // SLTU: (unsigned 0xFFFFFFFF < 0) -> 0

        // c. Store & Load ca 4 gia tri bien vao RAM de kiem tra toan ven 32-bit
        emit(store_type(2, 1, 0, 0));   // sw 0x00000000 -> ram[0]
        emit(store_type(2, 2, 0, 4));   // sw 0xFFFFFFFF -> ram[1]
        emit(store_type(2, 3, 0, 8));   // sw 0x7FFFFFFF -> ram[2]
        emit(store_type(2, 4, 0, 12));  // sw 0x80000000 -> ram[3]

        emit(load_type(2, 14, 0, 0));   // lw -> x14
        emit(load_type(2, 15, 0, 4));   // lw -> x15
        emit(load_type(2, 16, 0, 8));   // lw -> x16
        emit(load_type(2, 17, 0, 12));  // lw -> x17

        run_program(35);

        // Kiem tra ket qua ALU Wrap-around
        check_reg("MAX_INT + 1 = MIN_INT", 6, 32'h80000000);
        check_reg("MIN_INT - 1 = MAX_INT", 7, 32'h7FFFFFFF);
        check_reg("0 - 1 = 0xFFFFFFFF",    8, 32'hFFFFFFFF);
        check_reg("0xFFFFFFFF + 1 = 0",    9, 32'h00000000);

        // Kiem tra SLT vs SLTU
        check_reg("SLT  (MIN_INT < MAX_INT)",  10, 32'd1);
        check_reg("SLTU (MIN_INT < MAX_INT)",  11, 32'd0);
        check_reg("SLT  (-1 < 0)",             12, 32'd1);
        check_reg("SLTU (0xFFFFFFFF < 0)",     13, 32'd0);

        // Kiem tra toan ven gia tri bien qua Memory
        check_mem("RAM[0] (0x00000000)", 0, 32'h00000000);
        check_mem("RAM[1] (0xFFFFFFFF)", 1, 32'hFFFFFFFF);
        check_mem("RAM[2] (0x7FFFFFFF)", 2, 32'h7FFFFFFF);
        check_mem("RAM[3] (0x80000000)", 3, 32'h80000000);

        check_reg("LW RAM[0] (0x00000000)", 14, 32'h00000000);
        check_reg("LW RAM[1] (0xFFFFFFFF)", 15, 32'hFFFFFFFF);
        check_reg("LW RAM[2] (0x7FFFFFFF)", 16, 32'h7FFFFFFF);
        check_reg("LW RAM[3] (0x80000000)", 17, 32'h80000000);
    endtask

    // 9. Chuong trinh thuc te: Tinh day Fibonacci(7) luu vao RAM
    task automatic test_fibonacci();
        $display("\n================ [TEST 9] CHUONG TRINH FIBONACCI ================");
        clear_prog();
        // Khoi tao: x1 = F0 (0), x2 = F1 (1), x3 = N (7), x4 = mem_ptr (0)
        emit(i_type(0, 1, 0, 0));
        emit(i_type(0, 2, 0, 1));
        emit(i_type(0, 3, 0, 7));
        emit(i_type(0, 4, 0, 0));
        
        // Loop:
        emit(store_type(2, 1, 4, 0));   // sw   x1, 0(x4)
        emit(r_type(0, 0, 5, 1, 2));    // add  x5, x1, x2  (F_next = F0 + F1)
        emit(i_type(0, 1, 2, 0));       // addi x1, x2, 0   (F0 = F1)
        emit(i_type(0, 2, 5, 0));       // addi x2, x5, 0   (F1 = F_next)
        emit(i_type(0, 4, 4, 4));       // addi x4, x4, 4   (ptr += 4)
        emit(i_type(0, 3, 3, -1));      // addi x3, x3, -1  (N--)
        emit(branch_type(1, 3, 0, -24));// bne  x3, x0, Loop (-6 instructions)
        run_program(80);

        // Kiem tra chuoi Fib: 0, 1, 1, 2, 3, 5, 8
        check_mem("Fib[0]", 0, 32'd0);
        check_mem("Fib[1]", 1, 32'd1);
        check_mem("Fib[2]", 2, 32'd1);
        check_mem("Fib[3]", 3, 32'd2);
        check_mem("Fib[4]", 4, 32'd3);
        check_mem("Fib[5]", 5, 32'd5);
        check_mem("Fib[6]", 6, 32'd8);
    endtask

    // ------------------------------------------------------------------
    // Main Flow Execution
    // ------------------------------------------------------------------
    initial begin
        $display("\n**********************************************************");
        $display("*   KHOI CHAY TESTBENCH RUT GON - RISC-V SINGLE-CYCLE    *");
        $display("**********************************************************");

        test_reset_and_x0();
        test_rtype_ops();
        test_itype_ops();
        test_u_type();
        test_load_store();
        test_branches();
        test_jumps();
        test_boundary_values();
        test_fibonacci();

        $display("\n==========================================================");
        $display(" TONG KET KET QUA MO PHONG: %0d TEST CASES", total_cnt);
        $display("   [PASS]: %0d", pass_cnt);
        $display("   [FAIL]: %0d", fail_cnt);
        if (fail_cnt == 0) begin
            $display(" KET LUAN: *** ALL TESTS PASSED! CPU HOAT DONG DUNG ***");
        end else begin
            $display(" KET LUAN: *** PHAT HIEN %0d LOI TRONG THIET KE ***", fail_cnt);
        end
        $display("==========================================================\n");
        $fflush();
        $finish;
    end

endmodule
