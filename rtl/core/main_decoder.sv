`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2026 04:45:58 PM
// Design Name: 
// Module Name: main_decoder
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


module main_decoder (
    input  logic [6:0] opcode,     // Opcode c?a instruction

    output logic       RegWrite,   // Cho phép ghi Register File
    output logic       MemWrite,   // Cho phép ghi Data RAM
    output logic       ALUSrc,     // Ch?n operand B c?a ALU
    output logic       Branch,     // L?nh branch
    output logic       Jump,       // L?nh jump
    output logic       MemToReg,   // Ch?n d? li?u t? RAM ?? ghi v? RF
    output logic [2:0] ImmSrc,     // Ch?n lo?i immediate
    output logic [1:0] ALUOp,      // ?i?u khi?n ALU Decoder
    output logic       Illegal     // Báo instruction không h?p l?
);

    always_comb begin

        // =====================================================
        // GIÁ TR? M?C ??NH AN TOÀN
        // =====================================================

        RegWrite = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;
        MemToReg = 1'b0;

        ImmSrc   = 3'b000;
        ALUOp    = 2'b00;

        // M?c ??nh instruction là illegal
        Illegal  = 1'b1;

        // =====================================================
        // GI?I MÃ OPCODE
        // =====================================================

        case (opcode)

            // -------------------------------------------------
            // R-TYPE
            // ADD, SUB, SLL, SLT, SLTU,
            // XOR, SRL, SRA, OR, AND
            // -------------------------------------------------
            7'b0110011: begin

                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                ALUOp    = 2'b10;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // I-TYPE ALU
            // ADDI, SLTI, SLTIU, XORI,
            // ORI, ANDI, SLLI, SRLI, SRAI
            // -------------------------------------------------
            7'b0010011: begin

                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b10;

                ImmSrc   = 3'b000;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // LOAD
            // LB, LH, LW, LBU, LHU
            // -------------------------------------------------
            7'b0000011: begin

                RegWrite = 1'b1;
                ALUSrc   = 1'b1;

                // D? li?u t? Data RAM
                MemToReg = 1'b1;

                // Address = rs1 + immediate
                ALUOp    = 2'b00;

                // I-type immediate
                ImmSrc   = 3'b000;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // STORE
            // SB, SH, SW
            // -------------------------------------------------
            7'b0100011: begin

                MemWrite = 1'b1;
                ALUSrc   = 1'b1;

                // Address = rs1 + immediate
                ALUOp    = 2'b00;

                // S-type immediate
                ImmSrc   = 3'b001;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // BRANCH
            // BEQ, BNE, BLT, BGE, BLTU, BGEU
            // -------------------------------------------------
            7'b1100011: begin

                Branch = 1'b1;

                // Branch so sánh rs1 và rs2
                ALUSrc = 1'b0;

                ALUOp  = 2'b01;

                // B-type immediate
                ImmSrc = 3'b010;

                Illegal = 1'b0;

            end


            // -------------------------------------------------
            // JAL
            // -------------------------------------------------
            7'b1101111: begin

                RegWrite = 1'b1;
                Jump     = 1'b1;

                // J-type immediate
                ImmSrc   = 3'b100;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // JALR
            // -------------------------------------------------
            7'b1100111: begin

                RegWrite = 1'b1;
                Jump     = 1'b1;

                ALUSrc   = 1'b1;

                // I-type immediate
                ImmSrc   = 3'b000;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // LUI
            // -------------------------------------------------
            7'b0110111: begin

                RegWrite = 1'b1;

                ALUSrc   = 1'b1;

                // U-type immediate
                ImmSrc   = 3'b011;

                ALUOp    = 2'b11;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // AUIPC
            // -------------------------------------------------
            7'b0010111: begin

                RegWrite = 1'b1;

                ALUSrc   = 1'b1;

                // U-type immediate
                ImmSrc   = 3'b011;

                ALUOp    = 2'b00;

                Illegal  = 1'b0;

            end


            // -------------------------------------------------
            // OPCODE KHÔNG H? TR?
            // -------------------------------------------------
            default: begin

                // Gi? nguyên t?t c? giá tr? m?c ??nh an toàn

                RegWrite = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                Jump     = 1'b0;

                Illegal  = 1'b1;

            end

        endcase

    end

endmodule
