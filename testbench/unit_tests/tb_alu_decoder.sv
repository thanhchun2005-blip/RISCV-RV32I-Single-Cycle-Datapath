`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/26/2026 03:16:15 PM
// Design Name: 
// Module Name: ALU_Decoder_tb
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


module alu_decoder_tb;

    logic [1:0] ALUOp;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [3:0] ALUControl;
    logic       Illegal;


    alu_decoder dut (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl),
        .Illegal    (Illegal)
    );


    task check_alu_decoder(
        input logic [1:0] op,
        input logic [2:0] f3,
        input logic [6:0] f7,

        input logic [3:0] expected_control,
        input logic       expected_illegal,

        input string name
    );

        begin

            ALUOp  = op;
            funct3 = f3;
            funct7 = f7;

            #1;

            if (
                ALUControl === expected_control &&
                Illegal    === expected_illegal
            ) begin

                $display("[PASS] %s", name);

            end
            else begin

                $error("[FAIL] %s", name);

                $display("       ALUOp      = %b", ALUOp);
                $display("       funct3     = %b", funct3);
                $display("       funct7     = %b", funct7);

                $display("       Expected ALUControl = %b",
                         expected_control);

                $display("       Actual ALUControl   = %b",
                         ALUControl);

                $display("       Expected Illegal = %b",
                         expected_illegal);

                $display("       Actual Illegal   = %b",
                         Illegal);

            end

        end

    endtask


    initial begin

        // =====================================================
        // R-TYPE
        // =====================================================

        // ADD
        check_alu_decoder(
            2'b10,
            3'b000,
            7'b0000000,
            4'b0000,
            0,
            "ADD"
        );


        // SUB
        check_alu_decoder(
            2'b10,
            3'b000,
            7'b0100000,
            4'b0001,
            0,
            "SUB"
        );


        // SLL
        check_alu_decoder(
            2'b10,
            3'b001,
            7'b0000000,
            4'b0101,
            0,
            "SLL"
        );


        // SLT
        check_alu_decoder(
            2'b10,
            3'b010,
            7'b0000000,
            4'b1000,
            0,
            "SLT"
        );


        // SLTU
        check_alu_decoder(
            2'b10,
            3'b011,
            7'b0000000,
            4'b1001,
            0,
            "SLTU"
        );


        // XOR
        check_alu_decoder(
            2'b10,
            3'b100,
            7'b0000000,
            4'b0100,
            0,
            "XOR"
        );


        // SRL
        check_alu_decoder(
            2'b10,
            3'b101,
            7'b0000000,
            4'b0110,
            0,
            "SRL"
        );


        // SRA
        check_alu_decoder(
            2'b10,
            3'b101,
            7'b0100000,
            4'b0111,
            0,
            "SRA"
        );


        // OR
        check_alu_decoder(
            2'b10,
            3'b110,
            7'b0000000,
            4'b0011,
            0,
            "OR"
        );


        // AND
        check_alu_decoder(
            2'b10,
            3'b111,
            7'b0000000,
            4'b0010,
            0,
            "AND"
        );


        // =====================================================
        // LOAD / STORE / AUIPC
        // ALU ph?i ADD
        // =====================================================

        check_alu_decoder(
            2'b00,
            3'b000,
            7'b0000000,
            4'b0000,
            0,
            "ALU ADD operation"
        );


        // =====================================================
        // BRANCH
        // =====================================================

        check_alu_decoder(
            2'b01,
            3'b000,
            7'b0000000,
            4'b0001,
            0,
            "BRANCH comparison"
        );


        // =====================================================
        // LUI
        // =====================================================

        check_alu_decoder(
            2'b11,
            3'b000,
            7'b0000000,
            4'b0000,
            0,
            "LUI"
        );


        // =====================================================
        // ILLEGAL funct7
        // =====================================================

        check_alu_decoder(
            2'b10,
            3'b000,
            7'b1111111,
            4'b0000,
            1,
            "Illegal ADD/SUB funct7"
        );


        // =====================================================
        // ILLEGAL SHIFT
        // =====================================================

        check_alu_decoder(
            2'b10,
            3'b101,
            7'b1111111,
            4'b0000,
            1,
            "Illegal shift funct7"
        );


        // =====================================================
        // ILLEGAL ALUOp
        // =====================================================

        check_alu_decoder(
            2'bxx,
            3'bxxx,
            7'bxxxxxxx,
            4'b0000,
            1,
            "Illegal ALUOp"
        );


        $display("==========================================");
        $display("ALU Decoder Test Completed");
        $display("==========================================");

        $finish;

    end

endmodule
