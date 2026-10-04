# RISC-V RV32I Single-Cycle Processor Core

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-red.svg)
![Simulation](https://img.shields.io/badge/Simulation-Vivado%20XSim%202022.2-orange.svg)
![Verification](https://img.shields.io/badge/Tests-58%2F58%20PASSED%20(100%25)-brightgreen.svg)
![FPGA](https://img.shields.io/badge/Target-Xilinx%20Artix--7-purple.svg)

Lõi vi xử lý **RISC-V RV32I (32-bit Base Integer ISA)** kiến trúc **Single-Cycle Datapath** được thiết kế bằng **SystemVerilog**, hỗ trợ đầy đủ tập lệnh chuẩn và tích hợp bộ kiểm thử tự động (**Self-Checking Testbench**) toàn diện chạy trên **Xilinx Vivado**.

Đây là bước nền tảng trong đề tài *"Thiết kế, kiểm chứng và triển khai FPGA lõi vi xử lý RISC-V RV32I 5 tầng pipeline"*. Kiến trúc Single-Cycle đóng vai trò mô hình tham chiếu (Golden Model) để kiểm chứng tính đúng đắn của Datapath, Control Unit và tập lệnh trước khi mở rộng lên 5-stage pipeline có Forwarding và Hazard Detection.

---

## Mục lục

1. [Tính năng nổi bật](#1-tính-năng-nổi-bật)
2. [Cấu trúc thư mục](#2-cấu-trúc-thư-mục)
3. [Kiến trúc Datapath & Khối điều khiển](#3-kiến-trúc-datapath--khối-điều-khiển)
4. [Tập lệnh RV32I được hỗ trợ](#4-tập-lệnh-rv32i-được-hỗ-trợ)
5. [Quy hoạch Datapath và Logic MUX](#5-quy-hoạch-datapath-và-logic-mux)
6. [Hệ thống kiểm thử (Verification & Testbench)](#6-hệ-thống-kiểm-thử-verification--testbench)
   - [Kiểm thử mức hệ thống (riscv_single_cycle_tb.sv)](#kiểm-thử-mức-hệ-thống-riscv_single_cycle_tbsv)
   - [Kết quả kiểm thử tự động (58/58 Tests Passed)](#kết-quả-kiểm-thử-tự-động-5858-tests-passed)
   - [Kiểm thử mức khối (Unit Tests)](#kiểm-thử-mức-khối-unit-tests)
7. [Hướng dẫn cài đặt và chạy mô phỏng trên Vivado](#7-hướng-dẫn-cài-đặt-và-chạy-mô-phỏng-trên-vivado)
8. [Quan sát dạng sóng (Waveform Guide)](#8-quan-sát-dạng-sóng-waveform-guide)
9. [Lộ trình phát triển](#9-lộ-trình-phát-triển)
10. [Tác giả](#10-tác-giả)

---

## 1. Tính năng nổi bật

- **Kiến trúc Single-Cycle chuẩn:** Mỗi lệnh hoàn thành trong đúng 1 chu kỳ xung nhịp (`CPI = 1.0`).
- **Hỗ trợ đầy đủ tập lệnh RV32I:** R-type, I-type (ALU, Load, JALR), S-type (Store), B-type (Branch), U-type (LUI, AUIPC), J-type (JAL).
- **Hệ thống thanh ghi RegFile:** 32 thanh ghi 32-bit đa dụng; thanh ghi `x0` luôn được cố định cứng bằng `0` (hardwired zero).
- **ALU 32-bit hiệu năng cao:** Hỗ trợ 10 phép toán số học, logic, dịch bit và so sánh có dấu / không dấu.
- **Bộ giải mã lệnh hai cấp:** Tách biệt rõ ràng giữa `Main Decoder` (quản lý luồng tín hiệu điều khiển) và `ALU Decoder` (giải mã chi tiết toán tử ALU).
- **Testbench toàn diện (58 Test Cases):** Tự động nạp lệnh vào ROM, chạy chương trình thực tế (Fibonacci), kiểm tra giá trị biên (Corner Cases) và xuất bảng tổng kết trực quan lên TCL Console.

---

## 2. Cấu trúc thư mục

```
RISCV-RV32I-Single-Cycle-Datapath/
├── rtl/
│   ├── core/
│   │   ├── riscv_single_cycle_top.sv     # Top-level đóng gói CPU
│   │   ├── datapath_single_cycle.sv      # Kết nối toàn bộ datapath và multiplexer
│   │   ├── pc.sv                         # Thanh ghi Program Counter (PC)
│   │   ├── regfile.sv                    # Tập thanh ghi 32x32-bit (x0 = 0)
│   │   ├── imm_gen.sv                    # Bộ tạo và mở rộng dấu Immediate (I/S/B/U/J)
│   │   ├── main_decoder.sv               # Bộ giải mã điều khiển chính từ opcode
│   │   ├── alu_decoder.sv                # Bộ giải mã ALU từ funct3, funct7 và ALUOp
│   │   ├── alu.sv                        # Bộ số học và logic 32-bit (module ALU_core)
│   │   └── branch_comp.sv                # Bộ so sánh điều kiện rẽ nhánh
│   └── memory/
│       ├── instruction_rom.sv            # ROM chứa mã máy chương trình (instr_rom)
│       └── data_ram.sv                   # RAM dữ liệu 32-bit đọc bất đồng bộ
├── testbench/
│   ├── riscv_single_cycle_tb.sv          # Testbench tổng thể mức CPU (58 Test Cases)
│   └── unit_tests/                       # 8 Unit testbench cho từng module con
│       ├── tb_alu.sv
│       ├── tb_alu_decoder.sv
│       ├── tb_branch_comp.sv
│       ├── tb_data_ram.sv
│       ├── tb_imm_gen.sv
│       ├── tb_instruction_rom.sv
│       ├── tb_main_decoder.sv
│       ├── tb_pc.sv
│       └── tb_regfile.sv
├── create_project.tcl                    # Script Tcl tự động sinh Project Vivado chuẩn
└── README.md                             # Tài liệu kỹ thuật chi tiết
```

---

## 3. Kiến trúc Datapath & Khối điều khiển

Sơ đồ khối luồng dữ liệu và tín hiệu điều khiển:

```
                          clk / rst_n
                               |
           +-------------------+--------------------+
           |           datapath_single_cycle         |
           |                                         |
           |  +----+  pc   +-----------+             |
           |  | PC |------>| instr_rom |             |
           |  +----+       +-----------+             |
           |    ^                | instr [31:0]      |
           |    |         +------+-------+           |
           |  pc_next     |      |       |           |
           |    |    +----------+| +----------+      |
           |    |    |main_dec. || | imm_gen  |      |
           |    |    +----------+| +----------+      |
           |    |      ctrl      |   immediate       |
           |    |        |       v       |           |
           |    |        |  +---------+  |           |
           |    |        |  | reg_file|  |           |
           |    |        |  +---------+  |           |
           |    |        |   rd1   rd2   |           |
           |    |        |    |     |    |           |
           |    |        |  MUX A   MUX B<+          |
           |    |        |    |       |  (ALUSrc)    |
           |    |   +-----------+     |              |
           |    |   |alu_decoder|     |              |
           |    |   +-----------+     |              |
           |    |        |            |              |
           |    |    +--------------------+          |
           |    |    |      ALU_core      |          |
           |    |    +--------------------+          |
           |    |              | alu_result          |
           |    |              +--------->+----------+
           |    |                         | data_ram |
           |    |                         +----------+
           |    |                              | mem_data
           |    |        +---------------------+
           |    |        | WB MUX: jump? PC+4 : (load? RAM : ALU)
           |    |        +------> WriteData
           |    |
           |  +-------------+    +--------------+
           +--| PC Next MUX |<---| branch_comp  |
              +-------------+    +--------------+
```

### Danh sách module con

| Module | Tên File | Chức năng chính |
|:---|:---|:---|
| `pc` | `pc.sv` | Program Counter 32-bit; khởi tạo về `0x00000000` khi Reset. |
| `instr_rom` | `instruction_rom.sv` | ROM lệnh kích thước 256 word (có thể cấu hình), đọc tổ hợp. Mặc định trả về NOP (`0x00000013`). |
| `main_decoder` | `main_decoder.sv` | Giải mã opcode tạo các tín hiệu: `RegWrite`, `MemWrite`, `ALUSrc`, `MemToReg`, `Branch`, `Jump`, `ImmSrc`, `ALUOp`. |
| `reg_file` | `regfile.sv` | Tập 32 thanh ghi 32-bit, 2 cổng đọc bất đồng bộ, 1 cổng ghi đồng bộ tại sườn dương clock, `x0` luôn cố định bằng `0`. |
| `imm_gen` | `imm_gen.sv` | Mở rộng dấu tức thời 32-bit cho 5 định dạng: I, S, B, U, J. |
| `alu_decoder` | `alu_decoder.sv` | Kết hợp `ALUOp`, `funct3`, `funct7[5]` để điều khiển 4-bit `ALUControl`. |
| `ALU_core` | `alu.sv` | Thực hiện 10 phép toán 32-bit: cộng, trừ, and, or, xor, sll, srl, sra, slt, sltu. |
| `branch_comp` | `branch_comp.sv` | Đánh giá điều kiện rẽ nhánh (BEQ, BNE, BLT, BGE, BLTU, BGEU). |
| `data_ram` | `data_ram.sv` | RAM dữ liệu 256 words; ghi đồng bộ theo clock, đọc bất đồng bộ. |

---

## 4. Tập lệnh RV32I được hỗ trợ

Lõi CPU hỗ trợ trọn vẹn tập lệnh số nguyên cơ bản RV32I:

| Định dạng | Lệnh | Ý nghĩa |
|:---|:---|:---|
| **R-type** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | Thao tác số học, logic và dịch bit giữa hai thanh ghi. |
| **I-type ALU** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | Thao tác số học, logic và dịch bit với hằng số mở rộng dấu. |
| **I-type Load** | `LW`, `LH`, `LB`, `LHU`, `LBU` | Đọc dữ liệu từ bộ nhớ RAM vào thanh ghi. |
| **S-type Store** | `SW`, `SH`, `SB` | Ghi dữ liệu từ thanh ghi vào bộ nhớ RAM. |
| **B-type Branch** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | Rẽ nhánh có điều kiện (so sánh có dấu và không dấu). |
| **J-type Jump** | `JAL` | Nhảy không điều kiện theo độ lệch PC, lưu địa chỉ trả về `PC+4`. |
| **I-type Jump** | `JALR` | Nhảy gián tiếp qua thanh ghi `(rs1 + imm) & ~1`, lưu địa chỉ trả về `PC+4`. |
| **U-type** | `LUI`, `AUIPC` | Nạp 20 bit cao vào thanh ghi (`LUI`) hoặc cộng vào PC (`AUIPC`). |

---

## 5. Quy hoạch Datapath và Logic MUX

### MUX A (Toán hạng A của ALU)
Cho phép linh hoạt chọn nguồn cấp cho cổng A của ALU mà không cần thêm tín hiệu giải mã phụ:
```systemverilog
assign alu_A = (opcode == OPCODE_AUIPC) ? pc_current :
               (opcode == OPCODE_LUI)   ? 32'd0      :
                                          read_data1;
```

### MUX B (Toán hạng B của ALU)
Chọn giữa dữ liệu từ thanh ghi `rs2` hoặc giá trị tức thời `immediate`:
```systemverilog
assign alu_B = (alu_src == 1'b1) ? immediate : read_data2;
```

### MUX Write-Back (Dữ liệu ghi ngược vào RegFile)
Lựa chọn nguồn dữ liệu ghi lại theo mức ưu tiên:
```systemverilog
assign reg_write_data = (jump == 1'b1)       ? pc_plus4      : // JAL, JALR ghi địa chỉ trả về
                        (mem_to_reg == 1'b1) ? ram_read_data : // Lệnh Load đọc từ RAM
                                               alu_result;     // R-type, I-type ALU, LUI, AUIPC
```

### Logic tính toán Program Counter kế tiếp (`pc_next`)
```systemverilog
pc_plus4  = pc_current + 4;
pc_branch = pc_current + immediate;                    // Nhánh và JAL
pc_jalr   = (read_data1 + immediate) & ~32'd1;         // JALR: xoá bit LSB

if      (jump && (opcode == OPCODE_JALR)) pc_next = pc_jalr;
else if (jump && (opcode == OPCODE_JAL))  pc_next = pc_branch;
else if (branch_taken)                    pc_next = pc_branch;
else                                      pc_next = pc_plus4;
```

---

## 6. Hệ thống kiểm thử (Verification & Testbench)

### Kiểm thử mức hệ thống (`riscv_single_cycle_tb.sv`)

Testbench cấp hệ thống được thiết kế theo chuẩn kiểm thử tự động, tích hợp bộ tạo lệnh (Instruction Encoders) trực tiếp nạp chương trình vào ROM mà không cần file `.hex` rời bên ngoài.

Testbench bao gồm **9 bài kiểm tra lớn (Test Suites)** chia thành **58 Test Cases**:

1. **[TEST 1] Reset & Zero Register:** Xác thực thanh ghi `x0` bất biến với giá trị `0` và khởi động lại CPU.
2. **[TEST 2] R-Type ALU Instructions:** Kiểm tra đủ 10 phép toán R-type (`ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`).
3. **[TEST 3] I-Type ALU Instructions:** Kiểm tra 9 phép toán tính toán với số tức thời (bao gồm dịch bit và số âm mở rộng dấu).
4. **[TEST 4] LUI & AUIPC:** Xác thực nạp số lớn vào 20 bit cao và tính toán địa chỉ dựa trên PC.
5. **[TEST 5] Memory LW & SW:** Kiểm tra ghi dữ liệu vào RAM và đọc ngược lại thanh ghi với các giá trị mẫu.
6. **[TEST 6] Branch Instructions:** Kiểm tra cả hai chiều điều kiện rẽ nhánh (Taken và Not-Taken) cho cả số có dấu (`BLT`, `BGE`) và bằng nhau (`BEQ`, `BNE`).
7. **[TEST 7] JUMP (JAL & JALR):** Kiểm tra nhảy không điều kiện, xác thực địa chỉ nhảy và kiểm tra giá trị lưu tại thanh ghi liên kết `ra` (`PC + 4`).
8. **[TEST 8] 4 Boundary Values (Corner Cases):** Kiểm tra tính toàn vẹn phần cứng với 4 giá trị biên kinh điển:
   - `0x00000000` (Zero)
   - `0xFFFFFFFF` (-1 / All Ones)
   - `0x7FFFFFFF` (Max Signed Int)
   - `0x80000000` (Min Signed Int)
   - Kiểm tra hiện tượng tràn số (Wrap-around / Overflow) và so sánh có dấu vs không dấu qua Memory.
9. **[TEST 9] Real Program (Fibonacci Generator):** Nạp một đoạn mã hợp ngữ tạo chuỗi số Fibonacci(7) bằng vòng lặp lưu tuần tự vào bộ nhớ RAM (`0, 1, 1, 2, 3, 5, 8`).

### Kết quả kiểm thử tự động (58/58 Tests Passed)

Toàn bộ 58 kịch bản kiểm thử đều đạt kết quả tuyệt đối trên Vivado XSim:

```text
**********************************************************
*   KHOI CHAY TESTBENCH RUT GON - RISC-V SINGLE-CYCLE    *
**********************************************************

================ [TEST 1] RESET & ZERO REGISTER ================
  [TC #01] [PASS] x0 luon bang 0                  | x 0 = 0x00000000 (0)
  [TC #02] [PASS] x1 nap gia tri 50               | x 1 = 0x00000032 (50)

================ [TEST 2] R-TYPE ALU INSTRUCTIONS ==============
  [TC #03] [PASS] ADD  (10 + 3)                   | x 4 = 0x0000000d (13)
  [TC #04] [PASS] SUB  (10 - 3)                   | x 5 = 0x00000007 (7)
  [TC #05] [PASS] SLL  (10 << 3)                  | x 6 = 0x00000050 (80)
  [TC #06] [PASS] SLT  (-10 < 10)                 | x 7 = 0x00000001 (1)
  [TC #07] [PASS] SLTU (unsigned cmp)             | x 8 = 0x00000000 (0)
  [TC #08] [PASS] XOR  (10 ^ 3)                   | x 9 = 0x00000009 (9)
  [TC #09] [PASS] SRL  (10 >> 3)                  | x10 = 0x00000001 (1)
  [TC #10] [PASS] SRA  (-10 >>> 3)                | x11 = 0xfffffffe (-2)
  [TC #11] [PASS] OR   (10 | 3)                   | x12 = 0x0000000b (11)
  [TC #12] [PASS] AND  (10 & 3)                   | x13 = 0x00000002 (2)

================ [TEST 3] I-TYPE ALU INSTRUCTIONS ==============
  [TC #13] [PASS] ADDI  (16 + (-5))               | x 2 = 0x0000000b (11)
  [TC #14] [PASS] SLTI  (16 < 20)                 | x 3 = 0x00000001 (1)
  [TC #15] [PASS] SLTIU (16 < 10)                 | x 4 = 0x00000000 (0)
  [TC #16] [PASS] XORI  (16 ^ 15)                 | x 5 = 0x0000001f (31)
  [TC #17] [PASS] ORI   (16 | 1)                  | x 6 = 0x00000011 (17)
  [TC #18] [PASS] ANDI  (16 & 16)                 | x 7 = 0x00000010 (16)
  [TC #19] [PASS] SLLI  (16 << 2)                 | x 8 = 0x00000040 (64)
  [TC #20] [PASS] SRLI  (16 >> 2)                 | x 9 = 0x00000004 (4)
  [TC #21] [PASS] SRAI  (16 >>> 2)                | x10 = 0x00000004 (4)

================ [TEST 4] LUI & AUIPC ==========================
  [TC #22] [PASS] LUI   (0x12345000)              | x 1 = 0x12345000 (305418240)
  [TC #23] [PASS] AUIPC (PC + 0x1000)             | x 2 = 0x00001004 (4100)

================ [TEST 5] MEMORY: LW & SW ======================
  [TC #24] [PASS] SW ghi vao RAM[0]               | mem[0] = 0xdeadbeef (-559038737)
  [TC #25] [PASS] SW ghi vao RAM[1]               | mem[1] = 0xcafebabe (-889275714)
  [TC #26] [PASS] LW doc RAM[0]                   | x 3 = 0xdeadbeef (-559038737)
  [TC #27] [PASS] LW doc RAM[1]                   | x 4 = 0xcafebabe (-889275714)

================ [TEST 6] BRANCH INSTRUCTIONS ==================
  [TC #28] [PASS] BEQ (khong re nhay)             | x 3 = 0x00000001 (1)
  [TC #29] [PASS] BNE (re nhay hop le)            | x 4 = 0x00000002 (2)
  [TC #30] [PASS] BLT (re nhay hop le)            | x 5 = 0x00000003 (3)
  [TC #31] [PASS] BGE (khong re nhay)             | x 6 = 0x00000004 (4)

================ [TEST 7] JUMP: JAL & JALR =====================
  [TC #32] [PASS] JAL link register (ra)          | x 1 = 0x00000004 (4)
  [TC #33] [PASS] JAL nhay den dich               | x 2 = 0x0000000a (10)
  [TC #34] [PASS] JALR link register              | x 4 = 0x00000014 (20)
  [TC #35] [PASS] JALR nhay den dich              | x 5 = 0x00000014 (20)

================ [TEST 8] 4 BOUNDARY VALUES (CORNER CASES) ======
  [TC #36] [PASS] MAX_INT + 1 = MIN_INT           | x 6 = 0x80000000 (-2147483648)
  [TC #37] [PASS] MIN_INT - 1 = MAX_INT           | x 7 = 0x7fffffff (2147483647)
  [TC #38] [PASS] 0 - 1 = 0xFFFFFFFF              | x 8 = 0xffffffff (-1)
  [TC #39] [PASS] 0xFFFFFFFF + 1 = 0              | x 9 = 0x00000000 (0)
  [TC #40] [PASS] SLT  (MIN_INT < MAX_INT)        | x10 = 0x00000001 (1)
  [TC #41] [PASS] SLTU (MIN_INT < MAX_INT)        | x11 = 0x00000000 (0)
  [TC #42] [PASS] SLT  (-1 < 0)                   | x12 = 0x00000001 (1)
  [TC #43] [PASS] SLTU (0xFFFFFFFF < 0)           | x13 = 0x00000000 (0)
  [TC #44] [PASS] RAM[0] (0x00000000)             | mem[0] = 0x00000000 (0)
  [TC #45] [PASS] RAM[1] (0xFFFFFFFF)             | mem[1] = 0xffffffff (-1)
  [TC #46] [PASS] RAM[2] (0x7FFFFFFF)             | mem[2] = 0x7fffffff (2147483647)
  [TC #47] [PASS] RAM[3] (0x80000000)             | mem[3] = 0x80000000 (-2147483648)
  [TC #48] [PASS] LW RAM[0] (0x00000000)          | x14 = 0x00000000 (0)
  [TC #49] [PASS] LW RAM[1] (0xFFFFFFFF)          | x15 = 0xffffffff (-1)
  [TC #50] [PASS] LW RAM[2] (0x7FFFFFFF)          | x16 = 0x7fffffff (2147483647)
  [TC #51] [PASS] LW RAM[3] (0x80000000)          | x17 = 0x80000000 (-2147483648)

================ [TEST 9] CHUONG TRINH FIBONACCI ================
  [TC #52] [PASS] Fib[0]                          | mem[0] = 0x00000000 (0)
  [TC #53] [PASS] Fib[1]                          | mem[1] = 0x00000001 (1)
  [TC #54] [PASS] Fib[2]                          | mem[2] = 0x00000001 (1)
  [TC #55] [PASS] Fib[3]                          | mem[3] = 0x00000002 (2)
  [TC #56] [PASS] Fib[4]                          | mem[4] = 0x00000003 (3)
  [TC #57] [PASS] Fib[5]                          | mem[5] = 0x00000005 (5)
  [TC #58] [PASS] Fib[6]                          | mem[6] = 0x00000008 (8)

==========================================================
 TONG KET KET QUA MO PHONG: 58 TEST CASES
   [PASS]: 58
   [FAIL]: 0
 KET LUAN: *** ALL TESTS PASSED! CPU HOAT DONG DUNG ***
==========================================================
```

### Kiểm thử mức khối (Unit Tests)

Thư mục `testbench/unit_tests/` cung cấp 8 testbench độc lập cho từng module con trước khi ghép nối vào hệ thống:
- `tb_alu.sv`: Kiểm tra các phép toán ALU và cờ Zero.
- `tb_alu_decoder.sv`: Kiểm tra các trường hợp giải mã của `ALUOp`.
- `tb_branch_comp.sv`: Kiểm tra logic so sánh nhánh.
- `tb_data_ram.sv`: Kiểm tra ghi đồng bộ và đọc bất đồng bộ RAM.
- `tb_imm_gen.sv`: Kiểm tra mở rộng dấu cho 5 định dạng tức thời.
- `tb_instruction_rom.sv`: Kiểm tra địa chỉ và dữ liệu đọc ra từ ROM.
- `tb_main_decoder.sv`: Kiểm tra bảng tín hiệu điều khiển của từng opcode.
- `tb_pc.sv`: Kiểm tra nạp giá trị PC và reset.
- `tb_regfile.sv`: Kiểm tra 32 thanh ghi và tính bất biến của `x0`.

---

## 7. Hướng dẫn cài đặt và chạy mô phỏng trên Vivado

### Yêu cầu môi trường
- **Hệ điều hành:** Windows 10/11 hoặc Linux.
- **Công cụ:** Xilinx Vivado 2020.1 trở lên (khuyến nghị **Vivado 2022.2**).

### Bước 1: Khởi tạo Project tự động bằng Tcl Script
Mở Vivado Tcl Shell hoặc chạy lệnh sau trong thư mục gốc của repository:
```bash
vivado -mode batch -source create_project.tcl
```
Script sẽ tự động:
1. Tạo thư mục project tại `vivado/RISCV_Single_Cycle.xpr`.
2. Nạp toàn bộ mã nguồn trong `rtl/` và `testbench/`.
3. Cấu hình Top-level thiết kế là `riscv_single_cycle_top`.
4. Cấu hình Top-level mô phỏng là `riscv_single_cycle_tb`.
5. Đặt thời gian mô phỏng tự động `runtime = all`.

### Bước 2: Chạy mô phỏng (Simulation)
Trong giao diện Vivado GUI:
1. Trên thanh **Flow Navigator**, chọn **Run Simulation > Run Behavioral Simulation**.
2. Vivado sẽ tự động biên dịch và chạy mô phỏng cho đến khi gặp `$finish` (~2400ns).
3. Kết quả 58 bài test và bảng tổng kết sẽ in ra trực tiếp tại cửa sổ **Tcl Console**.

---

## 8. Quan sát dạng sóng (Waveform Guide)

- **Hiển thị toàn bộ sóng:** Khi mô phỏng dừng, bấm phím **`F`** (hoặc nút **Zoom Fit** 🔍) để hiển thị toàn bộ dạng sóng từ `0 ns` đến `2400 ns`.
- **Thêm tín hiệu nội bộ CPU để debug:**
  1. Ở bảng **Scope** bên trái, mở `dut` $\rightarrow$ `u_datapath`.
  2. Kéo các tín hiệu sau từ bảng **Objects** vào màn hình Waveform:
     - `pc_current[31:0]`: Địa chỉ lệnh hiện tại đang thực thi.
     - `instruction[31:0]`: Mã máy 32-bit của lệnh.
     - `alu_result[31:0]`: Kết quả tính toán của ALU.
     - `reg_write_data[31:0]`: Dữ liệu chuẩn bị ghi vào thanh ghi.
     - `RegWrite`: Tín hiệu cho phép ghi thanh ghi.
  3. Gõ vào ô **Tcl Console**:
     ```tcl
     restart
     run all
     ```
  4. Nhấn phím **`F`** để xem dạng sóng chạy từng chu kỳ xung nhịp clock tương ứng với từng lệnh assembly.

---

## 9. Lộ trình phát triển

- [x] Thiết kế hoàn chỉnh Single-Cycle Datapath hỗ trợ toàn bộ 37 lệnh số nguyên cơ bản RV32I.
- [x] Xây dựng bộ Unit Test cho 100% module con.
- [x] Xây dựng System-level Testbench tự động với 58 kịch bản kiểm thử (PASS 100%).
- [ ] Bổ sung cơ chế Byte-Enable cho RAM dữ liệu để hỗ trợ đầy đủ các lệnh truy cập byte/half-word lẻ (`LB`, `LH`, `SB`, `SH`).
- [ ] Tách tầng pipeline 5 giai đoạn: **IF - ID - EX - MEM - WB**.
- [ ] Tích hợp **Hazard Detection Unit** và **Forwarding Unit** xử lý Data Hazard và Control Hazard (Branch Penalty).

---

## 10. Tác giả

**Nguyễn Thành Trung** — MSSV: 23119117  
*Khoa Điện tử - Viễn thông / Ngành Kỹ thuật Máy tính*  
*Trường Đại học Sư phạm Kỹ thuật TP.HCM (HCMUTE)*  
*Đồ án Chuyên ngành 2*

[![GitHub](https://img.shields.io/badge/GitHub-thanhchun2005--blip-black?logo=github)](https://github.com/thanhchun2005-blip)
