`timescale 1ns / 1ps

module top_pipelined (
    input  wire        clk,
    input  wire        rst,
    input  wire        dmem_ready,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_read_en,
    input  wire [31:0] dmem_rdata
);

    wire        pc_write;
    wire        if_id_write;
    wire        stall_mux;
    wire [1:0]  forward_A;
    wire [1:0]  forward_B;

    wire [31:0] id_pc;
    wire [31:0] id_pc_plus_4;
    wire [31:0] id_instruction;
    wire        control_flush; 

    wire [31:0] if_pc;
    wire [31:0] if_pc_plus_4;
    wire [31:0] if_pc_next;
    wire [31:0] if_instruction;

    wire halt_cpu = (id_instruction == 32'h00000073) && !control_flush;

    pc my_pc (
        .clk        (clk), 
        .rst        (rst), 
        .pc_write   (pc_write),
        .en         (dmem_ready && !halt_cpu), 
        .pc_next    (if_pc_next), 
        .pc         (if_pc)
    );

    pc_adder my_pc_adder (
        .pc         (if_pc), 
        .pc_plus_4  (if_pc_plus_4)
    );

    inst_mem my_rom (
        .pc         (if_pc), 
        .instruction(if_instruction)
    );

    if_id_reg my_if_id_reg (
        .clk           (clk),
        .rst           (rst),
        .flush         (control_flush),
        .if_id_write   (if_id_write),
        .if_pc         (if_pc),
        .en            (dmem_ready && !halt_cpu),
        .if_pc_plus_4  (if_pc_plus_4),
        .if_instruction(if_instruction),
        .id_pc         (id_pc),
        .id_pc_plus_4  (id_pc_plus_4),
        .id_instruction(id_instruction)
    );

    wire        id_Branch;
    wire        id_MemRead;
    wire        id_MemWrite;
    wire        id_ALUSrc;
    wire [1:0]  id_ALUSrcA;
    wire        id_RegWrite;
    wire [1:0]  id_ALUOp;
    wire [1:0]  id_Jump;
    wire [2:0]  id_ImmSrc;
    wire [2:0]  id_MemtoReg;
    wire [3:0]  id_ALU_Ctrl;

    wire [4:0]  id_rs1_addr = id_instruction[19:15];
    wire [4:0]  id_rs2_addr = id_instruction[24:20];
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_imm_ext;

    wire        mux_RegWrite = stall_mux ? 1'b0 : id_RegWrite;
    wire        mux_MemRead  = stall_mux ? 1'b0 : id_MemRead;
    wire        mux_MemWrite = stall_mux ? 1'b0 : id_MemWrite;
    wire        mux_ALUSrc   = stall_mux ? 1'b0 : id_ALUSrc;
    wire [1:0]  mux_ALUSrcA  = stall_mux ? 2'b00 : id_ALUSrcA;
    wire [3:0]  mux_ALU_Ctrl = stall_mux ? 4'b0 : id_ALU_Ctrl;
    wire [2:0]  mux_MemtoReg = stall_mux ? 3'b0 : id_MemtoReg;

    main_control my_main_control (
        .opcode   (id_instruction[6:0]), 
        .Branch   (id_Branch), 
        .MemRead  (id_MemRead), 
        .ALUOp    (id_ALUOp), 
        .MemWrite (id_MemWrite), 
        .ALUSrc   (id_ALUSrc), 
        .ALUSrcA  (id_ALUSrcA),
        .RegWrite (id_RegWrite), 
        .ImmSrc   (id_ImmSrc), 
        .Jump     (id_Jump),
        .MemtoReg (id_MemtoReg)
    );

    alu_control my_alu_control (
        .ALUOp    (id_ALUOp), 
        .funct3   (id_instruction[14:12]), 
        .bit30    (id_instruction[30]),
        .ALUSrc   (id_ALUSrc), 
        .ALU_Ctrl (id_ALU_Ctrl)
    );

    imm_gen my_imm_gen (
        .instruction(id_instruction), 
        .ImmSrc     (id_ImmSrc), 
        .imm_ext    (id_imm_ext)
    );

    wire        ex_RegWrite;
    wire        ex_MemRead;
    wire        ex_MemWrite;
    wire        ex_ALUSrc;
    wire [1:0]  ex_ALUSrcA;
    wire [2:0]  ex_MemtoReg;
    wire [2:0]  ex_funct3;
    wire [3:0]  ex_ALU_Ctrl;
    wire [31:0] ex_pc;
    wire [31:0] ex_pc_plus_4;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm_ext;
    wire [4:0]  ex_rd_addr;
    wire [4:0]  ex_rs1_addr;
    wire [4:0]  ex_rs2_addr;

    id_ex_reg my_id_ex_reg (
        .clk         (clk), 
        .rst         (rst),
        .en          (dmem_ready),
        .id_RegWrite (mux_RegWrite), 
        .id_MemtoReg (mux_MemtoReg), 
        .id_MemRead  (mux_MemRead),
        .id_MemWrite (mux_MemWrite), 
        .id_ALUSrc   (mux_ALUSrc), 
        .id_ALUSrcA  (mux_ALUSrcA),
        .id_ALU_Ctrl (mux_ALU_Ctrl),
        .id_funct3   (id_instruction[14:12]), 
        .id_pc       (id_pc), 
        .id_pc_plus_4(id_pc_plus_4),
        .id_rs1_data (id_rs1_data), 
        .id_rs2_data (id_rs2_data), 
        .id_imm_ext  (id_imm_ext),
        .id_rd_addr  (id_instruction[11:7]),
        .id_rs1_addr (id_rs1_addr), 
        .id_rs2_addr (id_rs2_addr),
        .ex_RegWrite (ex_RegWrite), 
        .ex_MemtoReg (ex_MemtoReg), 
        .ex_MemRead  (ex_MemRead),
        .ex_MemWrite (ex_MemWrite), 
        .ex_ALUSrc   (ex_ALUSrc), 
        .ex_ALUSrcA  (ex_ALUSrcA),
        .ex_funct3   (ex_funct3),
        .ex_ALU_Ctrl (ex_ALU_Ctrl), 
        .ex_pc       (ex_pc), 
        .ex_pc_plus_4(ex_pc_plus_4),
        .ex_rs1_data (ex_rs1_data), 
        .ex_rs2_data (ex_rs2_data), 
        .ex_imm_ext  (ex_imm_ext),
        .ex_rd_addr  (ex_rd_addr),
        .ex_rs1_addr (ex_rs1_addr),
        .ex_rs2_addr (ex_rs2_addr)
    );

    wire [31:0] ex_alu_result;
    reg  [31:0] forward_rs1_data;
    reg  [31:0] forward_rs2_data;
    wire [31:0] mem_alu_result;
    wire        mem_RegWrite;
    wire        mem_MemRead;
    wire        mem_MemWrite;
    wire [2:0]  mem_MemtoReg;
    wire [2:0]  mem_funct3;
    wire [31:0] mem_rs2_data;
    wire [31:0] mem_pc_plus_4;
    wire [31:0] mem_imm_ext;
    wire [31:0] mem_branch_target;
    wire [4:0]  mem_rd_addr;

    wire [31:0] wb_write_data;
    wire        wb_RegWrite;
    wire [4:0]  wb_rd_addr;
    wire [31:0] clean_data;

    reg [31:0] mem_forward_val;
    always @(*) begin
        case (mem_MemtoReg)
            3'b000:  mem_forward_val = mem_alu_result;
            3'b001:  mem_forward_val = clean_data;
            3'b010:  mem_forward_val = mem_pc_plus_4;
            3'b011:  mem_forward_val = mem_imm_ext;
            3'b100:  mem_forward_val = mem_branch_target;
            default: mem_forward_val = mem_alu_result;
        endcase
    end

    wire [31:0] branch_fwd_A = (id_rs1_addr != 5'b0 && id_rs1_addr == ex_rd_addr  && ex_RegWrite)  ? ex_alu_result :
                               (id_rs1_addr != 5'b0 && id_rs1_addr == mem_rd_addr && mem_RegWrite) ? mem_forward_val :
                               (id_rs1_addr != 5'b0 && id_rs1_addr == wb_rd_addr  && wb_RegWrite)  ? wb_write_data :
                               id_rs1_data;

    wire [31:0] branch_fwd_B = (id_rs2_addr != 5'b0 && id_rs2_addr == ex_rd_addr  && ex_RegWrite)  ? ex_alu_result :
                               (id_rs2_addr != 5'b0 && id_rs2_addr == mem_rd_addr && mem_RegWrite) ? mem_forward_val :
                               (id_rs2_addr != 5'b0 && id_rs2_addr == wb_rd_addr  && wb_RegWrite)  ? wb_write_data :
                               id_rs2_data;

    wire [31:0] id_branch_target = id_pc + id_imm_ext;
    
    reg branch_condition;
    always @(*) begin
        if (id_Branch) begin
            case(id_instruction[14:12])
                3'b000:  branch_condition = (branch_fwd_A == branch_fwd_B);
                3'b001:  branch_condition = (branch_fwd_A != branch_fwd_B);
                3'b100:  branch_condition = ($signed(branch_fwd_A) < $signed(branch_fwd_B));
                3'b101:  branch_condition = ($signed(branch_fwd_A) >= $signed(branch_fwd_B));
                3'b110:  branch_condition = (branch_fwd_A < branch_fwd_B);
                3'b111:  branch_condition = (branch_fwd_A >= branch_fwd_B);
                default: branch_condition = 1'b0;
            endcase
        end else begin
            branch_condition = 1'b0;
        end
    end

    assign if_pc_next = (id_Jump == 2'b10) ? ((branch_fwd_A + id_imm_ext) & 32'hFFFFFFFE) : 
                        (id_Jump == 2'b01 | branch_condition) ? id_branch_target : 
                        if_pc_plus_4;
    
    assign control_flush = !stall_mux && (branch_condition || (id_Jump == 2'b01) || (id_Jump == 2'b10));

    always @(*) begin
        case (forward_A) 
            2'b00 :  forward_rs1_data = ex_rs1_data;
            2'b10 :  forward_rs1_data = mem_forward_val;
            2'b01 :  forward_rs1_data = wb_write_data;
            default: forward_rs1_data = 32'b0;
        endcase
    end
    
    always @(*) begin
        case (forward_B) 
            2'b00 :  forward_rs2_data = ex_rs2_data;
            2'b10 :  forward_rs2_data = mem_forward_val;
            2'b01 :  forward_rs2_data = wb_write_data;
            default: forward_rs2_data = 32'b0;
        endcase
    end     

    wire [31:0] ex_alu_in2 = ex_ALUSrc ? ex_imm_ext : forward_rs2_data;
    
    wire [31:0] ex_alu_in1 = (ex_ALUSrcA == 2'b01) ? ex_pc :
                             (ex_ALUSrcA == 2'b10) ? 32'b0 :
                                                     forward_rs1_data;
    
    alu my_alu (
        .A         (ex_alu_in1), 
        .B         (ex_alu_in2), 
        .alu_ctrl  (ex_ALU_Ctrl), 
        .alu_result(ex_alu_result), 
        .zero      ()
    );

    wire [31:0] ex_branch_target = ex_pc + ex_imm_ext; 

    ex_mem_reg my_ex_mem_reg (
        .clk              (clk), 
        .rst              (rst),
        .en               (dmem_ready),
        .ex_RegWrite      (ex_RegWrite), 
        .ex_MemtoReg      (ex_MemtoReg), 
        .ex_MemRead       (ex_MemRead),
        .ex_MemWrite      (ex_MemWrite), 
        .ex_funct3        (ex_funct3), 
        .ex_alu_result    (ex_alu_result),
        .ex_rs2_data      (forward_rs2_data), 
        .ex_rd_addr       (ex_rd_addr), 
        .ex_pc_plus_4     (ex_pc_plus_4),
        .ex_imm_ext       (ex_imm_ext), 
        .ex_branch_target (ex_branch_target),
        .mem_RegWrite     (mem_RegWrite), 
        .mem_MemtoReg     (mem_MemtoReg), 
        .mem_MemRead      (mem_MemRead),
        .mem_MemWrite     (mem_MemWrite), 
        .mem_funct3       (mem_funct3), 
        .mem_alu_result   (mem_alu_result),
        .mem_rs2_data     (mem_rs2_data), 
        .mem_rd_addr      (mem_rd_addr), 
        .mem_pc_plus_4    (mem_pc_plus_4),
        .mem_imm_ext      (mem_imm_ext), 
        .mem_branch_target(mem_branch_target)
    );

    wire [2:0]  wb_MemtoReg;
    wire [31:0] wb_read_data;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_pc_plus_4;
    wire [31:0] wb_imm_ext;
    wire [31:0] wb_branch_target;

    mem_wb_reg my_mem_wb_reg (
        .clk              (clk), 
        .rst              (rst),
        .en               (dmem_ready),
        .mem_RegWrite     (mem_RegWrite), 
        .mem_MemtoReg     (mem_MemtoReg), 
        .mem_read_data    (clean_data),
        .mem_alu_result   (mem_alu_result), 
        .mem_rd_addr      (mem_rd_addr), 
        .mem_pc_plus_4    (mem_pc_plus_4),
        .mem_imm_ext      (mem_imm_ext), 
        .mem_branch_target(mem_branch_target),
        .wb_RegWrite      (wb_RegWrite), 
        .wb_MemtoReg      (wb_MemtoReg), 
        .wb_read_data     (wb_read_data),
        .wb_alu_result    (wb_alu_result), 
        .wb_rd_addr       (wb_rd_addr), 
        .wb_pc_plus_4     (wb_pc_plus_4),
        .wb_imm_ext       (wb_imm_ext), 
        .wb_branch_target (wb_branch_target)
    );

    reg [31:0] final_wb_data;
    always @(*) begin
        case (wb_MemtoReg)
            3'b000:  final_wb_data = wb_alu_result;     
            3'b001:  final_wb_data = wb_read_data;      
            3'b010:  final_wb_data = wb_pc_plus_4;      
            3'b011:  final_wb_data = wb_imm_ext;        
            3'b100:  final_wb_data = wb_branch_target;  
            default: final_wb_data = 32'b0;
        endcase
    end
    
    assign wb_write_data = final_wb_data;

    regfile my_regfile (
        .clk       (clk), 
        .we        (wb_RegWrite),                       
        .rs1_addr  (id_instruction[19:15]),       
        .rs2_addr  (id_instruction[24:20]), 
        .rd_addr   (wb_rd_addr),                    
        .write_data(wb_write_data),             
        .rs1_data  (id_rs1_data), 
        .rs2_data  (id_rs2_data)
    );

    forwarding_unit my_forwarding_unit (
        .id_ex_rs1      (ex_rs1_addr),      
        .id_ex_rs2      (ex_rs2_addr),      
        .ex_mem_rd      (mem_rd_addr),      
        .ex_mem_regwrite(mem_RegWrite),
        .mem_wb_rd      (wb_rd_addr),       
        .mem_wb_regwrite(wb_RegWrite), 
        .forward_A      (forward_A),        
        .forward_B      (forward_B)         
    );

    hazard_detection_unit my_hazard_unit (
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .ex_rd_addr (ex_rd_addr),
        .ex_MemRead (ex_MemRead),
        .pc_write   (pc_write),        
        .if_id_write(if_id_write), 
        .stall_mux  (stall_mux)      
    );

    // --- CHANGED HERE: Memory Interface Decoders & Assignments ---
    
    wire [3:0]  mem_we_map;
    wire [31:0] mem_shifted_wdata; // NEW: Wire for aligned store data
    wire [31:0] raw_ram_out = dmem_rdata;

    // UPDATED: Added rs2_data input and shifted_wdata output
    store_decoder my_store_decoder (
        .mem_MemWrite (mem_MemWrite), 
        .funct3       (mem_funct3), 
        .addr_align   (mem_alu_result[1:0]), 
        .rs2_data     (mem_rs2_data), 
        .we_map       (mem_we_map),
        .shifted_wdata(mem_shifted_wdata)
    );

    load_filter my_load_filter (
        .funct3      (mem_funct3), 
        .raw_ram_out (raw_ram_out), 
        .addr_align  (mem_alu_result[1:0]), 
        .clean_data  (clean_data)
    );

    // UPDATED: Force word alignment on addr, and drive shifted data
    assign dmem_addr    = {mem_alu_result[31:2], 2'b00};      
    assign dmem_wdata   = mem_shifted_wdata;       
    assign dmem_wstrb   = mem_we_map;          
    assign dmem_read_en = mem_MemRead;
    
    // -------------------------------------------------------------

endmodule