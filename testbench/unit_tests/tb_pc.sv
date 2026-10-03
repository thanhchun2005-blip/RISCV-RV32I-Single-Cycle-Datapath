`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 10:10:31 PM
// Design Name: 
// Module Name: pc_tb
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

module pc_tb;
    logic        clk;
    logic        rst_n;

    logic [31:0] pc_next;
    logic [31:0] pc;

    pc dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .pc_next (pc_next),
        .pc      (pc)
    );
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end
    // ============================================================
    // Task ki?m tra PC
    // ============================================================
    task check_pc(
        input logic [31:0] expected,
        input string       test_name
    );
        begin

            if (pc === expected) begin

                $display(
                    "[PASS] %s | PC = 0x%08h",
                    test_name,
                    pc
                );

            end

            else begin

                $error(
                    "[FAIL] %s | Expected = 0x%08h | Actual = 0x%08h",
                    test_name,
                    expected,
                    pc
                );

            end

        end
    endtask

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        $display("======================================");
        $display("          PC TESTBENCH");
        $display("======================================");
        rst_n  = 1'b0;
        pc_next = 32'h00000000;
        @(posedge clk);
        #1;
        check_pc(
            32'h00000000,
            "Reset PC = 0"
        );
        rst_n = 1'b1;
        // --------------------------------------------------------
        // 3. PC = 0x00000004
        // --------------------------------------------------------
        pc_next = 32'h00000004;
        @(posedge clk);
        #1;

        check_pc(
            32'h00000004,
            "PC updates to 0x00000004"
        );

        // --------------------------------------------------------
        // 4. PC = 0x00000008
        // --------------------------------------------------------

        pc_next = 32'h00000008;

        @(posedge clk);
        #1;

        check_pc(
            32'h00000008,
            "PC updates to 0x00000008"
        );

        // --------------------------------------------------------
        // 5. PC = 0x0000000C
        // --------------------------------------------------------

        pc_next = 32'h0000000C;

        @(posedge clk);
        #1;

        check_pc(
            32'h0000000C,
            "PC updates to 0x0000000C"
        );

        // --------------------------------------------------------
        // 6. Boundary: PC = 0xFFFFFFFF
        // --------------------------------------------------------

        pc_next = 32'hFFFFFFFF;

        @(posedge clk);
        #1;

        check_pc(
            32'hFFFFFFFF,
            "PC boundary = 0xFFFFFFFF"
        );

        // --------------------------------------------------------
        // 7. Boundary: PC = 0x80000000
        // --------------------------------------------------------

        pc_next = 32'h80000000;

        @(posedge clk);
        #1;

        check_pc(
            32'h80000000,
            "PC boundary = 0x80000000"
        );

        // --------------------------------------------------------
        // K?t thúc
        // --------------------------------------------------------

        $display("======================================");
        $display("          PC TEST FINISHED");
        $display("======================================");

        $finish;

    end

endmodule