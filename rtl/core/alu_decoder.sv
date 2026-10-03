`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/26/2026 03:15:57 PM
// Design Name: 
// Module Name: ALU_Decoder
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


module alu_decoder (
    input  logic [1:0] ALUOp,       // Lo?i phép toán t? Main Decoder
    input  logic [2:0] funct3,      // funct3 c?a instruction
    input  logic [6:0] funct7,      // funct7 c?a instruction

    output logic [3:0] ALUControl,  // L?nh ?i?u khi?n ALU
    output logic       Illegal      // Báo encoding ALU không h?p l?
);

    always_comb begin

        // M?c ??nh an toàn
        ALUControl = 4'b0000;
        Illegal    = 1'b0;

        case (ALUOp)

            // =================================================
            // ALUOp = 00
            // ADD
            // Dùng cho LOAD / STORE / AUIPC
            // =================================================

            2'b00: begin

                ALUControl = 4'b0000; // ADD

            end


            // =================================================
            // ALUOp = 01
            // BRANCH
            // =================================================

            2'b01: begin

                // Branch comparison s? ???c x? lý chi ti?t
                // ? Branch Comparator.
                // ? t?ng decoder hi?n t?i dùng SUB làm phép
                // toán c? s? ?? so sánh b?ng/khác.

                ALUControl = 4'b0001; // SUB

            end


            // =================================================
            // ALUOp = 10
            // R-TYPE / I-TYPE ALU
            // =================================================

            2'b10: begin

                case (funct3)

                    // -----------------------------------------
                    // ADD / SUB / ADDI
                    // -----------------------------------------

                    3'b000: begin

                        if (funct7 == 7'b0100000)
                            ALUControl = 4'b0001; // SUB

                        else if (funct7 == 7'b0000000)
                            ALUControl = 4'b0000; // ADD

                        else
                            Illegal = 1'b1;

                    end


                    // SLL / SLLI
                    3'b001: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b0101; // SLL
                        else
                            Illegal = 1'b1;

                    end


                    // SLT / SLTI
                    3'b010: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b1000; // SLT
                        else
                            Illegal = 1'b1;

                    end


                    // SLTU / SLTIU
                    3'b011: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b1001; // SLTU
                        else
                            Illegal = 1'b1;

                    end


                    // XOR / XORI
                    3'b100: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b0100; // XOR
                        else
                            Illegal = 1'b1;

                    end


                    // SRL / SRA / SRLI / SRAI
                    3'b101: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b0110; // SRL

                        else if (funct7 == 7'b0100000)
                            ALUControl = 4'b0111; // SRA

                        else
                            Illegal = 1'b1;

                    end


                    // OR / ORI
                    3'b110: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b0011; // OR
                        else
                            Illegal = 1'b1;

                    end


                    // AND / ANDI
                    3'b111: begin

                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b0010; // AND
                        else
                            Illegal = 1'b1;

                    end


                    default: begin

                        Illegal = 1'b1;

                    end

                endcase

            end


            // =================================================
            // ALUOp = 11
            // LUI
            // =================================================

            2'b11: begin

                // LUI c?n ??a immediate vào k?t qu?.
                // Cách ghép datapath chi ti?t s? hoàn thi?n
                // khi tích h?p CPU.

                ALUControl = 4'b0000;

            end


            default: begin

                ALUControl = 4'b0000;
                Illegal    = 1'b1;

            end

        endcase

    end

endmodule
