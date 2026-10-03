`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2026 02:35:25 PM
// Design Name: 
// Module Name: ALU_core
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


module ALU_core(
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [3:0] ALUControl,
    output logic [31:0] Result
    );
always_comb begin 
    Result = 32'b0;
    case(ALUControl)
        4'b0000:
            Result = A + B;
        4'b0001:
            Result = A - B;
        4'b0010:
            Result = A & B;
        4'b0011:
            Result = A | B;
        4'b0100:
            Result = A ^ B;
        4'b0101:
            Result = A << B[4:0];
        4'b0110:
            Result = A >> B[4:0];
        4'b0111:
            Result = $signed(A) >>> B[4:0];
        4'b1000:
            Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
        4'b1001:
            Result = A < B ? 32'd1 : 32'd0;
        default: 
            Result = 32'b0;
      endcase 
end
        
endmodule
