`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 02:06:50 PM
// Design Name: 
// Module Name: data_ram
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

module data_ram #(
    parameter int DEPTH = 256
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    input  logic        MemWrite,

    output logic [31:0] read_data
);

    // RAM g?m DEPTH word, m?i word 32-bit
    logic [31:0] ram [0:DEPTH-1];

    // Reset toàn b? RAM
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (int i = 0; i < DEPTH; i++) begin
                ram[i] <= 32'b0;
            end

        end else begin

            // Ch? ???c ghi RAM khi MemWrite = 1
            if (MemWrite && (addr[1:0] == 2'b00)) begin
                ram[addr[31:2]] <= write_data;
            end

        end
    end

    // ??c RAM combinational
    always_comb begin

        // Ch? h? tr? ??a ch? word-aligned ? Bài 9
        if ((addr[1:0] == 2'b00) &&
            (addr[31:2] < DEPTH))
            read_data = ram[addr[31:2]];
        else
            read_data = 32'b0;

    end

endmodule
