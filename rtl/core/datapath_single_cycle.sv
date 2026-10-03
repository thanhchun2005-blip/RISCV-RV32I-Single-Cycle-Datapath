`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: datapath_single_cycle
// Description: Ket noi toan bo 8 module thanh CPU Single-Cycle RV32I
//              Muc dich: buoc dem kiem chung ISA truoc khi chia tang Pipeline
//
// So do luong du lieu:
//   PC -> instr_rom -> [main_decoder + reg_file + imm_gen]
//      -> ALU_MUX_A / ALU_MUX_B -> ALU_core
//      -> data_ram -> WB_MUX -> reg_file (write back)
//
// Ghi chu phien ban Single-Cycle:
//   - pc_next = pc_current + 4 (chua xu ly Branch/Jump - se them o buoc sau)
//   - WB MUX 3-to-1: ho tro JAL/JALR ghi PC+4
//   - ALU_A MUX: phat hien AUIPC bang opcode, dung PC thay vi rs1
//////////////////////////////////////////////////////////////////////////////////


module datapath_single_cycle (
    input logic clk,
    input logic rst_n
);

    // =========================================================
    // OPCODE CONSTANTS (RV32I)
    // =========================================================
    localparam logic [6:0] OPCODE_LUI   = 7'b0110111;
    localparam logic [6:0] OPCODE_AUIPC = 7'b0010111;
    localparam logic [6:0] OPCODE_JAL   = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR  = 7'b1100111;

    // =========================================================
    // 1. Khai bao cac day noi bo
    // =========================================================

    // --- PC ---
    logic [31:0] pc_current;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;
    logic [31:0] pc_branch;    // PC + imm (Branch / JAL)
    logic [31:0] pc_jalr;      // (rs1 + imm) & ~1
    logic        branch_taken;

    // --- Instruction fields ---
    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [4:0]  rs1, rs2, rd;

    // --- Register File ---
    logic [31:0] read_data1;
    logic [31:0] read_data2;

    // --- Immediate Generator ---
    logic [31:0] immediate;

    // --- ALU ---
    logic [31:0] alu_A;
    logic [31:0] alu_B;
    logic [31:0] alu_result;

    // --- Data RAM ---a
    logic [31:0] ram_read_data;

    // --- Write-Back ---
    logic [31:0] write_back_data;

    // --- Control signals tu Main Decoder ---
    logic        reg_write;
    logic        mem_write;
    logic        alu_src;    // 0: rs2, 1: immediate (cho alu_B)
    logic        mem_to_reg; // 1: du lieu tu RAM, 0: ket qua ALU
    logic        branch;
    logic        jump;
    logic        illegal_main;

    // --- Decoder phu ---
    logic [2:0]  imm_src;
    logic [1:0]  alu_op;
    logic [3:0]  alu_control;


    // =========================================================
    // 2. Tach field instruction
    // =========================================================

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign rd     = instruction[11:7];


    // =========================================================
    // 3. PC — hien tai Single-Cycle: pc_next = pc + 4
    //    (Branch/Jump se duoc them o buoc tich hop Pipeline)
    // =========================================================

    assign pc_plus4  = pc_current + 32'd4;
    assign pc_branch = pc_current + immediate;
    assign pc_jalr   = (read_data1 + immediate) & ~32'd1;

    branch_comp u_branch_comp (
        .op_a        (read_data1),
        .op_b        (read_data2),
        .funct3      (funct3),
        .Branch      (branch),
        .branch_taken(branch_taken)
    );

    always_comb begin
        if (jump && (opcode == OPCODE_JALR))
            pc_next = pc_jalr;
        else if (jump && (opcode == OPCODE_JAL))
            pc_next = pc_branch;
        else if (branch_taken)
            pc_next = pc_branch;
        else
            pc_next = pc_plus4;
    end

    pc u_pc (
        .clk    (clk),
        .rst_n  (rst_n),
        .pc_next(pc_next),
        .pc     (pc_current)
    );


    // =========================================================
    // 4. Instruction ROM
    // =========================================================

    instr_rom u_instr_rom (
        .addr (pc_current),
        .instr(instruction)
    );


    // =========================================================
    // 5. Main Decoder
    // =========================================================

    main_decoder u_main_decoder (
        .opcode  (opcode),
        .RegWrite(reg_write),
        .MemWrite(mem_write),
        .ALUSrc  (alu_src),
        .MemToReg(mem_to_reg),
        .Branch  (branch),
        .Jump    (jump),
        .ImmSrc  (imm_src),
        .ALUOp   (alu_op),
        .Illegal (illegal_main)
    );


    // =========================================================
    // 6. Register File
    //    Chu y: reg_file dung port 'rst'
    //    -> dung ~rst_n de chuyen doi cuc
    // =========================================================

    reg_file u_regfile (
        .clk      (clk),
        .rst      (rst_n),   // reg_file dung reset active-low
        .rs1      (rs1),
        .rs2      (rs2),
        .rd       (rd),
        .WriteData(write_back_data),
        .RegWrite (reg_write),
        .ReadData1(read_data1),
        .ReadData2(read_data2)
    );


    // =========================================================
    // 7. Immediate Generator
    // =========================================================

    imm_gen u_imm_gen (
        .instr  (instruction),
        .imm_src(imm_src),
        .imm    (immediate)
    );


    // =========================================================
    // 8. ALU Decoder
    // =========================================================

    alu_decoder u_alu_decoder (
        .ALUOp     (alu_op),
        .funct3    (funct3),
        .funct7    (funct7),
        .ALUControl(alu_control)
    );


    // =========================================================
    // 9. ALU Input MUX
    //    MUX A: AUIPC can PC lam toan hang A (PC + imm)
    //    MUX B: alu_src=1 -> immediate, alu_src=0 -> rs2
    // =========================================================

    assign alu_A = (opcode == OPCODE_AUIPC) ? pc_current :
                   (opcode == OPCODE_LUI)   ? 32'd0      :
                                              read_data1;
    assign alu_B = alu_src ? immediate : read_data2;


    // =========================================================
    // 10. ALU
    // =========================================================

    ALU_core u_alu (
        .A         (alu_A),
        .B         (alu_B),
        .ALUControl(alu_control),
        .Result    (alu_result)
    );


    // =========================================================
    // 11. Data RAM
    // =========================================================

    data_ram u_data_ram (
        .clk       (clk),
        .rst_n     (rst_n),
        .addr      (alu_result),
        .write_data(read_data2),
        .MemWrite  (mem_write),
        .read_data (ram_read_data)
    );


    // =========================================================
    // 12. Write-Back MUX (3-to-1)
    //
    //   jump=1          -> PC+4   (JAL/JALR ghi dia chi tra ve)
    //   mem_to_reg=1    -> RAM    (LOAD: LW, LH, LB, ...)
    //   mac dinh        -> ALU result (R-type, I-type, LUI, AUIPC)
    //
    // Uu tien: jump > mem_to_reg > alu_result
    // =========================================================

    assign write_back_data = jump       ? pc_plus4      :
                             mem_to_reg ? ram_read_data  :
                                          alu_result;


endmodule
