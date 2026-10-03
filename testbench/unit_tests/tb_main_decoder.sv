`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2026 04:46:23 PM
// Design Name: 
// Module Name: main_decoder_tb
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


module main_decoder_tb;
    logic [6:0] opcode;
    logic       RegWrite;
    logic       MemWrite;
    logic       ALUSrc;
    logic       Branch;
    logic       Jump;
    logic       MemToReg;
    logic [2:0] ImmSrc;
    logic [1:0] ALUOp;
    logic       Illegal;


    main_decoder dut (
        .opcode   (opcode),

        .RegWrite (RegWrite),
        .MemWrite (MemWrite),
        .ALUSrc   (ALUSrc),
        .Branch   (Branch),
        .Jump     (Jump),
        .MemToReg (MemToReg),
        .ImmSrc   (ImmSrc),
        .ALUOp    (ALUOp),
        .Illegal  (Illegal)
    );


    task check_decoder(
        input logic [6:0] op,

        input logic exp_RegWrite,
        input logic exp_MemWrite,
        input logic exp_ALUSrc,
        input logic exp_Branch,
        input logic exp_Jump,
        input logic exp_MemToReg,
        input logic [2:0] exp_ImmSrc,
        input logic [1:0] exp_ALUOp,
        input logic exp_Illegal,

        input string name
    );

        begin

            opcode = op;

            #1;

            if (
                RegWrite === exp_RegWrite &&
                MemWrite === exp_MemWrite &&
                ALUSrc   === exp_ALUSrc &&
                Branch   === exp_Branch &&
                Jump     === exp_Jump &&
                MemToReg === exp_MemToReg &&
                ImmSrc   === exp_ImmSrc &&
                ALUOp    === exp_ALUOp &&
                Illegal  === exp_Illegal
            ) begin

                $display("[PASS] %s", name);

            end
            else begin

                $error("[FAIL] %s", name);

                $display("       opcode   = %b", opcode);

                $display("       RegWrite = %b / expected %b",
                         RegWrite, exp_RegWrite);

                $display("       MemWrite = %b / expected %b",
                         MemWrite, exp_MemWrite);

                $display("       ALUSrc   = %b / expected %b",
                         ALUSrc, exp_ALUSrc);

                $display("       Branch   = %b / expected %b",
                         Branch, exp_Branch);

                $display("       Jump     = %b / expected %b",
                         Jump, exp_Jump);

                $display("       MemToReg = %b / expected %b",
                         MemToReg, exp_MemToReg);

                $display("       ImmSrc   = %b / expected %b",
                         ImmSrc, exp_ImmSrc);

                $display("       ALUOp    = %b / expected %b",
                         ALUOp, exp_ALUOp);

                $display("       Illegal  = %b / expected %b",
                         Illegal, exp_Illegal);

            end

        end

    endtask


    initial begin

        // =====================================================
        // R-TYPE
        // =====================================================

        check_decoder(
            7'b0110011,
            1, 0, 0, 0, 0, 0,
            3'b000,
            2'b10,
            0,
            "R-type"
        );


        // =====================================================
        // I-TYPE ALU
        // =====================================================

        check_decoder(
            7'b0010011,
            1, 0, 1, 0, 0, 0,
            3'b000,
            2'b10,
            0,
            "I-type ALU"
        );


        // =====================================================
        // LOAD
        // =====================================================

        check_decoder(
            7'b0000011,
            1, 0, 1, 0, 0, 1,
            3'b000,
            2'b00,
            0,
            "LOAD"
        );


        // =====================================================
        // STORE
        // =====================================================

        check_decoder(
            7'b0100011,
            0, 1, 1, 0, 0, 0,
            3'b001,
            2'b00,
            0,
            "STORE"
        );


        // =====================================================
        // BRANCH
        // =====================================================

        check_decoder(
            7'b1100011,
            0, 0, 0, 1, 0, 0,
            3'b010,
            2'b01,
            0,
            "BRANCH"
        );


        // =====================================================
        // JAL
        // =====================================================

        check_decoder(
            7'b1101111,
            1, 0, 0, 0, 1, 0,
            3'b100,
            2'b00,
            0,
            "JAL"
        );


        // =====================================================
        // JALR
        // =====================================================

        check_decoder(
            7'b1100111,
            1, 0, 1, 0, 1, 0,
            3'b000,
            2'b00,
            0,
            "JALR"
        );


        // =====================================================
        // LUI
        // =====================================================

        check_decoder(
            7'b0110111,
            1, 0, 1, 0, 0, 0,
            3'b011,
            2'b11,
            0,
            "LUI"
        );


        // =====================================================
        // AUIPC
        // =====================================================

        check_decoder(
            7'b0010111,
            1, 0, 1, 0, 0, 0,
            3'b011,
            2'b00,
            0,
            "AUIPC"
        );


        // =====================================================
        // ILLEGAL OPCODE
        // =====================================================

        check_decoder(
            7'b1111111,
            0, 0, 0, 0, 0, 0,
            3'b000,
            2'b00,
            1,
            "Illegal opcode"
        );


        $display("==========================================");
        $display("Main Decoder Test Completed");
        $display("==========================================");

        $finish;

    end

endmodule