`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2026 05:37:44 PM
// Design Name: 
// Module Name: ALU_tb
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
module ALU_tb;
logic [31:0] A;
logic [31:0] B; 
logic [3:0] ALUControl;
logic [31:0] Result;

ALU_core DUT(
    .A(A),
    .B(B),
    .ALUControl(ALUControl),
    .Result(Result)
);

task automatic Check_ALU(
input logic [31:0] a_in,
input logic [31:0] b_in,
input logic [3:0] ctrl_in,
input logic [31:0] Expected,
input string test_name
);

A = a_in;
B = b_in;
ALUControl = ctrl_in;
#1;
if (Result !== Expected) begin 
$error(
"[FAIL] %s: A = %h B = %h Result = %h Expected = %h", test_name, A, B, Result, Expected);
end
else begin 
$display(
"[PASS] %s", test_name);
end 
endtask

initial begin 
// =========================
// TEST ADD
// =========================
    Check_ALU(
    32'd10,
    32'd20,
    4'b0000,
    32'd30,
    "ADD 10 + 20");
// =========================
// TEST SUB
// =========================
    Check_ALU(
    32'd20,
    32'd10,
    4'b0001,
    32'd10,
    "SUB 20 - 19");
// =========================
// TEST AND
// =========================
    Check_ALU(
    32'hAAAAAAAA,
    32'h55555555,
    4'b0010,
    32'd00000000,
    "AND");
// =========================
// TEST OR
// =========================
    Check_ALU(
    32'hAAAAAAAA,
    32'h55555555,
    4'b0011,
    32'hFFFFFFFF,
    "OR");
// =========================
// TEST XOR
// =========================
    Check_ALU(
    32'hAAAAAAAA,
    32'h55555555,
    4'b0100,
    32'hffffffff,
    "XOR");
// =========================
// TEST SLL
// =========================
    Check_ALU(
    32'h00000001,
    32'd4,
    4'b0101,
    32'h00000010,
    "SLL");
// =========================
// TEST SRL
// =========================
    Check_ALU(
    32'h80000000,
    32'd1,
    4'b0110,
    32'h40000000,
    "SRL");
// =========================
// TEST SRA
// =========================
    Check_ALU(
    32'h80000000,
    32'd1,
    4'b0111,
    32'hC0000000,
    "SRA");
// =========================
// TEST SLT
// =========================
    Check_ALU(
    32'hFFFFFFFF,
    32'h00000001,
    4'b1000,
    32'd1,
    "SLT signed -1 < 1");
// =========================
// TEST SLTU
// =========================
    Check_ALU(
    32'hFFFFFFFF,
    32'h00000001,
    4'b1001,
    32'd0,
    "SLTU unsigned 4294967295  < 1");
// =========================
// TEST EDGE VALUE
// =========================
    Check_ALU(
    32'h7FFFFFFF,
    32'h00000001,
    4'b0000,
    32'h80000000,
    "Boundary signed overflow");
// =========================
// FINISH
// =========================
$display("--------------------------------");
$display("ALU TESTBENCH FINISHED");
$finish;
end
endmodule
