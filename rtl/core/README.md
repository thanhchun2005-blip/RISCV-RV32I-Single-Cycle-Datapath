# Single-Cycle Datapath — RISC-V RV32I

[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Standard](https://img.shields.io/badge/Standard-IEEE%201800--2017-brightgreen.svg)]()
[![Target ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-red.svg)](https://riscv.org/)
[![Tool](https://img.shields.io/badge/Verified%20with-Vivado%202022.2-orange.svg)]()
[![Stage](https://img.shields.io/badge/Stage-Single--Cycle%20(ISA%20Verification)-yellow.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

Module **`datapath_single_cycle`** là bước đệm kiểm chứng ISA quan trọng trong lộ trình thiết kế vi xử lý RISC-V RV32I 5 tầng pipeline. Nó kết nối toàn bộ **8 module con** đã được kiểm chứng độc lập thành một lõi CPU hoàn chỉnh, thực thi mỗi lệnh trong đúng **1 chu kỳ clock**.

> **Triết lý thiết kế:** Không xây pipeline phức tạp ngay từ đầu. Ghép Single-Cycle trước để xác nhận 100% tính đúng đắn của Datapath và ISA. Sau đó mới chèn thanh ghi pipeline và hazard logic.

---

## 📌 Sơ đồ Kiến trúc Tổng quan

```
                        clk / rst_n
                             |
         +-------------------+-------------------+
         |         datapath_single_cycle          |
         |                                        |
         |  +-------+     +------------+          |
         |  |  PC   |---->| instr_rom  |          |
         |  +-------+     +------------+          |
         |      |               |                 |
         |   pc_current    instruction            |
         |      |          /   |   \              |
         |      |    opcode funct3 funct7         |
         |      |          |   |   |              |
         |  +---+---+  +--------+  +-----------+  |
         |  |  +4  |  | main_  |  | alu_       |  |
         |  | adder |  | decoder|  | decoder    |  |
         |  +-------+  +--------+  +-----------+  |
         |  pc_plus4   ctrl_sigs    alu_control    |
         |                                         |
         |  +---------+   +---------+              |
         |  | reg_file|   | imm_gen |              |
         |  +---------+   +---------+              |
         |  rd1  rd2       immediate               |
         |   |    |            |                   |
         | MUX_A  +--MUX_B----+                   |
         | (AUIPC)|  (ALUSrc)                      |
         | alu_A  alu_B                            |
         |   |    |                                |
         |  +--------+                             |
         |  |ALU_core|                             |
         |  +--------+                             |
         |  alu_result                             |
         |      |          +----------+            |
         |      +--------->| data_ram |            |
         |                 +----------+            |
         |                  ram_read_data          |
         |                       |                 |
         |          +------------+------------+    |
         |          |    WB MUX (3-to-1)      |    |
         |          | jump    -> pc_plus4     |    |
         |          | mem2reg -> ram_read_data|    |
         |          | default -> alu_result   |    |
         |          +-------------------------+    |
         |                write_back_data          |
         |                     |                   |
         |             [reg_file.WriteData]        |
         +----------------------------------------+
```

---

## 🔌 Port Interface

| Port | Direction | Width | Mô tả |
|:-----|:---------:|:-----:|:------|
| `clk` | Input | 1-bit | Clock hệ thống (sườn dương) |
| `rst_n` | Input | 1-bit | Reset bất đồng bộ, tích cực mức thấp |

> Datapath **không có I/O ngoài** ngoài clock và reset. Toàn bộ tín hiệu (instruction bus, register values, control signals) đều là dây nội bộ — đây là thiết kế đúng cho bước kiểm chứng Single-Cycle.

---

## 🧩 Danh sách Module Con được Instantiate

| # | Instance Name | Module | Chức năng |
|:--|:-------------|:-------|:----------|
| 1 | `u_pc` | `pc` | Thanh ghi PC, reset về `0x00000000` |
| 2 | `u_instr_rom` | `instr_rom` | ROM 256 lệnh, đọc bất đồng bộ theo word |
| 3 | `u_main_decoder` | `main_decoder` | Giải mã opcode → 9 tín hiệu điều khiển |
| 4 | `u_regfile` | `reg_file` | Tập 32 thanh ghi; x0 hardwired zero |
| 5 | `u_imm_gen` | `imm_gen` | Sign-extend immediate cho 5 định dạng |
| 6 | `u_alu_decoder` | `alu_decoder` | Giải mã funct3/funct7 → ALUControl 4-bit |
| 7 | `u_alu` | `ALU_core` | ALU tổ hợp 32-bit, 10 phép toán |
| 8 | `u_data_ram` | `data_ram` | RAM 256 word, đọc bất đồng bộ / ghi đồng bộ |

---

## 🔀 Các MUX và Logic Điều khiển

### MUX A — Chọn toán hạng A của ALU

| Điều kiện | `alu_A` | Lệnh áp dụng |
|:----------|:--------|:------------|
| `opcode == 7'b0010111` (AUIPC) | `pc_current` | `AUIPC` |
| Tất cả lệnh khác | `read_data1` (rs1) | R, I, S, B, JAL, JALR, LUI |

```systemverilog
assign alu_A = (opcode == OPCODE_AUIPC) ? pc_current : read_data1;
```

### MUX B — Chọn toán hạng B của ALU

| `ALUSrc` | `alu_B` | Lệnh áp dụng |
|:--------:|:--------|:------------|
| `0` | `read_data2` (rs2) | R-type |
| `1` | `immediate` | I, S, B, U, J-type |

```systemverilog
assign alu_B = alu_src ? immediate : read_data2;
```

### WB MUX (3-to-1) — Chọn dữ liệu Write-Back

| Điều kiện | `write_back_data` | Lệnh áp dụng |
|:----------|:-----------------|:------------|
| `jump == 1` | `pc_plus4` | `JAL`, `JALR` (ghi địa chỉ trả về) |
| `mem_to_reg == 1` | `ram_read_data` | `LW`, `LH`, `LB`, `LHU`, `LBU` |
| Mặc định | `alu_result` | R-type, I-type ALU, `LUI`, `AUIPC` |

```systemverilog
assign write_back_data = jump       ? pc_plus4      :
                         mem_to_reg ? ram_read_data  :
                                      alu_result;
```

### PC Next Logic (phiên bản Single-Cycle)

```systemverilog
// Hiện tại: PC luôn tăng +4 (tuần tự)
// Branch/Jump sẽ được tích hợp ở bước Pipeline
assign pc_next = pc_current + 32'd4;
```

> ⚠️ **Lưu ý phiên bản:** Branch taken và Jump target chưa được xử lý ở giai đoạn này. Đây là quyết định có chủ đích để kiểm chứng logic ALU và datapath trước.

---

## 📋 Bảng Hỗ trợ Lệnh RV32I

| Nhóm | Lệnh | Hỗ trợ | Ghi chú |
|:-----|:-----|:------:|:--------|
| **R-type** | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU | ✅ | Đầy đủ |
| **I-type ALU** | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | ✅ | Đầy đủ |
| **Load** | LW, LH, LB, LHU, LBU | ✅ | Word-aligned (giai đoạn này) |
| **Store** | SW, SH, SB | ✅ | Word-aligned (giai đoạn này) |
| **Branch** | BEQ, BNE, BLT, BGE, BLTU, BGEU | ⚠️ | Decode OK, PC không nhảy |
| **Jump** | JAL | ⚠️ | WB ghi PC+4 đúng, PC không nhảy |
| **Jump** | JALR | ⚠️ | WB ghi PC+4 đúng, PC không nhảy |
| **Upper** | LUI | ✅ | Đầy đủ |
| **Upper** | AUIPC | ✅ | alu_A = PC, kết quả đúng |

---

## ⚠️ Ghi chú Thiết kế Quan trọng

### 1. Xung đột cực Reset (`rst` vs `rst_n`)
Module `reg_file` sử dụng reset **active-high** (`rst`), trong khi các module còn lại dùng **active-low** (`rst_n`). Datapath xử lý bằng cách đảo tín hiệu:

```systemverilog
reg_file u_regfile (
    .rst(~rst_n),   // Đảo cực: rst_n active-low → rst active-high
    ...
);
```

### 2. Phát hiện AUIPC bằng Opcode trực tiếp
Thay vì thêm port `ALUSrcA` vào `main_decoder`, datapath phát hiện AUIPC bằng cách so sánh opcode trực tiếp trong mạch tổ hợp. Cách này không yêu cầu sửa đổi module `main_decoder`.

---

## 📁 Cấu trúc Thư mục (trong project tổng)

```
Do_An_2/
├── rtl/
│   ├── core/
│   │   ├── datapath_single_cycle.sv  ← file này
│   │   ├── pc.sv
│   │   ├── regfile.sv
│   │   ├── imm_gen.sv
│   │   ├── alu.sv
│   │   ├── alu_decoder.sv
│   │   └── main_decoder.sv
│   └── memory/
│       ├── instruction_rom.sv
│       └── data_ram.sv
├── testbench/
│   └── cpu_tests/
│       └── tb_single_cycle.sv        ← testbench tích hợp
└── software/
    └── asm/
        └── single_cycle_test.s       ← chương trình kiểm thử
```

---

## 🔗 Module liên quan trong series RISC-V RV32I

| Module | GitHub Repository |
|:-------|:-----------------|
| ALU 32-bit | [RISCV-RV32I-ALU](https://github.com/thanhchun2005-blip/RISCV-RV32I-ALU) |
| ALU Decoder | [RISCV-RV32I-ALU-Decoder](https://github.com/thanhchun2005-blip/RISCV-RV32I-ALU-Decoder) |
| Immediate Generator | [RISCV-RV32I-Immediate-Generator](https://github.com/thanhchun2005-blip/RISCV-RV32I-Immediate-Generator) |
| Main Decoder | [RISCV-RV32I-Main-Decoder](https://github.com/thanhchun2005-blip/RISCV-RV32I-Main-Decoder) |
| Register File | [RISCV-RV32I-Register-File](https://github.com/thanhchun2005-blip/RISCV-RV32I-Register-File) |
| Program Counter | [RISCV-RV32I-Program-Counter](https://github.com/thanhchun2005-blip/RISCV-RV32I-Program-Counter) |
| Instruction ROM | [RISCV-RV32I-Instruction-ROM](https://github.com/thanhchun2005-blip/RISCV-RV32I-Instruction-ROM) |
| Data RAM | [RISCV-RV32I-Data-RAM](https://github.com/thanhchun2005-blip/RISCV-RV32I-Data-RAM) |

---

## 👤 Thông tin Tác giả

**Nguyễn Thành Trung** — MSSV: 23119117  
Ngành Kỹ thuật Máy tính — Đồ án Môn học 2  
*Thiết kế, kiểm chứng và triển khai FPGA lõi vi xử lý RISC-V RV32I 32-bit pipeline 5 tầng*

[![GitHub](https://img.shields.io/badge/GitHub-thanhchun2005--blip-black?logo=github)](https://github.com/thanhchun2005-blip)
