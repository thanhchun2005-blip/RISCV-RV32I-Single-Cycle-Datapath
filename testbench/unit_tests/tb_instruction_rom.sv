`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 01:45:57 PM
// Design Name: 
// Module Name: instr_rom_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module instr_rom_tb;

    // ============================================================
    // 1. Tín hi?u k?t n?i v?i DUT
    // ============================================================

    logic [31:0] addr;
    logic [31:0] instr;

    // ============================================================
    // 2. Kh?i t?o DUT - Instruction ROM
    // ============================================================

    instr_rom #(
        .DEPTH(256)
    ) dut (
        .addr  (addr),
        .instr (instr)
    );

    // ============================================================
    // 3. Task ki?m tra instruction
    // ============================================================

    task check_instruction(
        input logic [31:0] test_addr,
        input logic [31:0] expected,
        input string       test_name
    );
        begin
            addr = test_addr;
            #1;

            if (instr === expected) begin
                $display("[PASS] %s", test_name);
                $display("       PC       = 0x%08h", addr);
                $display("       Instruction = 0x%08h", instr);
            end
            else begin
                $error("[FAIL] %s", test_name);
                $display("       PC       = 0x%08h", addr);
                $display("       Expected = 0x%08h", expected);
                $display("       Actual   = 0x%08h", instr);
            end
        end
    endtask

    // ============================================================
    // 4. Test
    // ============================================================

    initial begin

        $display("========================================");
        $display("       INSTRUCTION ROM TESTBENCH");
        $display("========================================");

        // --------------------------------------------------------
        // N?p ch??ng trình m?u vào ROM
        //
        // ROM[0] = ADDI x1, x0, 10
        // ROM[1] = ADDI x2, x0, 20
        // ROM[2] = ADD  x3, x1, x2
        // ROM[3] = SW   x3, 0(x0)
        //
        // L?u ý:
        // ?ây là instruction machine code c? th?.
        // --------------------------------------------------------

        dut.rom[0] = 32'h00A00093;  // ADDI x1, x0, 10
        dut.rom[1] = 32'h01400113;  // ADDI x2, x0, 20
        dut.rom[2] = 32'h002081B3;  // ADD  x3, x1, x2
        dut.rom[3] = 32'h00302023;  // SW   x3, 0(x0)

        // --------------------------------------------------------
        // Test 1: PC = 0x00
        // Ph?i l?y ROM[0]
        // --------------------------------------------------------

        check_instruction(
            32'h00000000,
            32'h00A00093,
            "ROM read instruction at PC = 0x00"
        );

        // --------------------------------------------------------
        // Test 2: PC = 0x04
        // Ph?i l?y ROM[1]
        // --------------------------------------------------------

        check_instruction(
            32'h00000004,
            32'h01400113,
            "ROM read instruction at PC = 0x04"
        );

        // --------------------------------------------------------
        // Test 3: PC = 0x08
        // Ph?i l?y ROM[2]
        // --------------------------------------------------------

        check_instruction(
            32'h00000008,
            32'h002081B3,
            "ROM read instruction at PC = 0x08"
        );

        // --------------------------------------------------------
        // Test 4: PC = 0x0C
        // Ph?i l?y ROM[3]
        // --------------------------------------------------------

        check_instruction(
            32'h0000000C,
            32'h00302023,
            "ROM read instruction at PC = 0x0C"
        );

        // --------------------------------------------------------
        // Test 5: PC không n?m trong ch??ng trình
        //
        // ROM[4] v?n ?ang là NOP m?c ??nh
        // --------------------------------------------------------

        check_instruction(
            32'h00000010,
            32'h00000013,
            "ROM default NOP at PC = 0x10"
        );

        // --------------------------------------------------------
        // Test 6: ??a ch? v??t quá ROM
        //
        // DEPTH = 256
        // ??a ch? word cu?i:
        // 255 * 4 = 1020 = 0x3FC
        //
        // 0x400 t??ng ?ng word index 256 ? ngoài ROM
        // RTL quy ??c tr? v? NOP.
        // --------------------------------------------------------

        check_instruction(
            32'h00000400,
            32'h00000013,
            "ROM out-of-range address"
        );

        // --------------------------------------------------------
        // K?t thúc
        // --------------------------------------------------------

        $display("========================================");
        $display("       ROM TESTBENCH FINISHED");
        $display("========================================");

        $finish;
    end

endmodule