`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 02:07:16 PM
// Design Name: 
// Module Name: data_ram_tb
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


module data_ram_tb;

    localparam int DEPTH = 16;

    logic        clk;
    logic        rst_n;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic        MemWrite;
    logic [31:0] read_data;

    data_ram #(
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .write_data(write_data),
        .MemWrite(MemWrite),
        .read_data(read_data)
    );

    // Clock 10 ns
    always #5 clk = ~clk;

    task write_word(
        input logic [31:0] test_addr,
        input logic [31:0] data,
        input string       test_name
    );
        begin

            addr      = test_addr;
            write_data = data;
            MemWrite  = 1'b1;

            @(posedge clk);
            #1;

            $display("[PASS] %s", test_name);

            MemWrite = 1'b0;

        end
    endtask

    task check_read(
        input logic [31:0] test_addr,
        input logic [31:0] expected,
        input string       test_name
    );
        begin

            addr = test_addr;
            #1;

            if (read_data === expected) begin
                $display("[PASS] %s", test_name);
            end
            else begin
                $error("[FAIL] %s", test_name);
                $display("       Address  = %h", addr);
                $display("       Expected = %h", expected);
                $display("       Actual   = %h", read_data);
            end

        end
    endtask

    initial begin

        clk       = 1'b0;
        rst_n     = 1'b0;
        addr      = 32'b0;
        write_data = 32'b0;
        MemWrite  = 1'b0;

        // Reset
        #2;
        rst_n = 1'b1;

        // -------------------------------
        // TEST 1: Ghi và ??c word bình th??ng
        // -------------------------------

        write_word(
            32'h00000000,
            32'h12345678,
            "Write RAM address 0"
        );

        check_read(
            32'h00000000,
            32'h12345678,
            "Read RAM address 0"
        );

        // -------------------------------
        // TEST 2: Boundary 0xFFFFFFFF
        // -------------------------------

        write_word(
            32'h00000004,
            32'hFFFFFFFF,
            "Write 0xFFFFFFFF"
        );

        check_read(
            32'h00000004,
            32'hFFFFFFFF,
            "Read 0xFFFFFFFF"
        );

        // -------------------------------
        // TEST 3: Boundary 0x80000000
        // -------------------------------

        write_word(
            32'h00000008,
            32'h80000000,
            "Write 0x80000000"
        );

        check_read(
            32'h00000008,
            32'h80000000,
            "Read 0x80000000"
        );

        // -------------------------------
        // TEST 4: Boundary 0x7FFFFFFF
        // -------------------------------

        write_word(
            32'h0000000C,
            32'h7FFFFFFF,
            "Write 0x7FFFFFFF"
        );

        check_read(
            32'h0000000C,
            32'h7FFFFFFF,
            "Read 0x7FFFFFFF"
        );

        // -------------------------------
        // TEST 5: MemWrite = 0
        // -------------------------------

        addr       = 32'h00000000;
        write_data = 32'hDEADBEEF;
        MemWrite   = 1'b0;

        @(posedge clk);
        #1;

        check_read(
            32'h00000000,
            32'h12345678,
            "MemWrite=0 must not overwrite RAM"
        );

        // -------------------------------
        // TEST 6: Misaligned address
        // -------------------------------

        addr       = 32'h00000002;
        write_data = 32'hAAAAAAAA;
        MemWrite   = 1'b1;

        @(posedge clk);
        #1;

        MemWrite = 1'b0;

        check_read(
            32'h00000002,
            32'h00000000,
            "Misaligned read returns 0"
        );

        // -------------------------------
        // TEST 7: Out-of-range
        // -------------------------------

        check_read(
            32'h00010000,
            32'h00000000,
            "Out-of-range read returns 0"
        );

        $display("--------------------------------");
        $display("Data RAM TEST DONE");
        $display("--------------------------------");

        $finish;

    end

endmodule