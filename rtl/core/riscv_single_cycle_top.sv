`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/03/2026 11:31:56 PM
// Design Name: 
// Module Name: riscv_single_cycle_top
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

module riscv_single_cycle_top (

    // Clock h? th?ng
    input logic clk,

    // Reset active-low
    input logic rst_n

);

    // =========================================================
    // Instantiate CPU datapath
    // =========================================================

    datapath_single_cycle u_datapath (

        // Clock truy?n vào datapath
        .clk(clk),

        // Reset active-low truy?n vào datapath
        .rst_n(rst_n)

    );

endmodule
