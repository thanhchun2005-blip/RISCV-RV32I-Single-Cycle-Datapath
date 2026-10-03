`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 09:06:24 PM
// Design Name: 
// Module Name: reg_file
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


module reg_file(
    input logic clk,
    input logic rst,
    
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    
    input logic [4:0] rd,
    input logic RegWrite,
    input logic [31:0] WriteData,
    
    output logic [31:0] ReadData1,
    output logic [31:0] ReadData2
);
logic [31:0] registers [31:0];
// =========================================================
// KH?I GHI REGISTER FILE
// =========================================================
always_ff@(posedge clk or negedge rst) begin 
    if (!rst) begin 
        for (int i = 0; i < 32; i++) begin 
            registers[i] = 32'b0;
            end
    end
    else begin 
    if(RegWrite && (rd != 5'd0)) begin 
        registers[rd] <= WriteData;
        end
    end
end
// =========================================================
// KH?I GHI REGISTER FILE
// =========================================================
always_comb begin 
    if(rs1 == 5'd0) 
        ReadData1 = 32'b0;
    else 
        ReadData1 = registers[rs1];
    if(rs2 == 5'd0)
        ReadData2 = 32'b0;
    else 
        ReadData2 = registers[rs2];
 end
 endmodule 
