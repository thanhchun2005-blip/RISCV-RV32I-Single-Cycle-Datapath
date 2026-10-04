# ĐẶC TẢ THIẾT KẾ KỸ THUẬT (TECHNICAL IMPLEMENTATION SPECIFICATION)

**Học phần:** Đồ án Môn học 2 (Capstone Project II) – Ngành Kỹ thuật Máy tính  
**Sinh viên thực hiện:** Nguyễn Thành Trung (MSSV: **23119117**)  
**Tên đề tài:** Thiết kế, kiểm chứng và triển khai FPGA lõi vi xử lý RISC-V RV32I 32-bit pipeline 5 tầng ở mức RTL bằng SystemVerilog  

---

## 1. TỔNG QUAN HỆ THỐNG (SYSTEM OVERVIEW)

### 1.1. Bài toán đặt ra và Phạm vi đề tài
- **Mục tiêu chính:** Thiết kế, mô phỏng kiểm chứng tự động và tổng hợp/triển khai trên FPGA một lõi vi xử lý RISC-V 32-bit ở mức Register Transfer Level (RTL) bằng ngôn ngữ **SystemVerilog** (chuẩn IEEE 1800-2012/2017).
- **Kiến trúc tập lệnh (ISA):** Tập lệnh cơ sở RV32I (32-bit, little-endian) gồm 37 lệnh chuẩn thuộc phạm vi đề tài.
- **Kiến trúc vi xử lý:** Pipeline 5 tầng kinh điển: **IF (Instruction Fetch) → ID (Instruction Decode) → EX (Execute) → MEM (Memory Access) → WB (Write Back)** theo mô hình *in-order, single-issue* (tối đa 1 instruction mới đi vào pipeline mỗi chu kỳ clock khi không bị stall).
- **Kiến trúc bộ nhớ:** Kiến trúc Harvard tách rời bộ nhớ lệnh (**Instruction ROM**) và bộ nhớ dữ liệu (**Data RAM**) nhằm triệt tiêu xung đột cấu trúc (structural hazard) khi truy xuất đồng thời ở tầng IF và MEM.
- **Cơ chế xử lý Hazard:**
  - **Data Hazard (RAW):** Xử lý triệt để xung đột Read-After-Write bằng khối chuyển tiếp dữ liệu (**Forwarding Unit**) từ các tầng EX/MEM và MEM/WB về tầng EX mà không gây stall dư thừa; xử lý trường hợp xung đột đặc biệt **Load-Use** bằng khối phát hiện xung đột (**Hazard Detection Unit**) tạo interlock/stall 1 chu kỳ clock và chèn 1 bubble vào pipeline.
  - **Control Hazard (Branch & Jump):** Áp dụng chiến lược dự đoán tĩnh **Predict Not-Taken**. Khi nhánh rẽ được thực thi (Taken) hoặc gặp lệnh nhảy không điều kiện (`JAL`, `JALR`), toàn bộ các lệnh nạp sai trên wrong-path (tại IF/ID và ID/EX) sẽ bị **Flush** trước khi thay đổi trạng thái kiến trúc. Đo đạc và báo cáo chi phí phạt rẽ nhánh (branch penalty = 2 chu kỳ).
- **Môi trường kiểm chứng (Verification):** Không chỉ dựa vào quan sát dạng sóng (waveform) thủ công mà tập trung xây dựng môi trường kiểm chứng tự động cấp độ CPU (**Self-Checking Testbench**) với cơ chế so sánh trạng thái kiến trúc (Architectural State / Memory Signature), tích hợp bộ **SystemVerilog Assertions (SVA)** và mô hình **Functional Coverage** (mục tiêu đạt tối thiểu 90%).
- **Hiện thực phần cứng (Synthesis & FPGA Validation):** Thiết kế RTL đảm bảo synthesizable 100%, không phát sinh latch ngoài chủ ý, tổng hợp trên công cụ EDA (Vivado hoặc Quartus) để trích xuất báo cáo tài nguyên phần cứng (LUT, FF, BRAM, Critical Path, $F_{max}$) và nạp lên board FPGA kiểm chứng thông qua giao tiếp hiển thị (UART, LED, LED 7 đoạn hoặc Memory-Mapped IO).

---

### 1.2. Cấu trúc Thư mục Dự án Chuẩn Công nghiệp

```
riscv32i_5stage_pipeline/
├── docs/                               # Tài liệu thiết kế và đặc tả kiến trúc
│   ├── implementation.md               # Đặc tả kỹ thuật chi tiết toàn diện (file này)
│   ├── tien_do_do_an.md                # Kế hoạch tiến độ thực hiện chi tiết trong 14 tuần
│   └── diagrams/                       # Sơ đồ khối datapath, sơ đồ pipeline, sơ đồ forwarding
├── rtl/                                # Mã nguồn phần cứng SystemVerilog (Synthesizable RTL)
│   ├── include/
│   │   └── rv32i_pkg.sv                # Package định nghĩa opcode, funct3, funct7, alu_op, types
│   ├── core/
│   │   ├── riscv_core_top.sv           # Top-level kết nối Datapath, Control Unit và Hazard Units
│   │   ├── datapath.sv                 # Khối ghép nối luồng dữ liệu 5 tầng
│   │   ├── control_unit.sv             # Bộ điều khiển chính (Main Decoder + ALU Decoder)
│   │   ├── alu.sv                      # Bộ tính toán số học, logic và dịch bit 32-bit
│   │   ├── regfile.sv                  # Tập 32 thanh ghi 32-bit (x0 hardwired to 0)
│   │   ├── imm_gen.sv                  # Bộ trích xuất và mở rộng tức thời (I, S, B, U, J)
│   │   ├── branch_comp.sv              # Bộ so sánh rẽ nhánh (Signed & Unsigned)
│   │   ├── forwarding_unit.sv          # Khối xử lý chuyển tiếp dữ liệu (EX & MEM Hazard)
│   │   └── hazard_detection_unit.sv    # Khối phát hiện xung đột Load-Use (Stall & Bubble)
│   ├── pipeline_regs/
│   │   ├── pipe_reg_if_id.sv           # Thanh ghi trung gian tầng IF/ID (hỗ trợ Stall & Flush)
│   │   ├── pipe_reg_id_ex.sv           # Thanh ghi trung gian tầng ID/EX (hỗ trợ Flush)
│   │   ├── pipe_reg_ex_mem.sv          # Thanh ghi trung gian tầng EX/MEM
│   │   └── pipe_reg_mem_wb.sv          # Thanh ghi trung gian tầng MEM/WB
│   ├── memory/
│   │   ├── instruction_rom.sv          # Bộ nhớ lệnh ROM (đọc đồng bộ/bất đồng bộ, nạp .hex)
│   │   └── data_ram.sv                 # Bộ nhớ dữ liệu RAM (hỗ trợ byte-enable SB/SH/SW, load sign/zero)
│   └── fpga/
│       ├── fpga_top.sv                 # Top-level bọc riscv_core_top để giao tiếp chân vật lý FPGA
│       ├── uart_tx.sv                  # Khối UART truyền dữ liệu kết quả kiểm thử lên PC
│       └── hex_display.sv              # Bộ giải mã LED 7 đoạn hiển thị PC/thanh ghi
├── testbench/                          # Môi trường kiểm chứng SystemVerilog (Simulation Only)
│   ├── unit_tests/
│   │   ├── tb_alu.sv                   # Testbench tự kiểm tra đơn vị ALU (biên signed/unsigned)
│   │   ├── tb_regfile.sv               # Testbench kiểm tra đọc/ghi và tính bất biến của x0
│   │   ├── tb_imm_gen.sv               # Testbench kiểm tra mở rộng 5 định dạng tức thời
│   │   ├── tb_decoder.sv               # Testbench kiểm tra bảng chân trị giải mã điều khiển
│   │   ├── tb_forwarding.sv            # Testbench kiểm tra chuyển tiếp và mức ưu tiên
│   │   └── tb_hazard.sv                # Testbench kiểm tra stall load-use và flush
│   ├── cpu_tests/
│   │   ├── tb_cpu_top.sv               # Self-checking Testbench cấp độ CPU hoàn chỉnh
│   │   └── reference_model.sv          # Mô hình tham chiếu kiến trúc để so sánh Signature
│   └── coverage/
│       └── riscv_coverage.sv           # Functional Coverage covergroups cho ISA, Hazards, Branches
├── assertions/
│   └── riscv_sva.sv                    # Bộ 8 SystemVerilog Assertions (SVA) kiểm tra invariant
├── software/                           # Phần mềm và chương trình kiểm thử Assembly/C
│   ├── asm/
│   │   ├── directed_tests/             # Các bài test định hướng theo từng nhóm lệnh
│   │   ├── hazard_stress_tests/        # Các bài test RAW chains, load-use, loop branch
│   │   ├── boundary_tests/             # Các bài test giá trị biên (0x0, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000)
│   │   └── applications/               # Ứng dụng: fibonacci.s, bubble_sort.s
│   ├── hex/                            # Mã máy nhị phân (.hex/.mem) nạp vào ROM/RAM
│   └── scripts/
│       ├── assemble.py                 # Script Python hoặc Makefile dịch mã nguồn ra file .hex
│       └── check_signature.py          # Script đối chiếu memory dump sau mô phỏng
└── sim/                                # Script chạy mô phỏng và cấu hình waveform
    ├── run_sim.do                      # Script tự động compile, simulate và dump coverage
    └── wave.do                         # Cấu hình hiển thị tín hiệu dạng sóng trực quan
```

---

## 2. ĐẶC TẢ TẬP LỆNH ISA RV32I & GIỚI HẠN THIẾT KẾ

Lõi vi xử lý hỗ trợ đầy đủ **37 lệnh chuẩn** của tập lệnh cơ sở RV32I theo tài liệu đặc tả kỹ thuật:

| Định dạng | Nhóm lệnh | Danh sách lệnh hỗ trợ (37 lệnh) | Chi tiết trường bit mã hóa lệnh |
| :--- | :--- | :--- | :--- |
| **R-type** | Số học & Logic (thanh ghi) | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | `funct7[31:25]` \| `rs2[24:20]` \| `rs1[19:15]` \| `funct3[14:12]` \| `rd[11:7]` \| `opcode[6:0]` |
| **I-type** | Số học & Logic tức thời | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | `imm[31:20]` \| `rs1[19:15]` \| `funct3[14:12]` \| `rd[11:7]` \| `opcode[6:0]` |
| **I-type** | Nạp dữ liệu (Load) | `LB`, `LH`, `LW`, `LBU`, `LHU` | `imm[31:20]` \| `rs1[19:15]` \| `funct3[14:12]` \| `rd[11:7]` \| `opcode[6:0]` |
| **I-type** | Nhảy gián tiếp thanh ghi | `JALR` | `imm[31:20]` \| `rs1[19:15]` \| `funct3[14:12]` \| `rd[11:7]` \| `opcode[6:0]` |
| **S-type** | Lưu dữ liệu (Store) | `SB`, `SH`, `SW` | `imm[31:25]` \| `rs2[24:20]` \| `rs1[19:15]` \| `funct3[14:12]` \| `imm[4:0]` \| `opcode[6:0]` |
| **B-type** | Rẽ nhánh có điều kiện | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | `imm[12\|10:5]` \| `rs2[24:20]` \| `rs1[19:15]` \| `funct3[14:12]` \| `imm[4:1\|11]` \| `opcode[6:0]` |
| **U-type** | Nạp tức thời phần cao | `LUI`, `AUIPC` | `imm[31:12]` \| `rd[11:7]` \| `opcode[6:0]` |
| **J-type** | Nhảy trực tiếp không điều kiện | `JAL` | `imm[20\|10:1\|11\|19:12]` \| `rd[11:7]` \| `opcode[6:0]` |

### Quy tắc Kiến trúc và Giới hạn Thiết kế
1. **Tính bất biến của thanh ghi `x0`:** Thanh ghi kiến trúc `x0` bị cố định cứng bằng 0 (hardwired-to-zero). Mọi thao tác ghi dữ liệu vào `x0` phải bị triệt tiêu, và giá trị đọc ra từ `x0` luôn luôn là `32'h0000_0000`.
2. **Xử lý lệnh không hợp lệ (Illegal/Unsupported Instructions):** 
   - Bộ giải mã `control_unit.sv` phải nhận diện các mã lệnh nằm ngoài 37 lệnh quy định hoặc có opcode/funct không hợp lệ.
   - Khi phát hiện lệnh không hợp lệ: Tất cả các tín hiệu điều khiển có khả năng thay đổi trạng thái kiến trúc (`reg_write`, `mem_write`, `branch`, `jump`) đều phải bị vô hiệu hóa (`= 0`), đảm bảo lệnh không hợp lệ hoạt động tương đương lệnh NOP an toàn và không làm sai lệch trạng thái vi xử lý.
3. **Phạm vi không thuộc đề tài:** Các chức năng đặc quyền (Privilege modes: User/Supervisor/Machine), ngắt (Interrupts) và ngoại lệ (Exceptions), tập thanh ghi điều khiển trạng thái (CSR), bộ quản lý bộ nhớ (MMU), bộ nhớ đệm (Cache) và các phần mở rộng phần cứng như RV32M (nhân/chia) hoặc RV32C (lệnh nén 16-bit) không thuộc phạm vi bắt buộc của đề tài này.

---

## 3. ĐẶC TẢ 7 CHỨC NĂNG CHI TIẾT CỦA HỆ THỐNG

```
===================================================================================================
                                      SƠ ĐỒ TỔNG THỂ PIPELINE 5 TẦNG
===================================================================================================

       +-----------------------------------------------------------------------------------+
       |                            HAZARD DETECTION UNIT                                  |
       |  - Kiểm tra Load-Use: (mem_read_ex && (rd_ex == rs1_id || rd_ex == rs2_id))       |
       |  - Tín hiệu sinh ra: pc_write_en, if_id_write_en, id_ex_flush (Bubble)            |
       +-------+-----------------------------+-----------------------------+---------------+
               |                             |                             |
               v                             v                             v
         +-----------+                 +-----------+                 +-----------+
         |  IF STAGE |                 |  ID STAGE |                 |  EX STAGE |
         +-----------+                 +-----------+                 +-----------+
         |   PC Reg  |                 |  RegFile  |                 |  ALU Mux  |
         |     |     |                 |  (32x32)  |                 |     |     |
         |     v     |                 |     |     |                 |     v     |
         | Instr ROM |===[ IF/ID ]====>|  Imm Gen  |===[ ID/EX ]====>| 32-bit ALU|
         +-----------+   Reg (Hold/    |     |     |   Reg (Flush    |     |     |
               ^          Flush)       |  Control  |    Bubble)      | BranchUnit|
               |                       +-----------+                 +-----+-----+
               |                             ^                             |
               |                             |                             v
               |                             |                  [Branch Taken/Target]
               |                             |                             |
               +-----------------------------+-----------------------------+
                                      Branch Flush (2 chu kỳ)
                                             |
                                             v
         +------------+                 +------------+
         |  MEM STAGE |                 |  WB STAGE  |
         +------------+                 +------------+
         |  Data RAM  |                 |  WB Mux    |
         | (Byte/Half/|===[ EX/MEM ]===>| (ALU/Data/ |===[ MEM/WB ]===> [RegFile]
         |  Word En)  |    Reg          |    PC+4)   |     Reg          (Write Back)
         +------------+                 +------------+
               |                              |
               +------------+-----------------+
                            |
                            v
               +-------------------------+
               |     FORWARDING UNIT     |
               | EX Hazard:  EX/MEM -> EX|
               | MEM Hazard: MEM/WB -> EX|
               | Ràng buộc:  rd != x0    |
               +-------------------------+
===================================================================================================
```

---

### Chức năng 1 – Instruction Execution (Thực thi Tập lệnh)

1. **Bộ nạp và giải mã lệnh (Fetch & Decode):**
   - Lệnh 32-bit được nạp từ `instruction_rom` tại địa chỉ PC và chuyển sang tầng ID qua thanh ghi `pipe_reg_if_id`.
   - Khối `control_unit.sv` thực hiện giải mã trường bit:
     - `opcode = instr[6:0]`
     - `rd = instr[11:7]`
     - `funct3 = instr[14:12]`
     - `rs1 = instr[19:15]`
     - `rs2 = instr[24:20]`
     - `funct7 = instr[31:25]`
2. **Bộ tạo số tức thời (Immediate Generator - `imm_gen.sv`):**
   - Hỗ trợ chính xác 5 định dạng immediate của RV32I:
     - **I-type:** `imm[31:0] = {{20{instr[31]}}, instr[31:20]}`
     - **S-type:** `imm[31:0] = {{20{instr[31]}}, instr[31:25], instr[11:7]}`
     - **B-type:** `imm[31:0] = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}`
     - **U-type:** `imm[31:0] = {instr[31:12], 12'b0}`
     - **J-type:** `imm[31:0] = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}`
3. **Bộ tính toán số học & logic (ALU 32-bit - `alu.sv`):**
   - Nhận 2 toán hạng 32-bit `alu_a` và `alu_b`, được điều khiển bởi mã chọn `alu_op[3:0]`:
     - `ADD`: `result = alu_a + alu_b`
     - `SUB`: `result = alu_a - alu_b`
     - `SLL`: `result = alu_a << alu_b[4:0]` (Dịch trái logic)
     - `SLT`: `result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0` (So sánh có dấu)
     - `SLTU`: `result = (alu_a < alu_b) ? 32'd1 : 32'd0` (So sánh không dấu)
     - `XOR`: `result = alu_a ^ alu_b`
     - `SRL`: `result = alu_a >> alu_b[4:0]` (Dịch phải logic chèn 0)
     - `SRA`: `result = $signed(alu_a) >>> alu_b[4:0]` (Dịch phải số học giữ bit dấu)
     - `OR`: `result = alu_a | alu_b`
     - `AND`: `result = alu_a & alu_b`
   - Báo cờ trạng thái: `zero_flag = (result == 32'd0)`.
4. **Tập thanh ghi kiến trúc (Register File - `regfile.sv`):**
   - 32 thanh ghi 32-bit (`x0` đến `x31`).
   - Hai cổng đọc bất đồng bộ: `rdata1 = (raddr1 == 5'd0) ? 32'd0 : registers[raddr1]` và `rdata2 = (raddr2 == 5'd0) ? 32'd0 : registers[raddr2]`.
   - Một cổng ghi đồng bộ tại cạnh dương xung nhịp clock:
     ```systemverilog
     always_ff @(posedge clk or negedge rst_n) begin
         if (!rst_n) begin
             for (int i = 0; i < 32; i++) registers[i] <= 32'd0;
         end else if (reg_write && (waddr != 5'd0)) begin
             registers[waddr] <= wdata;
         end
     end
     ```

---

### Chức năng 2 – Pipeline (Kiến trúc Đường ống 5 tầng)

Pipeline được phân chia thành 5 chặng độc lập với 4 thanh ghi trung gian. Mỗi thanh ghi pipeline lưu trữ cả dữ liệu tính toán và các tín hiệu điều khiển cần thiết cho các tầng tiếp theo:

1. **Thanh ghi IF/ID (`pipe_reg_if_id.sv`):**
   - **Tín hiệu lưu:** `pc_if`, `pc_plus4_if`, `instr_if`.
   - **Cơ chế:** Có tín hiệu cho phép ghi `if_id_write_en` (vô hiệu khi stall load-use) và xóa `if_id_flush` (bơm NOP `32'h0000_0013` khi branch/jump taken).
2. **Thanh ghi ID/EX (`pipe_reg_id_ex.sv`):**
   - **Tín hiệu lưu:**
     - Dữ liệu: `pc_id`, `pc_plus4_id`, `rdata1_id`, `rdata2_id`, `imm_id`, `rs1_id`, `rs2_id`, `rd_id`, `funct3_id`.
     - Điều khiển EX: `alu_op_id`, `alu_src_a_sel_id`, `alu_src_b_sel_id`.
     - Điều khiển MEM: `mem_read_id`, `mem_write_id`, `branch_id`, `jump_id`.
     - Điều khiển WB: `reg_write_id`, `wb_sel_id`.
   - **Cơ chế:** Có tín hiệu xóa `id_ex_flush` (khi load-use stall thì chèn Bubble, hoặc khi branch taken thì xóa lệnh sai).
3. **Thanh ghi EX/MEM (`pipe_reg_ex_mem.sv`):**
   - **Tín hiệu lưu:**
     - Dữ liệu: `alu_result_ex`, `mem_wdata_ex` (dữ liệu từ `rs2` sau khi forward để chuẩn bị ghi vào RAM), `rd_ex`, `pc_plus4_ex`, `funct3_ex`.
     - Điều khiển MEM: `mem_read_ex`, `mem_write_ex`.
     - Điều khiển WB: `reg_write_ex`, `wb_sel_ex`.
4. **Thanh ghi MEM/WB (`pipe_reg_mem_wb.sv`):**
   - **Tín hiệu lưu:**
     - Dữ liệu: `mem_rdata_mem`, `alu_result_mem`, `pc_plus4_mem`, `rd_mem`.
     - Điều khiển WB: `reg_write_mem`, `wb_sel_mem`.
5. **Nguyên tắc truyền lan điều khiển:** Mọi tín hiệu điều khiển phát ra từ `control_unit` ở tầng ID phải được "đóng gói" và truyền dọc theo đường ống. Tín hiệu nào thuộc tầng nào thì chỉ được kích hoạt tại đúng tầng đó (ví dụ: `reg_write` chỉ cập nhật vào Register File ở sườn clock kết thúc tầng WB).

---

### Chức năng 3 – Hazard Handling (Xử lý Xung đột Dữ liệu)

#### 1. Forwarding Unit (`forwarding_unit.sv`)
Giải quyết xung đột dữ liệu **RAW (Read-After-Write)** mà không cần dừng pipeline:
- **EX Hazard (EX-to-EX Forwarding):** Dữ liệu được tính ở tầng EX của lệnh trước đang nằm tại thanh ghi `EX/MEM` được chuyển tiếp ngay lập tức vào đầu vào ALU của lệnh hiện tại ở tầng EX.
- **MEM Hazard (MEM-to-EX Forwarding):** Dữ liệu của lệnh trước nữa đang nằm tại thanh ghi `MEM/WB` được chuyển tiếp vào đầu vào ALU của tầng EX.
- **Xử lý thứ tự ưu tiên (Priority Resolution):** Khi cả hai tầng EX/MEM và MEM/WB đều ghi vào cùng một thanh ghi đích trùng với thanh ghi nguồn của tầng EX, **EX Hazard phải được ưu tiên tuyệt đối** vì nó chứa giá trị mới nhất theo thứ tự thực thi của chương trình.
- **Loại trừ phụ thuộc giả với `x0`:** Ràng buộc chặt chẽ `(rd_mem != 5'd0)` và `(rd_wb != 5'd0)`. Không bao giờ forward dữ liệu khi thanh ghi đích là `x0`.

```systemverilog
// Logic chọn nguồn ForwardA cho Toán hạng 1 của ALU
always_comb begin
    if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex)) begin
        forward_a = 2'b10; // Chuyển tiếp từ EX/MEM (alu_result_mem)
    end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex)) begin
        forward_a = 2'b01; // Chuyển tiếp từ MEM/WB (wb_data)
    end else begin
        forward_a = 2'b00; // Không forward, lấy từ thanh ghi gốc (ID/EX)
    end
end

// Logic chọn nguồn ForwardB cho Toán hạng 2 của ALU
always_comb begin
    if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex)) begin
        forward_b = 2'b10; // Chuyển tiếp từ EX/MEM (alu_result_mem)
    end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex)) begin
        forward_b = 2'b01; // Chuyển tiếp từ MEM/WB (wb_data)
    end else begin
        forward_b = 2'b00; // Không forward, lấy từ thanh ghi gốc (ID/EX)
    end
end
```

#### 2. Hazard Detection Unit (`hazard_detection_unit.sv`)
Xử lý trường hợp **Load-Use Hazard**: Khi lệnh `Load` đi ngay trước một lệnh sử dụng dữ liệu từ thanh ghi đích của lệnh `Load`. Vì dữ liệu đọc từ bộ nhớ chỉ có ở cuối tầng MEM, không thể forward ngược về đầu tầng EX trong cùng một chu kỳ clock.
- **Điều kiện phát hiện:**
  ```systemverilog
  logic load_use_hazard;
  assign load_use_hazard = mem_read_ex && ((rd_ex == rs1_id) || (rd_ex == rs2_id)) && (rd_ex != 5'd0);
  ```
- **Hành vi xử lý (Interlock & Stall 1 chu kỳ):**
  - Khóa giá trị PC: `pc_write_en = 1'b0` (ngăn PC cập nhật lệnh tiếp theo).
  - Khóa thanh ghi IF/ID: `if_id_write_en = 1'b0` (giữ nguyên lệnh đang ở tầng ID để chờ dữ liệu).
  - Chèn Bubble (Bóng bọt / NOP) vào tầng EX: `id_ex_flush = 1'b1` (xóa các tín hiệu điều khiển trong thanh ghi ID/EX về 0, chuyển thành lệnh NOP vô hại).
  - Sau 1 chu kỳ stall, dữ liệu của lệnh Load đã đi tới tầng WB và sẽ được MEM-to-EX forwarding chuyển về tầng EX một cách an toàn.

---

### Chức năng 4 – Branch và Jump Handling (Xử lý Xung đột Điều khiển)

1. **Bộ kiểm tra điều kiện rẽ nhánh (Branch Comparator - `branch_comp.sv`):**
   - Đặt tại tầng EX, so sánh 2 toán hạng đã được xử lý forwarding:
     - `BEQ`: `taken = (op_a == op_b)`
     - `BNE`: `taken = (op_a != op_b)`
     - `BLT`: `taken = ($signed(op_a) < $signed(op_b))` (so sánh có dấu)
     - `BGE`: `taken = ($signed(op_a) >= $signed(op_b))` (so sánh có dấu)
     - `BLTU`: `taken = (op_a < op_b)` (so sánh không dấu)
     - `BGEU`: `taken = (op_a >= op_b)` (so sánh không dấu)
2. **Tính toán địa chỉ đích (Branch/Jump Target):**
   - Với Branch và `JAL`: `pc_target = pc_ex + imm_ex`.
   - Với `JALR`: `pc_target = (op_a + imm_ex) & ~32'd1` (theo chuẩn RISC-V: bit 0 luôn bị xóa về 0).
3. **Chiến lược dự đoán tĩnh Predict Not-Taken và Cơ chế Flush:**
   - Bình thường, tầng IF liên tục nạp lệnh kế tiếp tuần tự `PC + 4`.
   - Khi lệnh Branch được đánh giá là `taken == 1` hoặc là lệnh Jump (`JAL`/`JALR`):
     - MUX chọn PC ở tầng IF lập tức chuyển sang nhận `pc_target`.
     - Kích hoạt đồng thời 2 tín hiệu xóa: `if_id_flush = 1'b1` và `id_ex_flush = 1'b1`.
     - Hai lệnh nằm trên luồng rẽ nhánh sai (wrong path) trong thanh ghi `IF/ID` và `ID/EX` bị chuyển hóa thành NOP, hoàn toàn không được ghi vào Register File hay Data RAM.
4. **Báo cáo chi phí phạt rẽ nhánh (Branch Penalty):**
   - Kiến trúc giải quyết nhánh ở tầng EX có chi phí phạt khi đoán sai là **đúng 2 chu kỳ clock (2-cycle penalty)** tương ứng với 2 bóng bọt (bubbles) chèn vào đường ống.
   - Khi rẽ nhánh không nhảy (Not-Taken), số chu kỳ phạt bằng **0 (0-cycle penalty)**.

---

### Chức năng 5 – Memory Access & Alignment (Truy xuất Bộ nhớ & Căn chỉnh Byte)

1. **Kiến trúc Instruction ROM (`instruction_rom.sv`):**
   - Dung lượng: Cấu hình mặc định 4KB (1024 từ 32-bit).
   - Địa chỉ nạp: `addr[11:2]` truy xuất theo từ 32-bit (Word-aligned).
   - Nạp mã máy: Sử dụng cú pháp chuẩn `$readmemh("program.hex", mem_array)` để nạp mã máy trước khi bắt đầu mô phỏng.
2. **Kiến trúc Data RAM (`data_ram.sv`) và Byte-Enable Mask:**
   - Dung lượng: 4KB (1024 từ 32-bit), tổ chức dưới dạng 4 byte-banks hoặc hỗ trợ tín hiệu `byte_enable[3:0]`.
   - **Thao tác Ghi (Store):**
     - `SW` (Store Word): `byte_enable = 4'b1111`, dữ liệu ghi đủ 32 bit.
     - `SH` (Store Half-word):
       - Nếu `addr[1] == 0`: `byte_enable = 4'b0011`, `wdata[15:0] = rs2_val[15:0]`.
       - Nếu `addr[1] == 1`: `byte_enable = 4'b1100`, `wdata[31:16] = rs2_val[15:0]`.
     - `SB` (Store Byte): `byte_enable` bật 1 bit duy nhất tương ứng với `addr[1:0]` (`4'b0001 << addr[1:0]`), dữ liệu `rs2_val[7:0]` được nhân bản vào đúng vị trí byte tương ứng.
3. **Thao tác Đọc (Load) & Mở rộng Dấu:**
   - Dữ liệu đọc 32-bit thô từ RAM được xử lý căn chỉnh và mở rộng dấu theo `funct3`:
     - `LW`: Lấy trọn vẹn 32 bit.
     - `LH` (Load Half-word có dấu): Trích xuất 16-bit tương ứng `addr[1]`, mở rộng dấu: `{{16{half[15]}}, half}`.
     - `LHU` (Load Half-word không dấu): Trích xuất 16-bit, chèn 16 bit 0: `{16'h0000, half}`.
     - `LB` (Load Byte có dấu): Trích xuất 8-bit theo `addr[1:0]`, mở rộng dấu: `{{24{byte[7]}}, byte}`.
     - `LBU` (Load Byte không dấu): Trích xuất 8-bit, chèn 24 bit 0: `{24'h000000, byte}`.
4. **Quy tắc xử lý Misaligned Memory Access:**
   - Trong khuôn khổ đề tài và kiến trúc phần cứng tối giản: Mọi truy xuất Word phải căn chỉnh biên 4-byte (`addr[1:0] == 2'b00`), truy xuất Half-word phải căn chỉnh biên 2-byte (`addr[0] == 1'b0`).
   - Nếu xảy ra truy xuất lệch biên (misaligned access): Phần cứng quy định phớt lờ các bit thấp không căn chỉnh (`addr[1:0] <= 2'b00` cho Word, `addr[0] <= 1'b0` cho Half-word) để đảm bảo DUT luôn trả về kết quả xác định và không bị treo hệ thống hoặc tạo trạng thái bất định (X-state). Testbench sẽ chủ động kiểm tra và thông báo cảnh báo nếu phát hiện phần mềm cố ý truy xuất lệch biên.

---

### Chức năng 6 – Verification (Môi trường Kiểm chứng Tự động SystemVerilog)

Môi trường kiểm chứng được xây dựng theo phương pháp luận hiện đại, đảm bảo tính khách quan và tự động phát hiện lỗi 100%:

```
+-----------------------------------------------------------------------------+
|                     SELF-CHECKING TESTBENCH (tb_cpu_top.sv)                 |
|                                                                             |
|   +-------------------+                     +---------------------------+   |
|   |  DUT: RISC-V Core |                     | Reference Model / Golden  |   |
|   |  (Synthesizable)  |                     | Architectural State Check |   |
|   +---------+---------+                     +-------------+-------------+   |
|             |                                             |                 |
|             v                                             v                 |
|      [Architectural Commit Tracker]              [Expected Signature Dump]  |
|             \                                             /                 |
|              \                                           /                  |
|               v                                         v                   |
|         +-----------------------------------------------------+             |
|         |           TỰ ĐỘNG SO SÁNH (PASS / FAIL CHECK)       |             |
|         |    - Signature Match:   ===>> [TEST PASSED]         |             |
|         |    - Signature Mismatch:==>> [TEST FAILED AT PC]    |             |
|         +-----------------------------------------------------+             |
|                                                                             |
|   +------------------------------------+  +-----------------------------+   |
|   |   8 SYSTEMVERILOG ASSERTIONS (SVA) |  | FUNCTIONAL COVERAGE (>=90%) |   |
|   |   - Protocol Invariant Checking    |  | - Covergroups & Crosses     |   |
|   +------------------------------------+  +-----------------------------+   |
+-----------------------------------------------------------------------------+
```

1. **Kiểm thử Đơn vị (Unit-level Testbench):**
   - `tb_alu.sv`: Kiểm tra toàn diện 10 phép toán, quét qua các giá trị biên cực đoan: `0x0000_0000`, `0xFFFF_FFFF`, `0x7FFF_FFFF`, `0x8000_0000`. Kiểm tra tràn số và so sánh có dấu/không dấu.
   - `tb_regfile.sv`: Kiểm tra đọc 2 cổng bất đồng bộ, ghi đồng bộ 1 cổng, ghi đồng thời đọc, và chứng minh tính bất biến của `x0` khi bị ghi dữ liệu bất kỳ.
   - `tb_imm_gen.sv`: Kiểm tra việc trích xuất và mở rộng bit dấu của cả 5 loại immediate (I, S, B, U, J).
   - `tb_decoder.sv`: Kiểm tra bảng chân trị các tín hiệu điều khiển sinh ra tương ứng với toàn bộ 37 mã opcode/funct3/funct7.
   - `tb_forwarding.sv`: Tạo các vector kích thích nhân tạo để kiểm tra các trường hợp EX Hazard, MEM Hazard, và kiểm tra trường hợp cả hai cùng kích hoạt (ưu tiên EX).
   - `tb_hazard.sv`: Kiểm tra tính năng dừng xung clock (Stall) khi xảy ra Load-Use và kích hoạt tín hiệu Flush khi Branch Taken.
2. **Kiểm thử Tích hợp Tự động (CPU-level Self-Checking Testbench):**
   - File `tb_cpu_top.sv` tự động nạp file `.hex` vào ROM và nạp dữ liệu ban đầu vào RAM.
   - **Cơ chế Memory Signature / Architectural State:** Chương trình thử nghiệm sau khi hoàn thành thuật toán sẽ ghi toàn bộ kết quả thanh ghi quan trọng vào một vùng nhớ đặc biệt trong RAM (gọi là Signature Buffer, ví dụ tại địa chỉ `0x0000_0F00`). Testbench đọc toàn bộ buffer này và so sánh tự động với mảng kết quả mong đợi (Reference Model).
   - In thông báo rõ ràng lên màn hình console: `*** ALL TESTS PASSED SUCCESSFULLY ***` hoặc `*** TEST FAILED AT PC = 0x... ***`. Tuyệt đối không dựa dẫm vào việc quan sát thủ công trên Waveform.
3. **Bộ bài kiểm thử Directed Tests và Stress Tests:**
   - **Test 1 - Arithmetic & Immediate:** Kiểm tra 19 lệnh tính toán số học với các số âm, số dương, zero và giá trị biên.
   - **Test 2 - RAW Dependency Chains:** Chuỗi nhiều lệnh liên tiếp phụ thuộc dữ liệu để kích hoạt liên tục cả EX-to-EX và MEM-to-EX forwarding.
   - **Test 3 - Load-Use Interlock:** Kiểm tra lệnh Load ngay trước lệnh tính toán số học, đo đếm chính xác số chu kỳ stall (đúng 1 chu kỳ).
   - **Test 4 - Branch & Jump Stress Test:** Vòng lặp kiểm tra cả 6 lệnh rẽ nhánh ở cả 2 nhánh (Taken và Not-Taken) cho cả số có dấu và không dấu; kiểm tra lệnh `JAL` và `JALR` nhảy tới nhãn động.
   - **Test 5 - Flush Side-Effect Verification:** Đặt các lệnh ghi bộ nhớ (`SW`) và ghi thanh ghi ngay sau lệnh Branch/Jump, xác minh khi nhánh được chọn, các lệnh này bị Flush hoàn toàn và không để lại bất kỳ side-effect nào trong Register File hoặc RAM.
   - **Test 6 - Sub-word Memory Test:** Đọc và ghi đan xen các byte, half-word và word tại các vị trí offset khác nhau trong RAM; kiểm tra mở rộng dấu cho `LB`, `LH` và không dấu cho `LBU`, `LHU`.
   - **Test 7 - Ứng dụng thực tế quy mô:** Chạy thuật toán tính dãy số Fibonacci và thuật toán Sắp xếp nổi bọt (Bubble Sort) trên mảng dữ liệu trong RAM.
4. **Kiểm thử Ngẫu nhiên có Ràng buộc (Constrained-Random Verification):**
   - Tạo bộ sinh chuỗi lệnh ngẫu nhiên bằng SystemVerilog (`randomize() with { ... }`) để phát sinh ngẫu nhiên các cặp thanh ghi `rs1`, `rs2`, `rd` và các loại lệnh kế tiếp nhau nhằm phát hiện các tình huống tương tác phức tạp mà kiểm thử định hướng (directed) chưa bao phủ hết.
5. **Bộ 8 SystemVerilog Assertions (SVA) Bắt buộc:**
   - **SVA 1 - Bất biến của thanh ghi `x0`:**
     ```systemverilog
     property p_x0_always_zero;
         @(posedge clk) (dut.u_datapath.u_regfile.registers[0] == 32'd0);
     endproperty
     assert property (p_x0_always_zero) else $error("SVA ERROR: Register x0 modified!");
     ```
   - **SVA 2 - Không ghi Register File khi `RegWrite = 0`:**
     ```systemverilog
     property p_no_reg_write_when_disabled;
         @(posedge clk) (!dut.u_datapath.reg_write_wb) |=> ($stable(dut.u_datapath.u_regfile.registers));
     endproperty
     assert property (p_no_reg_write_when_disabled) else $error("SVA ERROR: RegFile modified without RegWrite!");
     ```
   - **SVA 3 - Không ghi Data Memory khi `MemWrite = 0`:**
     ```systemverilog
     property p_no_mem_write_when_disabled;
         @(posedge clk) (!dut.mem_write_mem) |=> ($stable(dut.u_data_ram.mem));
     endproperty
     assert property (p_no_mem_write_when_disabled) else $error("SVA ERROR: Memory written without MemWrite!");
     ```
   - **SVA 4 - Lệnh bị Flush không được cập nhật trạng thái kiến trúc:**
     ```systemverilog
     property p_flush_no_architectural_update;
         @(posedge clk) (dut.id_ex_flush) |=> (!dut.reg_write_ex && !dut.mem_write_ex);
     endproperty
     assert property (p_flush_no_architectural_update) else $error("SVA ERROR: Flushed instruction retained active control signals!");
     ```
   - **SVA 5 - Load-Use Dependency tạo Stall chuẩn xác:**
     ```systemverilog
     property p_load_use_stall_behavior;
         @(posedge clk) disable iff (!rst_n)
         (dut.u_hazard_unit.load_use_hazard) |=> (!dut.pc_write_en && !dut.if_id_write_en && dut.id_ex_flush);
     endproperty
     assert property (p_load_use_stall_behavior) else $error("SVA ERROR: Load-Use hazard failed to trigger stall!");
     ```
   - **SVA 6 - Forwarding Select lựa chọn đúng nguồn:**
     ```systemverilog
     property p_forwarding_priority_correct;
         @(posedge clk) disable iff (!rst_n)
         (dut.reg_write_mem && (dut.rd_mem != 5'd0) && (dut.rd_mem == dut.rs1_ex)) |-> (dut.u_forwarding_unit.forward_a == 2'b10);
     endproperty
     assert property (p_forwarding_priority_correct) else $error("SVA ERROR: EX-to-EX forwarding selection incorrect!");
     ```
   - **SVA 7 - Wrong-path Instruction không được Commit khi Branch/Jump Taken:**
     ```systemverilog
     property p_branch_flush_wrong_path;
         @(posedge clk) disable iff (!rst_n)
         (dut.branch_taken_ex) |=> (dut.if_id_flush && dut.id_ex_flush);
     endproperty
     assert property (p_branch_flush_wrong_path) else $error("SVA ERROR: Wrong-path instructions not flushed upon taken branch!");
     ```
   - **SVA 8 - Program Counter tuân thủ quy tắc cập nhật:**
     ```systemverilog
     property p_pc_update_rules;
         @(posedge clk) disable iff (!rst_n)
         (!dut.pc_write_en) |=> ($stable(dut.pc_if));
     endproperty
     assert property (p_pc_update_rules) else $error("SVA ERROR: PC changed during stall!");
     ```
6. **Mô hình Functional Coverage (Mục tiêu tối thiểu $\ge 90\%$):**
   - `cg_instruction`: Coverpoint cho 37 lệnh RV32I (đảm bảo mỗi lệnh được thực thi tối thiểu 10 lần).
   - `cg_hazards`:
     - Cross coverage giữa `forward_a` (00, 01, 10) và `forward_b` (00, 01, 10).
     - Coverpoint cho Load-Use stall xảy ra với cả `rs1` và `rs2`.
   - `cg_branch`: Coverpoint kiểm tra cả 2 nhánh (Taken và Not-Taken) cho từng lệnh trong 6 lệnh rẽ nhánh (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`).
   - `cg_memory`: Coverpoint cho kích thước truy xuất (Byte, Half-word, Word) đối với cả thao tác đọc (có dấu và không dấu) và thao tác ghi.
   - **Phân tích Coverage Hole:** Xuất báo cáo chi tiết, nếu điểm độ bao phủ chưa đạt 90%, phải phân tích nguyên nhân lỗ hổng và bổ sung test case có chủ đích vào regression suite.
7. **Code Coverage:** Kích hoạt tính năng thu thập Statement Coverage, Branch Coverage và Toggle Coverage trên công cụ mô phỏng để đánh giá độ bao phủ mã nguồn.

---

### Chức năng 7 – Synthesis và FPGA Validation (Hiện thực Phần cứng)

1. **Tiêu chuẩn RTL Synthesizable:**
   - Toàn bộ mã nguồn RTL tuân thủ chuẩn tổng hợp: Sử dụng `always_ff @(posedge clk or negedge rst_n)` cho phần tử tuần tự và `always_comb` cho mạch tổ hợp.
   - Triệt tiêu 100% hiện tượng chốt ẩn không mong muốn (Inferred Latches) bằng cách gán giá trị mặc định cho tất cả các nhánh trong câu lệnh `case` / `if`.
   - Không chứa bất kỳ vòng lặp tổ hợp nào (Combinational Loops).
2. **Quy trình Synthesis trên Vivado / Quartus:**
   - Thực hiện quy trình: RTL Analysis → Synthesis → Implementation.
   - Trích xuất bảng số liệu báo cáo kỹ thuật tối thiểu gồm:
     - Số lượng Look-Up Tables (LUTs) hoặc Logic Elements (LEs).
     - Số lượng Flip-Flops / Registers.
     - Số lượng khối bộ nhớ nhúng Block RAM (BRAM / M9K / M10K) sử dụng cho ROM/RAM.
     - Phân tích đường trễ tới hạn (Critical Path) và thời gian thiết lập/giữ (Setup/Hold slack).
     - Tần số xung nhịp hoạt động tối đa có thể đạt được ($F_{max}$).
3. **Triển khai Kiểm chứng trên Phần cứng FPGA:**
   - Thiết kế module giao tiếp đỉnh `fpga_top.sv` bao bọc lõi vi xử lý.
   - Ánh xạ chân kết nối với ngoại vi trên bo mạch thí nghiệm (FPGA Board):
     - **Hệ thống LED chỉ báo:** LED hiển thị trạng thái bộ vi xử lý (Đang chạy, Đã hoàn thành, Báo lỗi PASS/FAIL).
     - **LED 7 đoạn (Seven-Segment Display):** Hiển thị giá trị 16-bit thấp của Program Counter (PC) hoặc giá trị thanh ghi kết quả.
     - **Giao tiếp UART (Universal Asynchronous Receiver-Transmitter):** Truyền kết quả kiểm thử (Memory Signature hoặc chuỗi ký tự `"PASS"`) qua cổng Micro-USB/UART lên máy tính để theo dõi trên màn hình Terminal (Putty / TeraTerm).
     - **Memory-Mapped I/O:** Cấu hình một dải địa chỉ bộ nhớ đặc biệt (ví dụ `0x8000_0000`) để CPU có thể điều khiển trực tiếp các ngoại vi này bằng lệnh `SW`.

---

## 4. KỊCH BẢN KIỂM THỬ VÀ BẢNG TIÊU CHÍ NGHIỆM THU

| Hạng mục kiểm thử | Kịch bản kiểm thử chi tiết | Tiêu chí nghiệm thu (Acceptance Criteria) |
| :--- | :--- | :--- |
| **Kiểm thử ISA RV32I** | Chạy toàn bộ 37 lệnh với dữ liệu ngẫu nhiên và các giá trị biên `0x00000000`, `0xFFFFFFFF`, `0x7FFFFFFF`, `0x80000000`. | 100% lệnh thực thi chính xác, kết quả số học và logic đồng nhất với kết quả lý thuyết. |
| **Bất biến của thanh ghi x0** | Cố tình ghi các giá trị `0xFFFFFFFF`, `0x12345678` vào `x0` bằng các lệnh `ADDI`, `ADD`, `LW`. | Giá trị thanh ghi `x0` bất biến và luôn đọc ra `0x00000000`; không có vi phạm SVA 1. |
| **RAW Data Hazard** | Chuỗi lệnh phụ thuộc dữ liệu liên tiếp không có NOP: lệnh sau dùng ngay kết quả lệnh trước (EX Hazard và MEM Hazard). | Forwarding Unit hoạt động chính xác, dữ liệu nhận được đúng 100%, không bị sai lệch kết quả. |
| **Độ ưu tiên Forwarding** | Lệnh ở tầng MEM và WB cùng ghi vào một thanh ghi đích `rd` trùng với `rs` của tầng EX. | Forwarding Unit bắt buộc phải chọn dữ liệu từ tầng MEM; không có vi phạm SVA 6. |
| **Load-Use Interlock** | Lệnh `LW` đi ngay trước lệnh `ADD` sử dụng giá trị vừa load. | Thanh ghi PC và IF/ID bị giữ lại đúng 1 chu kỳ clock, 1 bubble chèn vào ID/EX; không có vi phạm SVA 5. |
| **Control Hazard (Branch)** | Kiểm tra 6 lệnh rẽ nhánh cả 2 trường hợp Taken và Not-Taken với các số có dấu và không dấu. | Rẽ nhánh đúng hướng; khi Taken, 2 lệnh wrong-path bị Flush hoàn toàn; không có side-effect ghi RAM/RegFile. |
| **Control Hazard (Jump)** | Kiểm tra lệnh `JAL` và `JALR` với địa chỉ đích bất kỳ. | Nhảy chính xác tới địa chỉ đích, thanh ghi `rd` lưu lại đúng địa chỉ trở về `PC + 4`. |
| **Sub-word Memory Access** | Ghi và đọc đan xen các kích thước Byte, Half-word, Word với các offset địa chỉ `0, 1, 2, 3`. | Byte-mask ghi đúng byte cần ghi; `LB`/`LH` mở rộng dấu đúng, `LBU`/`LHU` mở rộng 0 đúng; không làm hỏng dữ liệu lân cận. |
| **Chương trình phức hợp** | Chạy thuật toán Fibonacci và Bubble Sort trên CPU hoàn chỉnh. | Tự động so sánh Memory Signature trong RAM với bảng kết quả mẫu đạt khớp 100%, testbench báo `PASS`. |
| **Tự động hóa Testbench** | Toàn bộ các bài kiểm tra được gói trong một kịch bản hồi quy (Regression Test Suite). | Tự động báo PASS/FAIL; 0 lỗi Assertion trong suốt quá trình chạy; không phụ thuộc soi sóng thủ công. |
| **Độ bao phủ (Coverage)** | Thu thập dữ liệu từ mô hình Functional Coverage và Code Coverage. | Functional Coverage $\ge 90\%$; các coverage hole được phân tích và giải trình đầy đủ. |
| **Synthesis & FPGA** | Tổng hợp RTL trên Xilinx Vivado hoặc Intel Quartus Prime và nạp lên kit phần cứng. | Synthesis thành công với **0 Inferred Latches**, có đầy đủ báo cáo tài nguyên và $F_{max}$; chạy được bài test trên FPGA board. |

---

## 5. KẾT QUẢ DỰ KIẾN CỦA ĐỀ TÀI

1. **Bộ mã nguồn RTL hoàn chỉnh:** Mã nguồn SystemVerilog synthesizable đầy đủ các module cho CPU RISC-V 32-bit pipeline 5 tầng hỗ trợ 37 lệnh RV32I cơ bản, giải quyết triệt để Data Hazard và Control Hazard.
2. **Hệ thống Kiểm chứng Tự động Chuyên nghiệp:** Môi trường Self-checking Testbench tự động đối chiếu kết quả trạng thái kiến trúc và chữ ký bộ nhớ, đi kèm bộ 8 SystemVerilog Assertions kiểm soát tính bất biến và mô hình Functional Coverage đạt trên 90%.
3. **Báo cáo Kỹ thuật & Báo cáo Tổng hợp Phần cứng:** Hồ sơ thiết kế chi tiết bao gồm sơ đồ khối Datapath, sơ đồ xử lý xung đột, dạng sóng minh họa các trường hợp Forwarding, Stall, Flush, cùng báo cáo tổng hợp tài nguyên (LUT, FF, BRAM, Critical Path, $F_{max}$) trên công cụ EDA chuyên dụng.
4. **Hiện thực trên FPGA Board:** Triển khai vi xử lý trên nền tảng phần cứng phòng thí nghiệm, chạy thành công chương trình thử nghiệm và giao tiếp hiển thị kết quả qua LED/UART/7-segment, hoàn thiện chu trình khép kín từ ý tưởng thiết kế, mô phỏng kiểm chứng đến hiện thực phần cứng.
