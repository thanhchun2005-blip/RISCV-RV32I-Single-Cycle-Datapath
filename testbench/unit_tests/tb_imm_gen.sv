`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 05:22:52 PM
// Design Name: 
// Module Name: Imm_gen_tb
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
module Imm_gen_tb;

    logic [31:0] instr;
    logic [2:0]  imm_src;
    logic [31:0] imm;

    imm_gen dut (
        .instr   (instr),
        .imm_src (imm_src),
        .imm     (imm)
    );

    task check_imm(
        input logic [31:0] expected,
        input string name
    );
        begin
            #1;

            if (imm === expected)
                $display("[PASS] %s: imm = %h", name, imm);
            else
                $error("[FAIL] %s: expected=%h actual=%h",
                       name, expected, imm);
        end
    endtask

    initial begin

        // =====================================
        // I-TYPE: +10
        // =====================================
        instr   = 32'b0;
        instr[31:20] = 12'd10;
        imm_src = 3'b000;

        check_imm(32'd10, "I-type +10");


        // =====================================
        // I-TYPE: -1
        // 12-bit immediate = 0xFFF
        // =====================================
        instr   = 32'b0;
        instr[31:20] = 12'hFFF;
        imm_src = 3'b000;

        check_imm(32'hFFFFFFFF, "I-type -1");


        // =====================================
        // U-TYPE
        // =====================================
        instr   = 32'b0;
        instr[31:12] = 20'h12345;
        imm_src = 3'b011;

        check_imm(32'h12345000, "U-type");


        $display("================================");
        $display("ImmGen test completed");
        $display("================================");

        $finish;
    end

endmodule
