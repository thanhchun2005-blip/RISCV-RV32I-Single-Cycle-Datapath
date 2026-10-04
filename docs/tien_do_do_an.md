# KẾ HOẠCH TIẾN ĐỘ THỰC HIỆN ĐỒ ÁN 2 (14 TUẦN)

**Học phần:** Đồ án Môn học 2 (Capstone Project II) – Ngành Kỹ thuật Máy tính  
**Sinh viên thực hiện:** Nguyễn Thành Trung (MSSV: **23119117**)  
**Tên đề tài:** Thiết kế, kiểm chứng và triển khai FPGA lõi vi xử lý RISC-V RV32I 32-bit pipeline 5 tầng ở mức RTL bằng SystemVerilog  
**Thời lượng thực hiện:** 14 tuần (1 học kỳ chuẩn)  

---

## 0. CHIẾN LƯỢC VÀ PHƯƠNG PHÁP TRIỂN KHAI

> [!IMPORTANT]
> **Quy tắc 1: "Xây móng vững chắc - Đi qua bước đệm Single-Cycle"**  
> Tuyệt đối không bắt đầu ngay bằng một kiến trúc Pipeline phức tạp. Quá trình thiết kế được chia làm 3 bước bậc thang:
> 1. Thiết kế và kiểm tra độc lập từng module con (ALU, RegFile, ImmGen, Decoder, RAM).
> 2. Ghép nối thành CPU Đơn chu kỳ (Single-Cycle) để kiểm chứng 100% tính đúng đắn của logic tính toán và giải mã tập lệnh RV32I.
> 3. Tách tầng và chèn 4 thanh ghi Pipeline, sau đó lần lượt tích hợp Forwarding Unit, Hazard Detection Unit và Branch Flush.

> [!TIP]
> **Quy tắc 2: "Kiểm chứng Tự động hóa - Nói không với việc chỉ nhìn Waveform"**  
> Đề tài đặt trọng tâm vào chất lượng kiểm chứng:
> - Áp dụng phương pháp **Self-Checking Testbench**: Tự động so sánh Memory Signature và trạng thái kiến trúc với mô hình chuẩn (Golden Model), tự động báo PASS/FAIL.
> - Tích hợp đầy đủ **8 SystemVerilog Assertions (SVA)** kiểm soát giao thức và tính bất biến theo thời gian thực.
> - Xây dựng **Functional Coverage** mục tiêu đạt tối thiểu **90%**, chủ động phân tích các lỗ hổng bao phủ (coverage holes) để bổ sung test case.

---

## 1. BẢNG TỔNG HỢP LỘ TRÌNH 14 TUẦN

| Giai đoạn | Tuần | Trọng tâm công việc | Sản phẩm bàn giao (Deliverables) | Tiêu chí nghiệm thu cốt lõi |
| :--- | :---: | :--- | :--- | :--- |
| **GĐ 1: Khởi động & Nền tảng** | **Tuần 1** | Chuẩn bị EDA tool, nghiên cứu sâu ISA RV32I (37 lệnh) & cấu trúc Harvard | Thư mục dự án chuẩn, bộ tài liệu dịch tay 6 định dạng lệnh | Môi trường mô phỏng sẵn sàng, hiểu sâu 37 lệnh RV32I |
| **GĐ 2: Thiết kế Module lõi** | **Tuần 2** | Thiết kế & Unit-test ALU 32-bit (biên cực đoan) và Immediate Generator | `alu.sv`, `imm_gen.sv`, `tb_alu.sv`, `tb_imm_gen.sv` | ALU pass 10 phép toán với các giá trị biên signed/unsigned |
| | **Tuần 3** | Thiết kế Register File (x0 bất biến), Control Unit & Bộ nhớ ROM/RAM | `regfile.sv`, `control_unit.sv`, `instruction_rom.sv`, `data_ram.sv` | x0 luôn bằng 0, giải mã đúng 37 lệnh, nạp được file hex |
| **GĐ 3: Bước đệm Single-Cycle** | **Tuần 4** | Ghép nối CPU Single-Cycle hoàn chỉnh, chạy kiểm thử các lệnh cơ sở | `datapath_single_cycle.sv`, `riscv_single_cycle_top.sv` | Chạy đúng chuỗi lệnh cơ bản R, I, S, B, J trong 1 chu kỳ/lệnh |
| **GĐ 4: Dựng Khung Pipeline 5 tầng** | **Tuần 5** | Phân chia 5 tầng (IF/ID/EX/MEM/WB), thiết kế 4 thanh ghi Pipeline trung gian | `pipe_reg_if_id.sv`, `pipe_reg_id_ex.sv`, `pipe_reg_ex_mem.sv`, `pipe_reg_mem_wb.sv` | Đóng gói và truyền lan đầy đủ dữ liệu và tín hiệu điều khiển |
| | **Tuần 6** | Tích hợp CPU Pipeline cơ bản, kiểm thử luồng lệnh chèn NOP thủ công | `riscv_pipeline_basic.sv`, chương trình test có NOP | Nhìn thấy lệnh di chuyển nhịp nhàng qua 5 tầng trên sóng |
| **GĐ 5: Xử lý Xung đột (Hazards)** | **Tuần 7** | Thiết kế Forwarding Unit (RAW Hazard: EX-to-EX & MEM-to-EX, priority) | `forwarding_unit.sv`, testbench kiểm thử xung đột RAW | Chuỗi lệnh phụ thuộc chạy đúng không cần bất kỳ NOP nào |
| | **Tuần 8** | Thiết kế Hazard Detection Unit (Load-Use Stall) & Xử lý Branch Flush | `hazard_detection_unit.sv`, `branch_comp.sv`, logic Flush | Stall đúng 1 chu kỳ khi load-use; flush sạch 2 lệnh sai khi branch |
| **GĐ 6: Bộ nhớ & Kiểm thử Tổng hợp**| **Tuần 9** | Hoàn thiện Data RAM (Byte/Half/Word, sign-extend, misaligned rule) & App | `data_ram.sv` nâng cấp, `fibonacci.s`, `bubble_sort.s` | Xử lý đúng mọi kích thước byte; chạy đúng thuật toán trong RAM |
| **GĐ 7: Kiểm chứng Tự động & Nâng cao**| **Tuần 10**| Xây dựng Self-Checking Testbench cấp CPU & Random Instruction Testing | `tb_cpu_top.sv`, bộ so sánh Memory Signature, test ngẫu nhiên | Testbench tự động in PASS/FAIL, kiểm thử giá trị biên toàn diện |
| | **Tuần 11**| Hiện thực trọn bộ 8 SystemVerilog Assertions (SVA) giám sát runtime | `riscv_sva.sv` gắn trực tiếp vào Top CPU | 0 SVA violation trong suốt toàn bộ chuỗi regression test |
| | **Tuần 12**| Xây dựng Functional Coverage & Đo lường Code Coverage | `riscv_coverage.sv`, bảng phân tích Coverage Holes | Functional Coverage đạt $\ge 90\%$, giải trình các coverage hole |
| **GĐ 8: Hiện thực FPGA & Báo cáo** | **Tuần 13**| RTL Synthesis trên Vivado/Quartus & Triển khai kiểm chứng trên FPGA Board | Dự án synthesis, báo cáo LUT/FF/BRAM/Fmax, module `fpga_top.sv` | 0 Inferred Latches, Fmax đạt yêu cầu, chạy test trên FPGA |
| | **Tuần 14**| Hoàn thiện Thuyết minh đồ án, Slide báo cáo, video demo & bảo vệ | Cuốn báo cáo kỹ thuật hoàn chỉnh, slide thuyết trình | Bảo vệ thành công trước Hội đồng chấm Đồ án 2 |

---

## 2. KẾ HOẠCH HÀNH ĐỘNG CHI TIẾT TỪNG TUẦN (ACTION PLAN)

---

### TUẦN 1: THIẾT LẬP MÔI TRƯỜNG EDA & NGHIÊN CỨU SÂU ISA RV32I
- **Mục tiêu tuần:** Chuẩn bị toàn diện môi trường làm việc; nắm vững quy chuẩn mã hóa 37 lệnh RV32I và kiến trúc bộ nhớ Harvard.
- **Công việc cụ thể:**
  1. Thiết lập công cụ:
     - Trình soạn thảo & Linter: VS Code cài đặt tiện ích SystemVerilog, Verissimo/Verilator linter.
     - Trình mô phỏng: Siemens QuestaSim / ModelSim (hoặc Synopsys VCS / Icarus Verilog).
     - Công cụ tổng hợp FPGA: Xilinx Vivado hoặc Intel Quartus Prime.
     - Toolchain hợp ngữ: Cài đặt RISC-V GCC toolchain (`riscv32-unknown-elf-gcc`) hoặc script dịch mã máy Python (`assemble.py`).
  2. Nghiên cứu kiến trúc vi xử lý RV32I:
     - 32 thanh ghi kiến trúc (`x0` - `x31`), đặc tính bất biến của `x0` (hardwired zero).
     - 6 định dạng lệnh: R, I, S, B, U, J. Phân tích chi tiết từng trường bit (`opcode`, `rd`, `funct3`, `rs1`, `rs2`, `funct7`, `imm`).
     - Xác định quy tắc xử lý lệnh không hợp lệ (illegal/unsupported): vô hiệu hóa tín hiệu điều khiển, không làm sai lệch trạng thái kiến trúc.
- **Sản phẩm bàn giao:**
  - Cấu trúc thư mục dự án hoàn chỉnh.
  - Script dịch hợp ngữ tự động từ mã Assembly sang file `.hex` / `.mem`.
- **Tiêu chí nghiệm thu (Checklist):**
  - [x] Chạy thử thành công một module test SystemVerilog trên QuestaSim/ModelSim.
  - [x] Lập bảng tra cứu nhị phân đối chiếu tay chính xác cho ít nhất 10 lệnh tiêu biểu của 6 định dạng.

---

### TUẦN 2: THIẾT KẾ & KIỂM CHỨNG ALU 32-BIT VÀ IMMEDIATE GENERATOR
- **Mục tiêu tuần:** Hoàn thành thiết kế RTL và Unit Testbench cho hai khối tính toán và sinh hằng số cốt lõi.
- **Công việc cụ thể:**
  1. Thiết kế module `alu.sv`:
     - Hiện thực 10 phép toán: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`.
     - Phân biệt rõ dịch logic `SRL` (chèn 0) và dịch số học `SRA` (giữ nguyên bit dấu MSB).
     - Phân biệt rõ so sánh có dấu `SLT` (`$signed(a) < $signed(b)`) và không dấu `SLTU` (`a < b`).
  2. Viết Testbench kiểm tra ALU `tb_alu.sv`:
     - Kiểm tra toàn bộ 10 phép toán với các giá trị bình thường.
     - **Kiểm tra giá trị biên bắt buộc:** `0x0000_0000`, `0xFFFF_FFFF`, `0x7FFF_FFFF`, `0x8000_0000`.
     - Kiểm tra các trường hợp tràn số (overflow), dịch 0 bit và dịch cực đại 31 bit.
  3. Thiết kế module `imm_gen.sv`:
     - Trích xuất và mở rộng bit dấu chính xác 32-bit cho cả 5 định dạng tức thời: I, S, B, U, J.
  4. Viết Testbench `tb_imm_gen.sv` kiểm tra tất cả các định dạng hằng số.
- **Sản phẩm bàn giao:**
  - File mã nguồn: `rtl/core/alu.sv`, `rtl/core/imm_gen.sv`.
  - File testbench: `testbench/unit_tests/tb_alu.sv`, `testbench/unit_tests/tb_imm_gen.sv`.
- **Tiêu chí nghiệm thu:**
  - [x] `tb_alu.sv` chạy tự động, đối chiếu kết quả với toán tử tham chiếu, báo PASS 100%.
  - [x] `tb_imm_gen.sv` trích xuất đúng từng bit của các lệnh I, S, B, U, J mẫu.

---

### TUẦN 3: THIẾT KẾ TẬP THANH GHI, CONTROL UNIT & BỘ NHỚ CƠ BẢN
- **Mục tiêu tuần:** Hoàn thành khối Register File, bộ giải mã điều khiển (Control Unit) và các khối bộ nhớ ROM/RAM cơ bản.
- **Công việc cụ thể:**
  1. Thiết kế module `regfile.sv`:
     - Mảng 32 thanh ghi 32-bit: `logic [31:0] registers [0:31]`.
     - 2 cổng đọc bất đồng bộ (tổ hợp) và 1 cổng ghi đồng bộ tại sườn dương clock khi `reg_write == 1`.
     - Khóa cứng `x0`: Mọi thao tác ghi vào `x0` bị triệt tiêu, đọc từ `x0` luôn ra `32'd0`.
     - Viết `tb_regfile.sv` kiểm tra tính bất biến của `x0` khi cố tình ghi `0xFFFF_FFFF`.
  2. Thiết kế module `control_unit.sv`:
     - Tách 2 tầng logic: **Main Decoder** (giải mã theo `opcode[6:0]`) và **ALU Decoder** (giải mã theo `funct3`, `funct7` và `alu_op_type`).
     - Sinh đầy đủ các tín hiệu: `reg_write`, `mem_read`, `mem_write`, `branch`, `jump`, `alu_src_a`, `alu_src_b`, `wb_sel`.
     - Nhận diện các lệnh không hỗ trợ / invalid opcode để vô hiệu hóa toàn bộ cờ ghi (`reg_write = 0, mem_write = 0`).
  3. Thiết kế `instruction_rom.sv` và `data_ram.sv` cơ bản:
     - `instruction_rom.sv`: Đọc theo từ (Word 32-bit), nạp dữ liệu bằng `$readmemh`.
     - `data_ram.sv`: Hỗ trợ đọc/ghi theo Word 32-bit phục vụ bước đệm Single-Cycle.
- **Sản phẩm bàn giao:**
  - File mã nguồn: `regfile.sv`, `control_unit.sv`, `instruction_rom.sv`, `data_ram.sv`.
  - File testbench đơn vị tương ứng.
- **Tiêu chí nghiệm thu:**
  - [x] `tb_regfile.sv` kiểm tra ghi/đọc đồng thời và khẳng định `x0` không bị thay đổi.
  - [x] `tb_decoder.sv` quét qua 37 mã lệnh RV32I và xác nhận sinh đúng bảng chân trị điều khiển.

---

### TUẦN 4: GHÉP NỐI CPU SINGLE-CYCLE (BƯỚC ĐỆM KIỂM CHỨNG ISA)
- **Mục tiêu tuần:** Kết nối toàn bộ các khối đã thiết kế thành một lõi vi xử lý Single-Cycle hoàn chỉnh; kiểm chứng tính đúng đắn của logic Datapath và ISA trước khi chia tầng pipeline.
- **Công việc cụ thể:**
  1. Tích hợp `datapath_single_cycle.sv`:
     - Kết nối PC, Bộ cộng `PC + 4`, Instruction ROM, Register File, Imm Gen, ALU Mux, ALU, Data RAM, WB Mux.
     - Bộ logic kiểm tra nhánh đơn giản tại cùng chu kỳ clock.
  2. Viết chương trình hợp ngữ kiểm tra toàn diện Single-Cycle (`single_cycle_test.s`):
     - Bao gồm các lệnh tính toán số học: `ADDI`, `ADD`, `SUB`, `AND`, `OR`.
     - Bao gồm lệnh lưu/nạp bộ nhớ: `SW`, `LW`.
     - Bao gồm lệnh rẽ nhánh và nhảy: `BEQ`, `BNE`, `JAL`.
  3. Chạy mô phỏng trên QuestaSim/ModelSim, quan sát sự thay đổi thanh ghi và bộ nhớ.
- **Sản phẩm bàn giao:**
  - Module `datapath_single_cycle.sv` và `riscv_single_cycle_top.sv`.
  - Chương trình kiểm thử `single_cycle_test.hex`.
- **Tiêu chí nghiệm thu:**
  - [x] CPU Single-Cycle chạy qua toàn bộ chuỗi lệnh mẫu, ghi đúng kết quả cuối cùng vào thanh ghi và RAM.
  - [x] Không phát sinh bất kỳ lỗi logic nào về giải mã hay tính toán địa chỉ.

---

### TUẦN 5: XÂY DỰNG KHUNG PIPELINE 5 TẦNG & 4 THANH GHI TRUNG GIAN
- **Mục tiêu tuần:** Phân rã Datapath thành 5 tầng độc lập (IF, ID, EX, MEM, WB) bằng 4 khối thanh ghi pipeline đồng bộ.
- **Công việc cụ thể:**
  1. Thiết kế 4 module thanh ghi Pipeline:
     - `pipe_reg_if_id.sv`: Lưu `pc`, `pc_plus4`, `instr`; có đầu vào điều khiển `write_en` (giữ lệnh khi stall) và `flush` (xóa lệnh).
     - `pipe_reg_id_ex.sv`: Lưu dữ liệu toán hạng, immediate, trường thanh ghi `rs1, rs2, rd`, cùng toàn bộ bus điều khiển cho EX, MEM, WB; có tín hiệu `flush` (chèn Bubble).
     - `pipe_reg_ex_mem.sv`: Lưu kết quả ALU, dữ liệu ghi RAM, `rd`, tín hiệu điều khiển MEM và WB.
     - `pipe_reg_mem_wb.sv`: Lưu dữ liệu đọc từ RAM, kết quả ALU, `rd`, tín hiệu điều khiển WB.
  2. Thực hiện nguyên tắc đóng gói điều khiển (Control Signals Propagation):
     - Tín hiệu `reg_write` và `wb_sel` phải truyền tuần tự qua đủ 4 thanh ghi pipeline trước khi kích hoạt tại tầng WB.
  3. Ghép nối thành khung CPU Pipeline cơ bản `riscv_pipeline_basic.sv` (chưa có mạch xử lý Hazard).
- **Sản phẩm bàn giao:**
  - 4 file thanh ghi: `pipe_reg_if_id.sv`, `pipe_reg_id_ex.sv`, `pipe_reg_ex_mem.sv`, `pipe_reg_mem_wb.sv`.
  - Module top sơ bộ `riscv_pipeline_basic.sv`.
- **Tiêu chí nghiệm thu:**
  - [x] Mã nguồn biên dịch sạch sẽ, không có cảnh báo Inferred Latch.
  - [x] Tín hiệu điều khiển truyền đúng từng tầng theo từng chu kỳ xung nhịp.

---

### TUẦN 6: KIỂM CHỨNG KHUNG PIPELINE VỚI CHUỖI LỆNH CHÈN NOP
- **Mục tiêu tuần:** Kiểm chứng trực quan hoạt động của đường ống 5 tầng khi không có xung đột dữ liệu (sử dụng lệnh NOP thủ công).
- **Công việc cụ thể:**
  1. Soạn thảo chương trình hợp ngữ kiểm tra Pipeline không xung đột (`pipeline_nop_test.s`):
     - Giữa các lệnh có quan hệ phụ thuộc dữ liệu, chèn 3 lệnh `NOP` (`addi x0, x0, 0`):
       ```assembly
       addi x1, x0, 10
       nop
       nop
       nop
       addi x2, x1, 20     # x2 phụ thuộc x1, nhưng x1 đã kịp Write-Back xong
       nop
       nop
       nop
       add  x3, x1, x2
       ```
  2. Chạy mô phỏng và phân tích chi tiết dạng sóng Waveform:
     - Xác nhận tại chu kỳ thứ 5, toàn bộ 5 tầng IF, ID, EX, MEM, WB đều đang xử lý 5 lệnh khác nhau song song.
     - Đo lường thông lượng: 1 lệnh hoàn thành sau mỗi chu kỳ xung nhịp khi pipeline đã đầy.
- **Sản phẩm bàn giao:**
  - Báo cáo phân tích Waveform có chú thích rõ ràng 5 tầng pipeline.
  - File mã máy `pipeline_nop_test.hex`.
- **Tiêu chí nghiệm thu:**
  - [x] Dạng sóng thể hiện luồng lệnh đi xuyên suốt 5 tầng nhịp nhàng.
  - [x] Thanh ghi `x3` nhận đúng giá trị 40 sau khi kết thúc chuỗi lệnh.

---

### TUẦN 7: THIẾT KẾ FORWARDING UNIT (XỬ LÝ DATA HAZARD RAW)
- **Mục tiêu tuần:** Xử lý triệt để xung đột dữ liệu Read-After-Write (RAW) bằng kỹ thuật chuyển tiếp dữ liệu, loại bỏ hoàn toàn việc phải chèn NOP.
- **Công việc cụ thể:**
  1. Thiết kế module `forwarding_unit.sv`:
     - Nhận các đầu vào: `rs1_ex`, `rs2_ex`, `rd_mem`, `rd_wb`, `reg_write_mem`, `reg_write_wb`.
     - Hiện thực logic chuyển tiếp **EX Hazard (EX-to-EX)**: Từ thanh ghi `EX/MEM` về đầu vào ALU tầng EX.
     - Hiện thực logic chuyển tiếp **MEM Hazard (MEM-to-EX)**: Từ thanh ghi `MEM/WB` về đầu vào ALU tầng EX.
     - Hiện thực **Quy tắc ưu tiên (Priority Resolution)**: Khi cả tầng MEM và WB cùng ghi vào một thanh ghi đích trùng với `rs` của tầng EX, phải ưu tiên lấy từ tầng MEM.
     - Hiện thực **Ràng buộc loại trừ x0**: Tuyệt đối không forward khi thanh ghi đích là `x0` (`rd != 5'd0`).
  2. Bổ sung các Multiplexer 3-to-1 (`forward_a_mux`, `forward_b_mux`) trước ngõ vào ALU tại tầng EX.
  3. Viết bài test kiểm tra chuỗi RAW liên tiếp không có NOP (`raw_hazard_test.s`):
     - Kiểm tra chuỗi 3 lệnh liên tiếp dùng chung thanh ghi.
     - Kiểm tra trường hợp cả 2 toán hạng `rs1` và `rs2` đều cần forward đồng thời.
- **Sản phẩm bàn giao:**
  - File mã nguồn `rtl/core/forwarding_unit.sv`.
  - Testbench kiểm thử đơn vị `tb_forwarding.sv` và bài test CPU `raw_hazard_test.hex`.
- **Tiêu chí nghiệm thu:**
  - [x] `tb_forwarding.sv` xác nhận chọn đúng mã điều khiển Mux (00, 01, 10) cho mọi trường hợp.
  - [x] CPU chạy chuỗi lệnh phụ thuộc liên tiếp đạt kết quả chính xác 100% mà không cần bất kỳ lệnh NOP nào.

---

### TUẦN 8: THIẾT KẾ HAZARD DETECTION UNIT & XỬ LÝ CONTROL HAZARD
- **Mục tiêu tuần:** Xử lý trường hợp Load-Use Hazard (Stall & chèn Bubble) và giải quyết rẽ nhánh/nhảy (Predict Not-Taken & Flush sai nhánh).
- **Công việc cụ thể:**
  1. Thiết kế module `hazard_detection_unit.sv`:
     - Điều kiện bắt xung đột: `mem_read_ex && ((rd_ex == rs1_id) || (rd_ex == rs2_id)) && (rd_ex != 5'd0)`.
     - Tạo cơ chế Stall: Khóa PC (`pc_write_en = 0`), khóa thanh ghi `IF/ID` (`if_id_write_en = 0`), chèn Bubble vào `ID/EX` (`id_ex_flush = 1`).
  2. Thiết kế module `branch_comp.sv` và bộ tính toán địa chỉ nhảy tại tầng EX:
     - So sánh cả số có dấu (`BLT`, `BGE`) và không dấu (`BLTU`, `BGEU`), cùng `BEQ`, `BNE`.
     - Tính `pc_target` cho nhánh và `JAL`, `JALR` (`(rs1 + imm) & ~1`).
  3. Hiện thực cơ chế **Predict Not-Taken** và **Pipeline Flush**:
     - Mặc định IF nạp `PC + 4`.
     - Khi `branch_taken == 1` hoặc gặp lệnh Jump: Cập nhật PC theo `pc_target`, kích hoạt `if_id_flush = 1` và `id_ex_flush = 1` để xóa bỏ 2 lệnh nạp sai trên wrong-path.
  4. Viết các bài test kiểm chứng:
     - `load_use_test.s`: Kiểm tra lệnh Load ngay trước lệnh dùng, xác minh xuất hiện đúng 1 chu kỳ stall.
     - `branch_flush_test.s`: Đặt các lệnh ghi bộ nhớ ngay sau lệnh Branch Taken, xác minh các lệnh này bị xóa sạch và không để lại side-effect.
- **Sản phẩm bàn giao:**
  - Module `hazard_detection_unit.sv`, `branch_comp.sv`.
  - Các bài test kiểm tra stall và flush: `load_use_test.hex`, `branch_flush_test.hex`.
- **Tiêu chí nghiệm thu:**
  - [x] Xuất hiện đúng 1 chu kỳ Bubble khi có Load-Use hazard, dữ liệu sau đó được forward chính xác.
  - [x] Chi phí phạt đoán sai rẽ nhánh đo được đúng 2 chu kỳ clock; lệnh wrong-path không làm thay đổi trạng thái RegFile/RAM.

---

### TUẦN 9: NÂNG CẤP BỘ NHỚ DATA RAM & CHẠY ỨNG DỤNG THỰC TẾ
- **Mục tiêu tuần:** Hoàn thiện hỗ trợ toàn diện truy xuất bộ nhớ đa kích thước (Byte, Half-word, Word) và chạy thành công các thuật toán phức hợp.
- **Công việc cụ thể:**
  1. Nâng cấp `data_ram.sv` và khối căn chỉnh bộ nhớ:
     - Hỗ trợ tín hiệu `byte_enable[3:0]` cho các lệnh lưu: `SB` (1 byte), `SH` (2 bytes), `SW` (4 bytes).
     - Hỗ trợ mở rộng dấu và không dấu cho các lệnh nạp: `LB`, `LH`, `LBU`, `LHU`, `LW`.
     - Quy định rõ ràng hành vi đối với Misaligned Access (phớt lờ bit địa chỉ thấp không căn chỉnh để tránh trạng thái bất định).
  2. Viết Testbench kiểm tra truy xuất bộ nhớ con (`subword_mem_test.s`):
     - Ghi đan xen các byte và half-word vào các vị trí offset `0, 1, 2, 3` trong cùng một Word, sau đó đọc lại kiểm tra.
  3. Biên dịch và chạy 2 chương trình ứng dụng quy mô thực tế:
     - **Ứng dụng 1 (`fibonacci.s`):** Tính toán 10 số đầu tiên của dãy Fibonacci và lưu kết quả vào mảng trong RAM.
     - **Ứng dụng 2 (`bubble_sort.s`):** Sắp xếp một mảng gồm 8 số nguyên từ nhỏ đến lớn bằng thuật toán Sắp xếp nổi bọt trong RAM.
- **Sản phẩm bàn giao:**
  - Module `data_ram.sv` hoàn chỉnh.
  - Các chương trình ứng dụng: `fibonacci.hex`, `bubble_sort.hex`.
- **Tiêu chí nghiệm thu:**
  - [x] Các thao tác ghi byte không làm ảnh hưởng đến các byte khác trong cùng một Word.
  - [x] Thuật toán Fibonacci và Bubble Sort chạy kết thúc thành công, dữ liệu mảng trong RAM khớp 100% với kết quả toán học.

---

### TUẦN 10: XÂY DỰNG SELF-CHECKING TESTBENCH CẤP CPU & KIỂM THỬ TỰ ĐỘNG
- **Mục tiêu tuần:** Xây dựng môi trường kiểm chứng tự động cấp hệ thống, tự động đối chiếu chữ ký bộ nhớ (Memory Signature) và bổ sung kiểm thử ngẫu nhiên có ràng buộc.
- **Công việc cụ thể:**
  1. Xây dựng môi trường `tb_cpu_top.sv`:
     - Tự động nạp file mã máy `.hex` vào ROM, reset CPU và chạy đến khi gặp tín hiệu kết thúc chương trình.
     - Đọc vùng nhớ Signature Buffer trong RAM và so sánh tự động với mảng kết quả mong đợi (Golden Reference Model).
     - In kết quả ra màn hình console: `*** TEST PASSED ***` hoặc `*** TEST FAILED ***`.
  2. Bổ sung các bài kiểm thử định hướng (Directed Tests) quét qua 37 lệnh RV32I:
     - Đảm bảo kiểm tra các giá trị biên: `0x0000_0000`, `0xFFFF_FFFF`, `0x7FFF_FFFF`, `0x8000_0000` cho từng nhóm lệnh.
  3. Xây dựng bộ sinh chuỗi lệnh ngẫu nhiên có ràng buộc (Constrained-Random Generation):
     - Phát sinh ngẫu nhiên các tổ hợp lệnh, thanh ghi và khoảng cách phụ thuộc dữ liệu nhằm kích hoạt các tình huống tương tác khó phát hiện.
- **Sản phẩm bàn giao:**
  - File `testbench/cpu_tests/tb_cpu_top.sv`.
  - Bộ kịch bản kiểm thử tự động (Regression Test Suite).
- **Tiêu chí nghiệm thu:**
  - [x] Toàn bộ chuỗi bài kiểm thử chạy tự động và báo PASS mà không cần kiểm tra Waveform thủ công.
  - [x] Phát hiện chính xác và dừng mô phỏng khi cố tình chèn lỗi vào DUT.

---

### TUẦN 11: HIỆN THỰC TRỌN BỘ 8 SYSTEMVERILOG ASSERTIONS (SVA)
- **Mục tiêu tuần:** Áp dụng phương pháp kiểm chứng hiện đại bằng Assertion, cài đặt đầy đủ 8 SVA bắt buộc để giám sát các invariant và protocol nội bộ.
- **Công việc cụ thể:**
  1. Tạo file `assertions/riscv_sva.sv` và bind trực tiếp vào lõi vi xử lý:
     - **SVA 1 (`p_x0_always_zero`):** Kiểm tra thanh ghi `x0` luôn bằng 0 ở mọi chu kỳ clock.
     - **SVA 2 (`p_no_reg_write_when_disabled`):** Đảm bảo Register File không bị ghi đè khi `RegWrite = 0`.
     - **SVA 3 (`p_no_mem_write_when_disabled`):** Đảm bảo Data RAM không bị ghi đè khi `MemWrite = 0`.
     - **SVA 4 (`p_flush_no_architectural_update`):** Xác minh lệnh bị Flush không giữ lại các tín hiệu kích hoạt ghi.
     - **SVA 5 (`p_load_use_stall_behavior`):** Xác minh khi có Load-Use hazard thì PC và IF/ID bắt buộc phải stall đúng 1 chu kỳ.
     - **SVA 6 (`p_forwarding_priority_correct`):** Xác minh chọn đúng nguồn forwarding từ tầng MEM khi có xung đột trùng thanh ghi.
     - **SVA 7 (`p_branch_flush_wrong_path`):** Xác minh 2 lệnh wrong-path bị Flush hoàn toàn khi Branch Taken.
     - **SVA 8 (`p_pc_update_rules`):** Xác minh Program Counter tuân thủ quy tắc giữ nguyên khi stall và nhảy đúng khi branch/jump.
  2. Chạy toàn bộ Regression Test Suite với SVA được kích hoạt.
- **Sản phẩm bàn giao:**
  - File mã nguồn `assertions/riscv_sva.sv`.
  - Báo cáo log mô phỏng xác nhận trạng thái các Assertions.
- **Tiêu chí nghiệm thu:**
  - [x] Không có bất kỳ vi phạm Assertion nào (`0 SVA Violations`) trong suốt quá trình chạy toàn bộ các bài test.

---

### TUẦN 12: ĐÁNH GIÁ ĐỘ BAO PHỦ (FUNCTIONAL COVERAGE & CODE COVERAGE)
- **Mục tiêu tuần:** Xây dựng mô hình Functional Coverage, thu thập số liệu thống kê chứng minh thiết kế được kiểm chứng toàn diện với độ bao phủ đạt trên 90%.
- **Công việc cụ thể:**
  1. Xây dựng module `riscv_coverage.sv`:
     - Định nghĩa `covergroup cg_instruction`: Coverpoint cho toàn bộ 37 lệnh RV32I.
     - Định nghĩa `covergroup cg_hazards`:
       - Cross coverage giữa `forward_a` (00, 01, 10) và `forward_b` (00, 01, 10).
       - Coverpoint cho Load-Use stall trên cả toán hạng `rs1` và `rs2`.
     - Định nghĩa `covergroup cg_branch`: Coverpoint cho cả 2 trường hợp Taken và Not-Taken của cả 6 lệnh rẽ nhánh.
     - Định nghĩa `covergroup cg_memory`: Coverpoint cho các kích thước truy xuất Byte, Half-word, Word của cả lệnh Load và Store.
     - Cross coverage giữa các loại lệnh và các kịch bản hazard.
  2. Bật cờ thu thập Code Coverage (Statement, Branch, Toggle) trong công cụ mô phỏng.
  3. Phân tích lỗ hổng bao phủ (Coverage Hole Analysis):
     - Rà soát các bins chưa đạt 100%.
     - Viết bổ sung các test case có chủ đích để tăng độ bao phủ.
- **Sản phẩm bàn giao:**
  - File mã nguồn `testbench/coverage/riscv_coverage.sv`.
  - Báo cáo Coverage Report (dạng HTML hoặc text tóm tắt).
- **Tiêu chí nghiệm thu:**
  - [x] Functional Coverage đạt **tối thiểu 90%**.
  - [x] Các coverage holes còn lại được phân tích nguyên nhân và giải trình thỏa đáng.

---

### TUẦN 13: TỔNG HỢP RTL (SYNTHESIS) & TRIỂN KHAI TRÊN FPGA BOARD
- **Mục tiêu tuần:** Thực hiện tổng hợp phần cứng trên Vivado/Quartus, đảm bảo RTL synthesizable 100%, phân tích tài nguyên và $F_{max}$, triển khai kiểm chứng trên kit FPGA.
- **Công việc cụ thể:**
  1. Tiến hành RTL Analysis & Synthesis trên Xilinx Vivado hoặc Intel Quartus Prime:
     - Kiểm tra và loại bỏ triệt để mọi cảnh báo về **Inferred Latches** hoặc **Combinational Loops**.
     - Đạt kết quả **0 Errors** và không có cảnh báo nghiêm trọng.
  2. Trích xuất và phân tích báo cáo tài nguyên phần cứng:
     - Số lượng Look-Up Tables (LUTs) / Logic Elements (LEs).
     - Số lượng Flip-Flops / Registers.
     - Số lượng Block RAM (BRAM) sử dụng.
     - Phân tích đường trễ tới hạn (Critical Path) và xác định tần số xung nhịp tối đa đạt được ($F_{max}$).
  3. Triển khai phần cứng trên FPGA Board:
     - Viết wrapper module `fpga_top.sv` kết nối các chân vật lý của kit FPGA.
     - Kết nối hiển thị trạng thái và kết quả kiểm thử qua:
       - Hệ thống LED chỉ báo (LED xanh: PASS, LED đỏ: FAIL, LED nhấp nháy: Running).
       - LED 7 đoạn hiển thị giá trị thanh ghi hoặc 16-bit thấp của PC.
       - Giao tiếp UART truyền chuỗi thông báo kết quả kiểm thử về máy tính qua Serial Port.
- **Sản phẩm bàn giao:**
  - File dự án synthesis hoàn chỉnh và file bitstream (`.bit` hoặc `.sof`).
  - Bảng tổng hợp báo cáo tài nguyên và Timing Analysis.
  - Module `fpga_top.sv`, `uart_tx.sv`, `hex_display.sv`.
- **Tiêu chí nghiệm thu:**
  - [x] Thiết kế synthesizable thành công 100%, không có chốt ẩn ngoài chủ ý.
  - [x] Chương trình kiểm thử chạy thành công trên board FPGA, đèn LED hoặc UART báo kết quả PASS rõ ràng.

---

### TUẦN 14: HOÀN THIỆN BÁO CÁO THUYẾT MINH & BẢO VỆ ĐỒ ÁN
- **Mục tiêu tuần:** Đóng gói toàn bộ sản phẩm kỹ thuật thành tài liệu thuyết minh đồ án chuẩn mực khoa học, chuẩn bị slide và tập dượt bảo vệ tự tin trước Hội đồng.
- **Công việc cụ thể:**
  1. Soạn thảo Thuyết minh Đồ án 2 theo mẫu chuẩn của Khoa Kỹ thuật Máy tính:
     - **Chương 1:** Giới thiệu đề tài, kiến trúc tập lệnh RV32I và mục tiêu thiết kế.
     - **Chương 2:** Cơ sở lý thuyết về Pipeline 5 tầng và các kỹ thuật xử lý Hazard (Forwarding, Stall, Flush).
     - **Chương 3:** Thiết kế kiến trúc phần cứng chi tiết từng module bằng SystemVerilog (7 chức năng).
     - **Chương 4:** Môi trường kiểm chứng tự động: Self-checking Testbench, phân tích Waveform, kết quả 8 SVA và Functional Coverage.
     - **Chương 5:** Kết quả tổng hợp phần cứng trên FPGA, phân tích tài nguyên, tần số $F_{max}$ và kết quả chạy thực tế trên board.
     - **Kết luận & Hướng phát triển:** Đánh giá mức độ hoàn thành so với đề cương, hướng nâng cấp (Branch Prediction động, RV32M, Cache).
  2. Chuẩn bị Slide PowerPoint bảo vệ (15 - 20 slide ngắn gọn, tập trung hình ảnh sơ đồ khối và kết quả kiểm chứng).
  3. Quay video demo chạy mô phỏng tự động và chạy thực tế trên board FPGA để trình chiếu khi cần.
  4. Tập dượt vấn đáp các câu hỏi bảo vệ trọng tâm của Hội đồng.
- **Sản phẩm bàn giao:**
  - Cuốn Thuyết minh Đồ án 2 (file PDF và bản in hoàn chỉnh).
  - File Slide thuyết trình bảo vệ.
  - Video minh họa chạy mô phỏng và chạy thực tế trên phần cứng.
- **Tiêu chí nghiệm thu:**
  - [x] Tài liệu báo cáo chỉn chu, đầy đủ hình vẽ, sơ đồ và bảng số liệu thực nghiệm.
  - [x] Trình bày lưu loát, tự tin trả lời chính xác tất cả các câu hỏi phản biện của Hội đồng.

---

## 3. CHECKLIST ĐẠT ĐIỂM XUẤT SẮC (9.5 - 10) VỚI HỘI ĐỒNG CHẤM

- [ ] **Mã nguồn chuẩn mực công nghiệp:** Sử dụng đầy đủ `always_ff` và `always_comb` của SystemVerilog, không dùng Verilog-2001 lỗi thời; tên tín hiệu có hậu tố tầng (`_if`, `_id`, `_ex`, `_mem`, `_wb`) rõ ràng.
- [ ] **100% Không Latch ẩn:** Báo cáo Synthesis trên Vivado/Quartus chứng minh 0 Inferred Latches.
- [ ] **Kiểm chứng tự động (Self-checking):** Không dựa vào việc soi Waveform thủ công, testbench tự động đối chiếu Memory Signature và báo PASS/FAIL.
- [ ] **Đầy đủ 8 SVA Assertions:** Trình bày được log mô phỏng chứng minh không có vi phạm SVA trong toàn bộ chuỗi regression.
- [ ] **Functional Coverage $\ge 90\%$:** Có báo cáo HTML Coverage chi tiết và phân tích thấu đáo các Coverage Holes.
- [ ] **Triển khai thành công trên FPGA:** Có sản phẩm phần cứng thực tế chạy được thuật toán và hiển thị kết quả qua LED/UART.
- [ ] **Waveform chú thích chuyên nghiệp:** Các hình ảnh dạng sóng đưa vào báo cáo đều có khoanh vùng màu và chú thích mũi tên giải thích từng chu kỳ xung nhịp.

---

## 4. HỆ THỐNG 24 BÀI HỌC TƯƠNG TÁC ĐỒNG HÀNH
*(Hệ thống bài học được thiết kế bám sát từng nấc thang kỹ thuật, mỗi bài học kết thúc bằng 2-3 câu hỏi Checkpoint trọng tâm giúp sinh viên làm chủ kiến thức)*

| Tuần | Bài | Tên bài học | Nội dung trọng tâm | Câu hỏi Checkpoint củng cố kiến trúc |
| :---: | :---: | :--- | :--- | :--- |
| **T1** | **Bài 1** | Tổng quan RV32I & Thanh ghi `x0` | 32 thanh ghi 32-bit, quy tắc hardwired-to-zero của `x0`, kiến trúc Harvard. | 1. Tại sao thanh ghi `x0` bị khóa cứng bằng 0?<br>2. Sự khác biệt giữa kiến trúc Harvard và Von Neumann trong vi xử lý pipeline là gì? |
| | **Bài 2** | 6 Định dạng lệnh RV32I | Cấu trúc bit của R, I, S, B, U, J format; cách dịch tay lệnh `addi x1, x0, 10`. | 1. Nêu sự khác nhau về cấu trúc trường immediate giữa định dạng S và B?<br>2. Tại sao bit 0 của immediate trong lệnh Branch luôn ngầm định bằng 0? |
| | **Bài 3** | Cài đặt EDA & Cú pháp SystemVerilog | Thiết lập QuestaSim/ModelSim, phân biệt `always_comb` và `always_ff`. | 1. Tại sao không nên dùng `always @(*)` trong thiết kế mạch tổ hợp hiện đại?<br>2. Khái niệm Non-blocking (`<=`) và Blocking (`=`) assignment được dùng như thế nào? |
| **T2** | **Bài 4** | Thiết kế ALU 32-bit & Giá trị biên | Hiện thực 10 phép toán, so sánh có dấu/không dấu, dịch logic vs số học. | 1. Phép dịch `SRL` và `SRA` khác nhau như thế nào khi toán hạng đầu vào là số âm?<br>2. Tại sao cần kiểm tra các giá trị biên `0x7FFFFFFF` và `0x80000000`? |
| | **Bài 5** | Thiết kế Immediate Generator | Trích xuất và ghép các trường bit, mở rộng bit dấu 32-bit cho 5 format. | 1. Giải thích cú pháp replication operator `{{20{instr[31]}}, instr[31:20]}` trong SystemVerilog? |
| | **Bài 6** | Unit Testbench cho ALU & ImmGen | Tự động hóa kiểm thử đơn vị, tạo vector kích thích ngẫu nhiên và biên. | 1. Làm thế nào để testbench tự động so sánh kết quả ALU với giá trị tham chiếu mà không cần soi sóng? |
| **T3** | **Bài 7** | Thiết kế Register File (32x32) | 2 cổng đọc bất đồng bộ, 1 cổng ghi đồng bộ sườn dương, khóa cứng `x0`. | 1. Nếu trong cùng một chu kỳ clock, một lệnh đọc và một lệnh ghi vào cùng thanh ghi `x1`, điều gì xảy ra?<br>2. Viết đoạn code SystemVerilog bảo đảm `x0` không bao giờ bị ghi đè? |
| | **Bài 8** | Thiết kế Control Unit | Main Decoder theo `opcode` và ALU Decoder theo `funct3/funct7`. | 1. Tín hiệu `alu_src_b` bằng bao nhiêu khi thực thi lệnh `ADDI` so với lệnh `ADD`?<br>2. Làm sao để vô hiệu hóa an toàn các lệnh không hợp lệ (illegal instructions)? |
| | **Bài 9** | Thiết kế Instruction ROM & Data RAM | Đọc đồng bộ/bất đồng bộ, nạp file `.hex` qua `$readmemh`. | 1. Tại sao địa chỉ PC đưa vào ROM lại bỏ đi 2 bit cuối (`addr[11:2]`)? |
| **T4** | **Bài 10** | Tích hợp CPU Single-Cycle | Ghép PC, ROM, RegFile, ALU, RAM thành CPU 1 chu kỳ hoàn chỉnh. | 1. Yếu tố nào quyết định chu kỳ xung nhịp tối thiểu (tần số tối đa) của CPU Single-Cycle? |
| | **Bài 11** | Kiểm chứng Single-Cycle qua Waveform | Chạy chương trình ASM kiểm tra đầy đủ các họ lệnh R, I, S, B, J. | 1. Làm sao để nhận biết lệnh `BEQ` nhảy hay không nhảy trên cửa sổ Waveform? |
| **T5** | **Bài 12** | Phân chia Pipeline 5 tầng | Mô hình dây chuyền IF -> ID -> EX -> MEM -> WB, thông lượng và độ trễ. | 1. Pipeline làm tăng Throughput hay giảm Latency của một lệnh đơn lẻ? |
| | **Bài 13** | Thiết kế 4 Thanh ghi Pipeline | Đóng gói dữ liệu và truyền lan tín hiệu điều khiển dọc theo đường ống. | 1. Tại sao tín hiệu `reg_write` sinh ra từ tầng ID lại phải truyền qua ID/EX, EX/MEM rồi mới tới MEM/WB? |
| **T6** | **Bài 14** | Chạy Pipeline với lệnh NOP | Ghép CPU Pipeline cơ bản, quan sát lệnh đi qua 5 tầng bằng mắt. | 1. Cần chèn bao nhiêu lệnh NOP giữa hai lệnh có phụ thuộc dữ liệu trực tiếp nếu chưa có Forwarding Unit? |
| **T7** | **Bài 15** | Phân tích Data Hazard (RAW) | Bản chất xung đột Read-After-Write, phân biệt EX Hazard và MEM Hazard. | 1. Nêu điều kiện kiểm tra tồn tại EX Hazard và MEM Hazard cho toán hạng `rs1`? |
| | **Bài 16** | Thiết kế Forwarding Unit & Độ ưu tiên | Hiện thực `forwarding_unit.sv`, bộ Mux chọn nguồn, loại trừ `x0`. | 1. Khi cả tầng MEM và WB cùng ghi vào `x1`, Forwarding Unit sẽ ưu tiên lấy từ tầng nào? Vì sao?<br>2. Làm thế nào để không forward dữ liệu khi thanh ghi đích là `x0`? |
| **T8** | **Bài 17** | Xử lý Load-Use Hazard & Stall | Bản chất Load-Use, tại sao không forward được trong cùng chu kỳ, cơ chế Stall. | 1. Khi phát hiện Load-Use hazard, những thanh ghi nào bị khóa và tầng nào bị chèn Bubble? |
| | **Bài 18** | Control Hazard & Cơ chế Flush | Chiến lược Predict Not-Taken, so sánh nhánh, tính target, Flush 2 tầng. | 1. Tại sao chi phí phạt rẽ nhánh đoán sai là 2 chu kỳ clock mà không phải 1 chu kỳ?<br>2. Sự khác biệt giữa tín hiệu Stall và Flush ở mức phần cứng là gì? |
| **T9** | **Bài 19** | Nâng cấp Truy xuất Bộ nhớ Đa kích thước | Byte-enable mask cho `SB/SH/SW`, mở rộng dấu cho `LB/LH` và không dấu cho `LBU/LHU`. | 1. Nêu giá trị của `byte_enable[3:0]` khi thực hiện lệnh `SH` tại địa chỉ có `addr[1] == 1`?<br>2. Xử lý như thế nào khi phần mềm thực hiện truy xuất lệch biên (misaligned access)? |
| | **Bài 20** | Chạy Thuật toán Thực tế (Fibonacci & Sort)| Viết chương trình ASM tính Fibonacci và Bubble Sort, kiểm tra RAM. | 1. Làm thế nào để chương trình ASM báo hiệu cho Testbench biết thuật toán đã hoàn thành? |
| **T10**| **Bài 21** | Self-Checking Testbench & Signature Dump | Tự động hóa kiểm thử CPU, đối chiếu Memory Signature với Golden Model. | 1. Tại sao kiểm chứng tự động (Self-checking) là tiêu chuẩn bắt buộc trong thiết kế vi mạch hiện đại? |
| **T11**| **Bài 22** | Kiểm chứng với 8 SystemVerilog Assertions | Viết `riscv_sva.sv`, kiểm tra invariant `x0`, stall, flush, không ghi sai. | 1. Nêu cú pháp và ý nghĩa của toán tử `|->` (overlapping) và `|=>` (non-overlapping) trong SVA? |
| **T12**| **Bài 23** | Xây dựng Functional Coverage (>=90%) | Định nghĩa Covergroups, Coverpoints, Crosses, phân tích Coverage Holes. | 1. Functional Coverage khác với Code Coverage (Line, Branch, Toggle) ở điểm căn bản nào? |
| **T13-14**| **Bài 24** | Synthesis FPGA, Báo cáo & Bảo vệ | Chạy synthesis trên Vivado/Quartus, đo $F_{max}$, kết nối ngoại vi LED/UART. | 1. Các nguyên nhân phổ biến sinh ra Inferred Latch khi viết RTL và cách khắc phục triệt để?<br>2. Hãy trình bày tự tin cơ chế giải quyết Load-Use hazard trước câu hỏi của Hội đồng! |

---

## 5. KẾT LUẬN VÀ CAM KẾT TIẾN ĐỘ

Bản kế hoạch 14 tuần này phân bổ khối lượng công việc khoa học, cân đối giữa **Thiết kế phần cứng (Design)**, **Kiểm chứng chuyên nghiệp (Verification)** và **Hiện thực thực tế (FPGA Implementation)**. Việc bám sát kế hoạch hành động từng tuần và hoàn thành các checklist nghiệm thu sẽ đảm bảo sinh viên **Nguyễn Thành Trung** hoàn thành đồ án đúng hạn, đạt chất lượng kỹ thuật cao nhất và bảo vệ thành công rực rỡ trước Hội đồng Capstone Project II.
