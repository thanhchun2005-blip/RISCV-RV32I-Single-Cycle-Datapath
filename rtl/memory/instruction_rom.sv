`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 01:45:40 PM
// Design Name: 
// Module Name: instr_rom
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


module instr_rom #(
    parameter int DEPTH = 256
)(
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    // M?i ph?n t? ROM ch?a m?t instruction 32-bit
    logic [31:0] rom [0:DEPTH-1];

    // Kh?i t?o toàn b? ROM thành NOP
    initial begin
        for (int i = 0; i < DEPTH; i++) begin
            rom[i] = 32'h00000013; // NOP = ADDI x0,x0,0
        end

        // Có th? n?p ch??ng trình b?ng:
        // $readmemh("program.hex", rom);
    end

    // ??c instruction theo ??a ch? PC
    always_comb begin

        // Ki?m tra ??a ch? có n?m trong ph?m vi ROM không
        if (addr[31:2] < DEPTH)
            instr = rom[addr[31:2]];
        else
            instr = 32'h00000013; // Ngoài ph?m vi ? NOP
    end

endmodule