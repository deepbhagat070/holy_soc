`timescale 1ns / 1ps

module top_pipelined (
    input  wire        clk,
    input  wire        rst,
    input  wire        dmem_ready,
    input  wire        ext_irq,       
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_read_en,
    input  wire [31:0] dmem_rdata
);

    // --- PHASE 2: CENTRALIZED PIPELINE CONTROL SIGNALS ---
    wire        mem_stall;
    wire        reg_stall;
    wire        load_use_hazard;
    wire        PC_en;
    wire        IF_ID_en;
    wire        IF_ID_clr;
    wire        ID_EX_en;
    wire        ID_EX_clr;

    // OLD: 
    // wire        pc_write;
    // wire        if_id_write;
    // wire        stall_mux;
    
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

    wire        trap_flush;
    wire        halt_cpu = 1'b0; 

    // --- PHASE 2: PIPELINE REGISTER CONTROL EQUATIONS ---
    assign mem_stall = ~dmem_ready;
    assign PC_en     = ~mem_stall & (trap_flush | ~reg_stall) & ~halt_cpu;
    assign IF_ID_en  = ~mem_stall & (trap_flush | ~reg_stall) & ~halt_cpu;
    assign IF_ID_clr = ~mem_stall & (trap_flush | control_flush); 
    assign ID_EX_en  = ~mem_stall;
    assign ID_EX_clr = ~mem_stall & (trap_flush | reg_stall);


    pc my_pc (
        .clk        (clk), 
        .rst        (rst), 
        // OLD: .pc_write   (pc_write),
        .pc_write   (1'b1), 
        // OLD: .en         (dmem_ready && !halt_cpu), 
        .en         (PC_en),
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

    // OLD:
    // if_id_reg my_if_id_reg (
    //     .clk           (clk),
    //     .rst           (rst), 
    //     .flush         (control_flush | trap_flush),
    //     .if_id_write   (if_id_write),
    //     .if_pc         (if_pc),
    //     .en            (dmem_ready && !halt_cpu),
    //     .if_pc_plus_4  (if_pc_plus_4),
    //     .if_instruction(if_instruction),
    //     .id_pc         (id_pc),
    //     .id_pc_plus_4  (id_pc_plus_4),
    //     .id_instruction(id_instruction)
    // );
    
    // NEW:
    if_id_reg my_if_id_reg (
        .clk           (clk),
        .rst           (rst), 
        .clr           (IF_ID_clr), // Mapped to new centralized signal
        .en            (IF_ID_en),  // Mapped to new centralized signal
        .if_pc         (if_pc),
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
    wire        is_system_id;
    wire        id_is_ecall; 
    wire        id_is_ebreak; 
    wire        id_csr_we;

    wire [4:0]  id_rs1_addr = id_instruction[19:15];
    wire [4:0]  id_rs2_addr = id_instruction[24:20];
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_imm_ext;
    wire        id_is_mret  = is_system_id && (id_instruction[14:12] == 3'b000) && (id_instruction[31:20] == 12'h302);

    // --- PHASE 2: BUBBLE INJECTION MULTIPLEXERS REMOVED ---
    // Multiplexers removed from combinational path; bubble injection is now inside id_ex_reg
    // OLD: wire        mux_RegWrite  = stall_mux ? 1'b0 : id_RegWrite;
    // OLD: wire        mux_MemRead   = stall_mux ? 1'b0 : id_MemRead;
    // OLD: wire        mux_MemWrite  = stall_mux ? 1'b0 : id_MemWrite;
    // OLD: wire        mux_ALUSrc    = stall_mux ? 1'b0 : id_ALUSrc;
    // OLD: wire [1:0]  mux_ALUSrcA   = stall_mux ? 2'b00 : id_ALUSrcA;
    // OLD: wire [3:0]  mux_ALU_Ctrl  = stall_mux ? 4'b0 : id_ALU_Ctrl;
    // OLD: wire [2:0]  mux_MemtoReg  = stall_mux ? 3'b0 : id_MemtoReg;
    // OLD: wire        mux_csr_we    = stall_mux ? 1'b0 : id_csr_we;
    // OLD: wire        mux_is_ecall  = stall_mux ? 1'b0 : id_is_ecall;
    // OLD: wire        mux_is_ebreak = stall_mux ? 1'b0 : id_is_ebreak; 
    // OLD: wire        mux_is_mret   = stall_mux ? 1'b0 : id_is_mret;

    main_control my_main_control (
        .opcode    (id_instruction[6:0]),
        .funct3    (id_instruction[14:12]),
        .imm12     (id_instruction[31:20]),
        .rs1_addr  (id_rs1_addr), 
        .Branch    (id_Branch),
        .MemRead   (id_MemRead),
        .ALUOp     (id_ALUOp),
        .MemWrite  (id_MemWrite),
        .ALUSrc    (id_ALUSrc),
        .ALUSrcA   (id_ALUSrcA),
        .RegWrite  (id_RegWrite),
        .ImmSrc    (id_ImmSrc),
        .Jump      (id_Jump),
        .MemtoReg  (id_MemtoReg),
        .id_csr_we (id_csr_we),
        .Is_System (is_system_id),
        .is_ecall  (id_is_ecall),
        .is_ebreak (id_is_ebreak) 
    );

    wire [11:0] id_csr_addr = id_instruction[31:20];
    wire [31:0] id_csr_rdata_raw;
    
    wire        wb_csr_we;
    wire [11:0] wb_csr_addr;
    wire [31:0] wb_csr_wdata;
    wire [31:0] id_csr_rdata = (wb_csr_we && (wb_csr_addr == id_csr_addr)) ? wb_csr_wdata : id_csr_rdata_raw;

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
    
    wire [31:0] ex_alu_result, mem_alu_result;
    reg  [31:0] forward_rs1_data, forward_rs2_data;
    wire        mem_RegWrite, mem_MemRead, mem_MemWrite;
    wire [2:0]  mem_MemtoReg, mem_funct3;
    wire [31:0] mem_rs2_data, mem_pc_plus_4, mem_imm_ext, mem_branch_target, mem_pc;
    wire [4:0]  mem_rd_addr;
    wire        mem_is_ecall, mem_is_ebreak, mem_is_mret, mem_csr_we;
    wire [11:0] mem_csr_addr;
    wire [31:0] mem_csr_wdata, mem_csr_rdata;

    wire [31:0] wb_write_data;
    wire        wb_RegWrite;
    wire [4:0]  wb_rd_addr;
    wire [31:0] clean_data;

    reg [31:0] mem_forward_val;
    
    wire        ex_RegWrite, ex_MemRead, ex_MemWrite, ex_ALUSrc;
    wire [1:0]  ex_ALUSrcA;
    wire [2:0]  ex_MemtoReg, ex_funct3;
    wire [3:0]  ex_ALU_Ctrl;
    wire [31:0] ex_pc, ex_pc_plus_4, ex_rs1_data, ex_rs2_data, ex_imm_ext;
    wire [4:0]  ex_rd_addr, ex_rs1_addr, ex_rs2_addr;
    wire        ex_is_ecall, ex_is_ebreak, ex_is_mret, ex_csr_we;
    wire [11:0] ex_csr_addr;
    wire [31:0] ex_csr_rdata;
    wire [31:0] branch_fwd_A = (id_rs1_addr != 5'b0 && id_rs1_addr == ex_rd_addr  && ex_RegWrite)  ? ex_alu_result :
                               (id_rs1_addr != 5'b0 && id_rs1_addr == mem_rd_addr && mem_RegWrite) ? mem_forward_val :
                               (id_rs1_addr != 5'b0 && id_rs1_addr == wb_rd_addr  && wb_RegWrite)  ? wb_write_data :
                               id_rs1_data;

    // OLD:
    // id_ex_reg my_id_ex_reg (
    //     .clk          (clk), 
    //     .rst          (rst),
    //     .en           (dmem_ready),
    //     .id_RegWrite  (mux_RegWrite & ~trap_flush), 
    //     .id_MemtoReg  (mux_MemtoReg), 
    //     .id_MemRead   (mux_MemRead),
    //     .id_MemWrite  (mux_MemWrite & ~trap_flush), 
    //     .id_ALUSrc    (mux_ALUSrc), 
    //     .id_ALUSrcA   (mux_ALUSrcA),
    //     .id_ALU_Ctrl  (mux_ALU_Ctrl),
    //     .id_funct3    (id_instruction[14:12]), 
    //     .id_pc        (id_pc), 
    //     .id_pc_plus_4 (id_pc_plus_4),
    //     .id_rs1_data  (id_rs1_data), 
    //     .id_rs2_data  (id_rs2_data), 
    //     .id_imm_ext   (id_imm_ext),
    //     .id_rd_addr   (id_instruction[11:7]),
    //     .id_rs1_addr  (id_rs1_addr), 
    //     .id_rs2_addr  (id_rs2_addr),
    //     .id_is_mret   (mux_is_mret),
    //     .id_is_ecall  (mux_is_ecall),
    //     .id_is_ebreak (mux_is_ebreak), 
    //     .id_csr_we    (mux_csr_we & ~trap_flush),
    //     .id_csr_addr  (id_csr_addr),
    //     .id_csr_rdata (id_csr_rdata),
    //     ... (ex outputs)
    // );
    
    // NEW: Direct connection of control signals. Multiplexing replaced by clr port.
    id_ex_reg my_id_ex_reg (
        .clk          (clk), 
        .rst          (rst),
        .en           (ID_EX_en),
        .clr          (ID_EX_clr),      // Handled internally now
        .id_RegWrite  (id_RegWrite),    
        .id_MemtoReg  (id_MemtoReg), 
        .id_MemRead   (id_MemRead),
        .id_MemWrite  (id_MemWrite), 
        .id_ALUSrc    (id_ALUSrc), 
        .id_ALUSrcA   (id_ALUSrcA),
        .id_ALU_Ctrl  (id_ALU_Ctrl),
        .id_funct3    (id_instruction[14:12]), 
        .id_pc        (id_pc), 
        .id_pc_plus_4 (id_pc_plus_4),
        .id_rs1_data  (id_rs1_data), 
        .id_rs2_data  (id_rs2_data), 
        .id_imm_ext   (id_imm_ext),
        .id_rd_addr   (id_instruction[11:7]),
        .id_rs1_addr  (id_rs1_addr), 
        .id_rs2_addr  (id_rs2_addr),
        
        .id_is_mret   (id_is_mret),     
        .id_is_ecall  (id_is_ecall),    
        .id_is_ebreak (id_is_ebreak),   
        .id_csr_we    (id_csr_we),      
        .id_csr_addr  (id_csr_addr),
        .id_csr_rdata (id_csr_rdata), 

        .ex_RegWrite  (ex_RegWrite), 
        .ex_MemtoReg  (ex_MemtoReg), 
        .ex_MemRead   (ex_MemRead),
        .ex_MemWrite  (ex_MemWrite), 
        .ex_ALUSrc    (ex_ALUSrc), 
        .ex_ALUSrcA   (ex_ALUSrcA),
        .ex_funct3    (ex_funct3),
        .ex_ALU_Ctrl  (ex_ALU_Ctrl), 
        .ex_pc        (ex_pc), 
        .ex_pc_plus_4 (ex_pc_plus_4),
        .ex_rs1_data  (ex_rs1_data), 
        .ex_rs2_data  (ex_rs2_data), 
        .ex_imm_ext   (ex_imm_ext),
        .ex_rd_addr   (ex_rd_addr),
        .ex_rs1_addr  (ex_rs1_addr),
        .ex_rs2_addr  (ex_rs2_addr),
        .ex_is_mret   (ex_is_mret),
        .ex_is_ecall  (ex_is_ecall),
        .ex_is_ebreak (ex_is_ebreak), 
        .ex_csr_we    (ex_csr_we),
        .ex_csr_addr  (ex_csr_addr),
        .ex_csr_rdata (ex_csr_rdata) 
    );

    always @(*) begin
        case (mem_MemtoReg)
            3'b000:  mem_forward_val = mem_alu_result;
            3'b001:  mem_forward_val = clean_data;
            3'b010:  mem_forward_val = mem_pc_plus_4;
            3'b011:  mem_forward_val = mem_imm_ext;
            3'b100:  mem_forward_val = mem_branch_target;
            3'b101:  mem_forward_val = mem_csr_rdata; 
            default: mem_forward_val = mem_alu_result;
        endcase
    end

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

    wire [31:0] csr_mtvec, csr_mepc;
    wire        wb_is_ecall, wb_is_ebreak, wb_is_mret;
    
    wire csr_mie;
    wire async_irq = ext_irq & csr_mie; 
    wire wb_trap_taken = wb_is_ecall | wb_is_ebreak | async_irq; 
    
    assign if_pc_next = wb_trap_taken ? csr_mtvec : 
                        wb_is_mret    ? csr_mepc :
                        (id_Jump == 2'b10) ? ((branch_fwd_A + id_imm_ext) & 32'hFFFFFFFE) : 
                        (id_Jump == 2'b01 | branch_condition) ? id_branch_target : 
                        if_pc_plus_4;
    
    // OLD: assign control_flush = !stall_mux && (branch_condition || (id_Jump == 2'b01) || (id_Jump == 2'b10));
    assign control_flush = !ID_EX_clr && (branch_condition || (id_Jump == 2'b01) || (id_Jump == 2'b10));

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
                             (ex_ALUSrcA == 2'b10) ? 32'b0 : forward_rs1_data;
    
    alu my_alu (
        .A         (ex_alu_in1), 
        .B         (ex_alu_in2), 
        .alu_ctrl  (ex_ALU_Ctrl), 
        .alu_result(ex_alu_result), 
        .zero      ()
    );
    
    wire [31:0] op_data;
    wire [31:0] ex_csr_wdata_computed;
    
    assign op_data = ex_ALUSrc ? ex_imm_ext : forward_rs1_data; 
    
    csr_alu u_csr_alu (
        .csr_rdata (ex_csr_rdata),        
        .op_data   (op_data),             
        .funct3    (ex_funct3),           
        .csr_wdata (ex_csr_wdata_computed)
    );
    
    wire [31:0] ex_branch_target = ex_pc + ex_imm_ext; 

    // OLD:
    // ex_mem_reg my_ex_mem_reg (
    //     .clk              (clk), 
    //     .rst              (rst),
    //     .en               (dmem_ready),
    //     .ex_RegWrite      (ex_RegWrite & ~trap_flush), 
    //     .ex_MemtoReg      (ex_MemtoReg), 
    //     .ex_MemRead       (ex_MemRead),
    //     .ex_MemWrite      (ex_MemWrite & ~trap_flush), 
    //     .ex_funct3        (ex_funct3), 
    //     ... (and other maskings with ~trap_flush)
    // );
    
    assign trap_flush = wb_trap_taken | wb_is_mret;

    // NEW: trap_flush masking handled by internal clr logic
    ex_mem_reg my_ex_mem_reg (
        .clk              (clk), 
        .rst              (rst),
        .en               (~mem_stall),
        .clr              (trap_flush),
        .ex_RegWrite      (ex_RegWrite), 
        .ex_MemtoReg      (ex_MemtoReg), 
        .ex_MemRead       (ex_MemRead),
        .ex_MemWrite      (ex_MemWrite), 
        .ex_funct3        (ex_funct3), 
        .ex_alu_result    (ex_alu_result),
        .ex_rs2_data      (forward_rs2_data), 
        .ex_rd_addr       (ex_rd_addr), 
        .ex_pc_plus_4     (ex_pc_plus_4),
        .ex_pc            (ex_pc),
        .ex_imm_ext       (ex_imm_ext), 
        .ex_branch_target (ex_branch_target),
        .ex_is_ecall      (ex_is_ecall),
        .ex_is_ebreak     (ex_is_ebreak), 
        .ex_is_mret       (ex_is_mret),
        
        .ex_csr_we        (ex_csr_we),
        .ex_csr_addr      (ex_csr_addr),
        .ex_csr_wdata     (ex_csr_wdata_computed), 
        .ex_csr_rdata     (ex_csr_rdata),

        .mem_RegWrite     (mem_RegWrite), 
        .mem_MemtoReg     (mem_MemtoReg), 
        .mem_MemRead      (mem_MemRead),
        .mem_MemWrite     (mem_MemWrite), 
        .mem_funct3       (mem_funct3), 
        .mem_alu_result   (mem_alu_result),
        .mem_rs2_data     (mem_rs2_data), 
        .mem_rd_addr      (mem_rd_addr), 
        .mem_pc_plus_4    (mem_pc_plus_4),
        .mem_pc           (mem_pc),
        .mem_imm_ext      (mem_imm_ext),
        .mem_is_ecall     (mem_is_ecall),
        .mem_is_ebreak    (mem_is_ebreak), 
        .mem_is_mret      (mem_is_mret),
        .mem_branch_target(mem_branch_target),
        
        .mem_csr_we       (mem_csr_we),
        .mem_csr_addr     (mem_csr_addr),
        .mem_csr_wdata    (mem_csr_wdata),
        .mem_csr_rdata    (mem_csr_rdata)
    );

    wire [31:0] wb_csr_rdata;
    wire [2:0]  wb_MemtoReg;
    wire [31:0] wb_read_data, wb_alu_result, wb_pc_plus_4, wb_imm_ext, wb_branch_target, wb_pc;
    
    // OLD:
    // wire gated_wb_RegWrite = mem_RegWrite & ~trap_flush;
    // wire gated_wb_MemWrite = mem_MemWrite & ~trap_flush;
    // wire gated_wb_csr_we   = mem_csr_we   & ~trap_flush;
    // mem_wb_reg my_mem_wb_reg ( ... passed gated signals ... );

    // NEW: Gated signals removed, internal clr logic used
    mem_wb_reg my_mem_wb_reg (
        .clk              (clk), 
        .rst              (rst),
        .en               (~mem_stall),
        .clr              (trap_flush),
        .mem_RegWrite     (mem_RegWrite), 
        .mem_MemtoReg     (mem_MemtoReg), 
        .mem_read_data    (clean_data),
        .mem_alu_result   (mem_alu_result), 
        .mem_rd_addr      (mem_rd_addr), 
        .mem_pc_plus_4    (mem_pc_plus_4),
        .mem_imm_ext      (mem_imm_ext), 
        .mem_branch_target(mem_branch_target),
        .mem_is_ecall     (mem_is_ecall),
        .mem_is_ebreak    (mem_is_ebreak), 
        .mem_is_mret      (mem_is_mret),
        .mem_pc           (mem_pc),
        .mem_csr_we       (mem_csr_we),
        .mem_csr_addr     (mem_csr_addr),
        .mem_csr_wdata    (mem_csr_wdata),
        .mem_csr_rdata    (mem_csr_rdata),

        .wb_RegWrite      (wb_RegWrite), 
        .wb_MemtoReg      (wb_MemtoReg), 
        .wb_read_data     (wb_read_data),
        .wb_alu_result    (wb_alu_result), 
        .wb_rd_addr       (wb_rd_addr), 
        .wb_pc_plus_4     (wb_pc_plus_4),
        .wb_imm_ext       (wb_imm_ext), 
        .wb_branch_target (wb_branch_target),
        .wb_is_ecall      (wb_is_ecall),
        .wb_is_ebreak     (wb_is_ebreak), 
        .wb_is_mret       (wb_is_mret),
        .wb_pc            (wb_pc),
        .wb_csr_we        (wb_csr_we),
        .wb_csr_addr      (wb_csr_addr),
        .wb_csr_wdata     (wb_csr_wdata),
        .wb_csr_rdata     (wb_csr_rdata)
    );

    wire [31:0] exception_cause = async_irq    ? {1'b1, 31'd11} :
                                  wb_is_ecall  ? 32'd11 : 
                                  wb_is_ebreak ? 32'd3 : 32'd0;
                                  
    wire [31:0] commit_pc = async_irq ? mem_pc : wb_pc;

    csr_file sys_csr (
        .clk          (clk),
        .rst          (rst),
        .ext_irq      (ext_irq),       
        .csr_raddr    (id_csr_addr),
        .csr_waddr    (wb_csr_addr),
        .csr_we       (wb_csr_we),
        .csr_wdata    (wb_csr_wdata),
        .csr_rdata    (id_csr_rdata_raw),
        .trap_taken   (wb_trap_taken), 
        .trap_pc      (commit_pc),     
        .trap_cause   (exception_cause), 
        .trap_val     (32'd0),
        .mret_taken   (wb_is_mret),
        .mtvec_out    (csr_mtvec),
        .mepc_out     (csr_mepc),
        .mie_out      (csr_mie)        
    );

    reg [31:0] final_wb_data;
    always @(*) begin
        case (wb_MemtoReg)
            3'b000:  final_wb_data = wb_alu_result;     
            3'b001:  final_wb_data = wb_read_data;      
            3'b010:  final_wb_data = wb_pc_plus_4;      
            3'b011:  final_wb_data = wb_imm_ext;        
            3'b100:  final_wb_data = wb_branch_target;  
            3'b101:  final_wb_data = wb_csr_rdata;      
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

    // --- PHASE 2: INLINE HAZARD DETECTION ---
    // OLD: wire base_pc_write;
    // OLD: wire base_if_id_write;
    // OLD: wire base_stall_mux;

    // OLD: hazard_detection_unit my_hazard_unit (
    // OLD:     .id_rs1_addr(id_rs1_addr),
    // OLD:     .id_rs2_addr(id_rs2_addr),
    // OLD:     .ex_rd_addr (ex_rd_addr),
    // OLD:     .ex_MemRead (ex_MemRead),
    // OLD:     .pc_write   (base_pc_write),        
    // OLD:     .if_id_write(base_if_id_write), 
    // OLD:     .stall_mux  (base_stall_mux)      
    // OLD: );

    // NEW: Inline continuous assignment for hazard condition
    assign load_use_hazard = ex_MemRead && (ex_rd_addr != 5'b0) && 
                             ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

    wire csr_hazard = is_system_id && (id_instruction[14:12] != 3'b000) && (
        (ex_csr_we  && (ex_csr_addr  == id_csr_addr)) ||
        (mem_csr_we && (mem_csr_addr == id_csr_addr))
    );

    // OLD: assign pc_write    = base_pc_write & ~csr_hazard;
    // OLD: assign if_id_write = base_if_id_write & ~csr_hazard;
    // OLD: assign stall_mux   = base_stall_mux | csr_hazard;
    
    // NEW: Unified hazard generation 
    assign reg_stall = load_use_hazard | csr_hazard;

    wire [3:0]  mem_we_map;
    wire [31:0] mem_shifted_wdata; 
    wire [31:0] raw_ram_out = dmem_rdata;

    store_decoder my_store_decoder (
        // Because exception mask is handled in EX/MEM clr port, we still need this local mask 
        // to prevent false memory writes on the cycle the trap resolves
        .mem_MemWrite (mem_MemWrite & ~trap_flush), 
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

    assign dmem_addr    = {mem_alu_result[31:2], 2'b00};      
    assign dmem_wdata   = mem_shifted_wdata;        
    assign dmem_wstrb   = mem_we_map;           
    assign dmem_read_en = mem_MemRead;
    
endmodule