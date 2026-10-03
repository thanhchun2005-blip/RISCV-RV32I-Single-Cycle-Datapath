`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 09:06:43 PM
// Design Name: 
// Module Name: reg_file_tb
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


module reg_file_tb;
logic clk;
logic rst;

logic [4:0] rs1;
logic [4:0] rs2;

logic [4:0] rd;
logic [31:0] WriteData;
logic RegWrite;

logic [31:0] ReadData1;
logic [31:0] ReadData2;

reg_file DUT (
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .RegWrite(RegWrite),
    .WriteData(WriteData),
    .ReadData1(ReadData1),
    .ReadData2(ReadData2)
);
// =========================================================
// CLOCK
// =========================================================
initial begin 
    clk = 1'b0;
    forever #5 clk = ~clk;
end 
// =========================================================
// TASK KI?M TRA 2 C?NG ??C
// =========================================================
task Check_Read_Ports(
input logic [4:0] addr1,
input logic [31:0] expected1,

input logic [4:0] addr2,
input logic [31:0] expected2,

input string test_name
);
    begin 
        rs1 = addr1;
        rs2 = addr2;
        
        #1;
        if (ReadData1 === expected1) begin 
            $display("[PASS] %s - ReadData1", test_name);
        end
        else begin 
            $error("[FAIL] %s - ReadData1", test_name);
            $display(" rs1 = x%0d", addr1);
            $display(" Expected = %h", expected1);
            $display(" Actual = %h", ReadData1);
        end
        if(ReadData2 === expected2) begin 
            $display("[PASS] %s - ReadData2", test_name);
        end
        else begin 
            $error("[FAIL] %s - ReadData2", test_name);
            $display(" rs2 = x%0d", addr2);
            $display(" Expected = %h", expected2);
            $display(" Actual = %h", ReadData2);
        end
    end
endtask
// =========================================================
// TASK GHI REGISTER
// =========================================================
task write_register(
    input logic [4:0] addr,
    input logic [31:0] data
);

begin 
    @(negedge clk);
    rd = addr;
    WriteData = data;
    RegWrite = 1'b1;
    
    @(posedge clk);
    RegWrite = 0'b1; 
end 
endtask
// =========================================================
// TEST
// =========================================================
initial begin 
    rst       = 1'b0;
    rs1       = 5'd0;
    rs2       = 5'd0;
    rd        = 5'd0;
    WriteData = 5'd0;
    RegWrite  = 1'b0;
// -----------------------------------------------------
// TEST 1: RESET
// -----------------------------------------------------
#10 
    rst = 1'b1;
    Check_Read_Ports(
        5'd0,
        32'h0000_0000,
        5'd1,
        32'h0000_0000,
        "Reset"
);
// -----------------------------------------------------
// TEST 2: GHI x5 = 100
// -----------------------------------------------------       
    write_register(
        5'd5,
        32'd100
    );
    Check_Read_Ports(
        5'd5,
        32'd100,
        5'd0,
        32'd0,
        "Write x5 = 100"
    );
// -----------------------------------------------------
// TEST 3: GHI x10 = 0xFFFFFFFF
// Boundary value
// -----------------------------------------------------
    write_register(
        5'd10,
        32'hFFFF_FFFF
    );
    Check_Read_Ports(
        5'd5,
        32'd100,
        5'd10,
        32'hFFFF_FFFF,
        "Write x10 = 0xFFFF_FFFF"
    );
    // -----------------------------------------------------
// TEST 4: ??C HAI REGISTER CÙNG LÚC
// -----------------------------------------------------
    Check_Read_Ports(
        5'd5,
        32'd100,
        5'd10,
        32'hFFFF_FFFF,
        "Dual read x5 an? x10"
    );
    // -----------------------------------------------------
// TEST 5: GHI GIÁ TR? BIÊN 0x80000000
// -----------------------------------------------------
    write_register(
        5'd15,
        32'h8000_0000
    );
    Check_Read_Ports(
        5'd15,
        32'h8000_0000,
        5'd10,
        32'hFFFF_FFFF,
        "Boundary values"
    );
// -----------------------------------------------------
// TEST 6: GHI GIÁ TR? 0x7FFFFFFF
// -----------------------------------------------------
    write_register(
        5'd20,
        32'h7FFF_FFFF
    );
    Check_Read_Ports(
        5'd20,
        32'h7FFF_FFFF,
        5'd15,
        32'h8000_0000,
        "Signed boundary values"
     );
// -----------------------------------------------------
// TEST 7: RegWrite = 0
// Không ???c phép thay ??i register
// -----------------------------------------------------
    @(negedge clk);
        rd        = 5'd5;
        WriteData = 32'h12345678;
        RegWrite  = 1'b0;
    
    @(posedge clk);
    #1;
    Check_Read_Ports(
        5'd5,
        32'd100,
        5'd10,
        32'hFFFF_FFFF,
        "RegWrite = 0 must not write"
    );
// -----------------------------------------------------
// TEST 8: C? TÌNH GHI x0
// x0 ph?i luôn b?ng 0
// -----------------------------------------------------
    write_register(
        5'd0,
        32'h12345678
    );
    Check_Read_Ports(
        5'd0,
        32'h0,
        5'd5,
        32'd100,
        "Write register x0"
    );
// -----------------------------------------------------
// TEST 9: KI?M TRA x0 QUA C? HAI C?NG ??C
// -----------------------------------------------------
    Check_Read_Ports(
        5'd0,
        32'd0,
        5'd0,
        32'd0,
        "x0 through both read ports"
    );
// -----------------------------------------------------
// K?T THÚC
 // -----------------------------------------------------
    $display("==============================================");
    $display("Register File Unit Test Completed");
    $display("==============================================");
        $finish;
    end
endmodule

