# RISC-V RV32I Single-Cycle CPU

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-red.svg)
![Tool](https://img.shields.io/badge/Vivado-2022.2-orange.svg)
![Stage](https://img.shields.io/badge/Stage-Single--Cycle-yellow.svg)

Lõi vi xử lý **RISC-V RV32I 32-bit** kiến trúc **Single-Cycle** (mỗi lệnh thực thi trong đúng 1 chu kỳ clock), viết bằng SystemVerilog và mô phỏng bằng Vivado.

Đây là bước đệm kiểm chứng ISA trong lộ trình đồ án *"Thiết kế, kiểm chứng và triển khai FPGA lõi vi xử lý RISC-V RV32I 5 tầng pipeline"*. Datapath được xác nhận đúng ở dạng Single-Cycle trước, sau đó mới chèn thanh ghi pipeline và hazard logic.

---

## Mục lục

1. [Cấu trúc repo](#1-cấu-trúc-repo)
2. [Kiến trúc tổng quan](#2-kiến-trúc-tổng-quan)
3. [Danh sách module](#3-danh-sách-module)
4. [Luồng dữ liệu và các MUX](#4-luồng-dữ-liệu-và-các-mux)
5. [Logic chọn PC kế tiếp](#5-logic-chọn-pc-kế-tiếp)
6. [Lệnh RV32I được hỗ trợ](#6-lệnh-rv32i-được-hỗ-trợ)
7. [Hướng dẫn chạy mô phỏng với Vivado](#7-hướng-dẫn-chạy-mô-phỏng-với-vivado)
8. [Testbench](#8-testbench)
9. [Ghi chú thiết kế](#9-ghi-chú-thiết-kế)
10. [Hạn chế và hướng phát triển](#10-hạn-chế-và-hướng-phát-triển)
11. [Tác giả](#11-tác-giả)

---

## 1. Cấu trúc repo

```
.
├── rtl/
│   ├── core/
│   │   ├── riscv_single_cycle_top.sv     # Top-level (clk, rst_n) bọc datapath
│   │   ├── datapath_single_cycle.sv      # Datapath: nối toàn bộ module con
│   │   ├── pc.sv                         # Thanh ghi Program Counter
│   │   ├── regfile.sv                    # 32 thanh ghi, x0 = 0
│   │   ├── imm_gen.sv                    # Sinh immediate I/S/B/U/J
│   │   ├── main_decoder.sv               # Opcode -> tín hiệu điều khiển
│   │   ├── alu_decoder.sv                # ALUOp/funct3/funct7 -> ALUControl
│   │   ├── alu.sv                        # ALU 32-bit (module ALU_core)
│   │   └── branch_comp.sv                # So sánh nhánh (BEQ/BNE/BLT/BGE/BLTU/BGEU)
│   └── memory/
│       ├── instruction_rom.sv            # ROM lệnh (module instr_rom)
│       └── data_ram.sv                   # RAM dữ liệu
├── testbench/
│   └── unit_tests/
│       ├── tb_alu.sv
│       ├── tb_alu_decoder.sv
│       ├── tb_data_ram.sv
│       ├── tb_imm_gen.sv
│       ├── tb_instruction_rom.sv
│       ├── tb_main_decoder.sv
│       ├── tb_pc.sv
│       └── tb_regfile.sv
├── create_project.tcl                    # Tạo project Vivado tự động
└── README.md
```

> Tên file và tên module không phải lúc nào cũng trùng nhau: `alu.sv` chứa `ALU_core`, `regfile.sv` chứa `reg_file`, `instruction_rom.sv` chứa `instr_rom`.

---

## 2. Kiến trúc tổng quan

```
                       clk / rst_n
                            |
        +-------------------+--------------------+
        |           datapath_single_cycle         |
        |                                         |
        |  +----+  pc   +-----------+             |
        |  | PC |------>| instr_rom |             |
        |  +----+       +-----------+             |
        |    ^               | instruction        |
        |    |        +------+-------+            |
        |  pc_next    |      |       |            |
        |    |   +----------+  +---------+  +----------+
        |    |   |main_dec. |  | reg_file|  | imm_gen  |
        |    |   +----------+  +---------+  +----------+
        |    |     ctrl         rd1   rd2     immediate
        |    |       |           |     |          |
        |    |   +-----------+   |   MUX B <------+
        |    |   |alu_decoder|   |   (ALUSrc)
        |    |   +-----------+   |     |
        |    |       |        MUX A    |
        |    |       |      (AUIPC/LUI)|
        |    |       |           |     |
        |    |   +--------------------------+
        |    |   |         ALU_core         |
        |    |   +--------------------------+
        |    |            | alu_result
        |    |            +------------> +----------+
        |    |                           | data_ram |
        |    |                           +----------+
        |    |                                | ram_read_data
        |    |         +----------------------+
        |    |         |   WB MUX (3-to-1)
        |    |         |  jump->PC+4 / load->RAM / else->ALU
        |    |         +--> reg_file.WriteData
        |    |
        |  +-------------+    +--------------+
        +--| PC next MUX |<---| branch_comp  |
           +-------------+    +--------------+
```

### Cổng giao tiếp

| Cổng | Hướng | Độ rộng | Mô tả |
|:-----|:-----:|:-------:|:------|
| `clk` | Input | 1 | Clock hệ thống, sườn dương |
| `rst_n` | Input | 1 | Reset tích cực mức thấp |

Top-level không có I/O ngoài clock và reset. Bus lệnh, giá trị thanh ghi và tín hiệu điều khiển đều là dây nội bộ, phù hợp cho giai đoạn kiểm chứng ISA bằng mô phỏng.

---

## 3. Danh sách module

Các module được khởi tạo trong `datapath_single_cycle`:

| Instance | Module | File | Chức năng |
|:---------|:-------|:-----|:----------|
| `u_pc` | `pc` | `rtl/core/pc.sv` | Thanh ghi PC, reset về `0x00000000` |
| `u_instr_rom` | `instr_rom` | `rtl/memory/instruction_rom.sv` | ROM 256 lệnh (tham số `DEPTH`), đọc tổ hợp theo word, mặc định NOP |
| `u_main_decoder` | `main_decoder` | `rtl/core/main_decoder.sv` | Giải mã opcode ra `RegWrite`, `MemWrite`, `ALUSrc`, `MemToReg`, `Branch`, `Jump`, `ImmSrc`, `ALUOp`, `Illegal` |
| `u_regfile` | `reg_file` | `rtl/core/regfile.sv` | 32 thanh ghi, 2 cổng đọc, 1 cổng ghi, x0 luôn bằng 0 |
| `u_imm_gen` | `imm_gen` | `rtl/core/imm_gen.sv` | Trích xuất và mở rộng dấu immediate I, S, B, U, J |
| `u_alu_decoder` | `alu_decoder` | `rtl/core/alu_decoder.sv` | Giải mã `ALUOp` + `funct3` + `funct7` thành `ALUControl` 4 bit |
| `u_alu` | `ALU_core` | `rtl/core/alu.sv` | ALU tổ hợp 32-bit, 10 phép toán |
| `u_branch_comp` | `branch_comp` | `rtl/core/branch_comp.sv` | Tạo `branch_taken` theo `funct3` |
| `u_data_ram` | `data_ram` | `rtl/memory/data_ram.sv` | RAM dữ liệu, ghi đồng bộ, đọc bất đồng bộ |

Module bao ngoài: `riscv_single_cycle_top` chỉ khởi tạo `datapath_single_cycle`.

### `branch_comp`

| `funct3` | Lệnh | Điều kiện |
|:--------:|:-----|:----------|
| `000` | BEQ | `op_a == op_b` |
| `001` | BNE | `op_a != op_b` |
| `100` | BLT | `$signed(op_a) < $signed(op_b)` |
| `101` | BGE | `$signed(op_a) >= $signed(op_b)` |
| `110` | BLTU | `op_a < op_b` (không dấu) |
| `111` | BGEU | `op_a >= op_b` (không dấu) |

`branch_taken` chỉ bằng 1 khi tín hiệu `Branch` từ main decoder bằng 1.

---

## 4. Luồng dữ liệu và các MUX

### MUX A: toán hạng A của ALU

| Điều kiện | `alu_A` | Lệnh |
|:----------|:--------|:-----|
| `opcode == AUIPC` | `pc_current` | AUIPC |
| `opcode == LUI` | `0` | LUI |
| Còn lại | `read_data1` (rs1) | R, I, S, B, JAL, JALR |

```systemverilog
assign alu_A = (opcode == OPCODE_AUIPC) ? pc_current :
               (opcode == OPCODE_LUI)   ? 32'd0      :
                                          read_data1;
```

### MUX B: toán hạng B của ALU

| `ALUSrc` | `alu_B` | Lệnh |
|:--------:|:--------|:-----|
| `0` | `read_data2` (rs2) | R-type |
| `1` | `immediate` | I, S, B, U, J |

### WB MUX: dữ liệu ghi về thanh ghi

Mức ưu tiên: `jump` > `mem_to_reg` > `alu_result`.

| Điều kiện | `write_back_data` | Lệnh |
|:----------|:------------------|:-----|
| `jump == 1` | `pc_plus4` | JAL, JALR (ghi địa chỉ trả về) |
| `mem_to_reg == 1` | `ram_read_data` | Lệnh load |
| Còn lại | `alu_result` | R-type, I-type ALU, LUI, AUIPC |

---

## 5. Logic chọn PC kế tiếp

```systemverilog
pc_plus4  = pc_current + 4;
pc_branch = pc_current + immediate;                    // Branch và JAL
pc_jalr   = (read_data1 + immediate) & ~32'd1;         // JALR, xoá bit 0

if      (jump && opcode == JALR) pc_next = pc_jalr;
else if (jump && opcode == JAL)  pc_next = pc_branch;
else if (branch_taken)           pc_next = pc_branch;
else                             pc_next = pc_plus4;
```

| Trường hợp | `pc_next` |
|:-----------|:----------|
| JALR | `(rs1 + imm) & ~1` |
| JAL | `PC + imm` |
| Branch được thực hiện | `PC + imm` |
| Còn lại | `PC + 4` |

---

## 6. Lệnh RV32I được hỗ trợ

| Nhóm | Lệnh | Ghi chú |
|:-----|:-----|:--------|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU | Đầy đủ |
| I-type ALU | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | Đầy đủ |
| Load | LW, LH, LB, LHU, LBU | Xem [mục 10](#10-hạn-chế-và-hướng-phát-triển) |
| Store | SW, SH, SB | Xem [mục 10](#10-hạn-chế-và-hướng-phát-triển) |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU | PC nhảy qua `branch_comp` |
| Jump | JAL, JALR | PC nhảy, ghi `PC+4` vào rd |
| Upper | LUI, AUIPC | `LUI`: A = 0; `AUIPC`: A = PC |

---

## 7. Hướng dẫn chạy mô phỏng với Vivado

**Yêu cầu:** Vivado 2022.2 (các bản gần đó cũng dùng được).

### Cách 1: dùng script (khuyến nghị)

```bash
vivado -mode batch -source create_project.tcl
```

Hoặc trong Vivado: **Tools > Run Tcl Script...** rồi chọn `create_project.tcl`.

Script tạo project `vivado/RISCV_Single_Cycle.xpr`:

- Design sources: toàn bộ `rtl/core/*.sv` và `rtl/memory/*.sv`, top là `riscv_single_cycle_top`.
- Simulation sources: toàn bộ `testbench/unit_tests/*.sv`, top mặc định là `ALU_tb`.
- Chip mặc định `xc7a35tcpg236-1` (Basys3). Nếu dùng board khác, sửa tham số `-part` trong script.

File nguồn được tham chiếu tại chỗ, nên sửa file trong `rtl/` hoặc `testbench/` là Vivado thấy ngay.

### Cách 2: tạo project thủ công

1. **File > Project > New**, chọn RTL Project.
2. **Add Sources > Add or create design sources**: thêm `rtl/core/*.sv` và `rtl/memory/*.sv`.
3. **Add or create simulation sources**: thêm `testbench/unit_tests/*.sv`.
4. Chọn đúng file type là **SystemVerilog**.

### Chạy một testbench

1. Trong **Simulation Sources**, bấm chuột phải vào testbench cần chạy, chọn **Set as Top**.
2. Bấm **Run Simulation > Run Behavioral Simulation**.

---

## 8. Testbench

| File | Module top | Kiểm tra |
|:-----|:-----------|:---------|
| `tb_alu.sv` | `ALU_tb` | Các phép toán ALU và giá trị biên |
| `tb_alu_decoder.sv` | `alu_decoder_tb` | Giải mã `ALUControl` |
| `tb_data_ram.sv` | `data_ram_tb` | Đọc và ghi RAM |
| `tb_imm_gen.sv` | `Imm_gen_tb` | Mở rộng immediate theo định dạng |
| `tb_instruction_rom.sv` | `instr_rom_tb` | Đọc ROM theo địa chỉ |
| `tb_main_decoder.sv` | `main_decoder_tb` | Tín hiệu điều khiển theo opcode |
| `tb_pc.sv` | `pc_tb` | Reset và cập nhật PC |
| `tb_regfile.sv` | `reg_file_tb` | Đọc/ghi và x0 luôn bằng 0 |

Hiện mới có kiểm thử mức module. Chưa có testbench mức CPU và chưa có chương trình `.hex`.

---

## 9. Ghi chú thiết kế

- **Reset:** toàn bộ CPU dùng reset tích cực mức thấp `rst_n`, và datapath nối `rst_n` trực tiếp vào cổng `rst` của `reg_file`. Khi sửa `reg_file`, cần giữ đúng cực này.
- **AUIPC và LUI:** datapath nhận diện hai lệnh này bằng opcode ngay tại MUX A, nên `main_decoder` không cần thêm cổng `ALUSrcA`.
- **ROM mặc định:** mọi ô ROM khởi tạo là NOP (`32'h00000013`). Địa chỉ ngoài vùng ROM cũng trả về NOP. Để nạp chương trình, mở dòng `$readmemh("program.hex", rom)` trong `instruction_rom.sv`.
- **Tên module:** `ALU_core`, `reg_file`, `instr_rom` khác tên file. Chú ý khi thêm testbench hoặc instance mới.

---

## 10. Hạn chế và hướng phát triển

- Data RAM hiện truy cập theo word. Các lệnh SB/SH/LB/LH/LBU/LHU được giải mã đúng nhưng chưa có byte-enable đầy đủ.
- Chưa có testbench mức CPU và chương trình kiểm thử (`software/`, `.hex`).
- Bước tiếp theo: tạo `tb_single_cycle.sv`, viết chương trình assembly kiểm thử, rồi tách tầng pipeline 5 giai đoạn kèm forwarding và hazard detection.

---

## 11. Tác giả

**Nguyễn Thành Trung**
Ngành Kỹ thuật Máy tính, Đồ án Môn học 2

[![GitHub](https://img.shields.io/badge/GitHub-thanhchun2005--blip-black?logo=github)](https://github.com/thanhchun2005-blip)
