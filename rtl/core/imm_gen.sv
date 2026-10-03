`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 05:22:10 PM
// Design Name: 
// Module Name: Imm_src
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
module imm_gen (
    input  logic [31:0] instr,      // Instruction 32-bit
    input  logic [2:0]  imm_src,    // Ch?n lo?i immediate
    output logic [31:0] imm         // Immediate sau khi m? r?ng
);

    always_comb begin

        // M?c ??nh ?? tránh inferred latch
        imm = 32'b0;

        case (imm_src)

            // =========================
            // I-TYPE
            // =========================
            3'b000: begin
                // imm[11:0] = instr[31:20]
                // Sign-extend 12 bit -> 32 bit
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // =========================
            // S-TYPE
            // =========================
            3'b001: begin
                // Ghép imm[11:5] và imm[4:0]
                imm = {{20{instr[31]}},
                       instr[31:25],
                       instr[11:7]};
            end

            // =========================
            // B-TYPE
            // =========================
            3'b010: begin
                // Ghép immediate theo format B
                imm = {{19{instr[31]}},
                       instr[31],
                       instr[7],
                       instr[30:25],
                       instr[11:8],
                       1'b0};
            end

            // =========================
            // U-TYPE
            // =========================
            3'b011: begin
                // 20 bit immediate + 12 bit 0
                imm = {instr[31:12], 12'b0};
            end

            // =========================
            // J-TYPE
            // =========================
            3'b100: begin
                // Ghép immediate theo format J
                imm = {{11{instr[31]}},
                       instr[31],
                       instr[19:12],
                       instr[20],
                       instr[30:21],
                       1'b0};
            end

            // =========================
            // FORMAT KHÔNG H?P L?
            // =========================
            default: begin
                imm = 32'b0;
            end

        endcase
    end

endmodule
