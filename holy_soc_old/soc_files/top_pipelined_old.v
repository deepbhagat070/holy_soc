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
    input  wire [31:0] dmem_rdata,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    input  wire        imem_ready,
    output wire        imem_req,
    output wire        icache_flush_out,
    output wire        dcache_flush_out,  
    input  wire        dcache_flush_done  
);

    wire        pc_en;
    wire        if_id_en;
    wire        if_id_clr;
    wire        id_ex_en;
    wire        id_ex_clr;
    wire        ex_mem_en;
    wire        mem_wb_en;
    
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

    pc my_pc (
        .clk        (clk), 
        .rst        (rst), 
        .pc_write   (1'b1), 
        .en         (pc_en),
        .pc_next    (if_pc_next), 
        .pc         (if_pc)
    );

    pc_adder my_pc_adder (
        .pc         (if_pc), 
        .pc_plus_4  (if_pc_plus_4)
    );

    assign imem_addr = if_pc;
    assign imem_req  = 1'b1; 
    assign if_instruction = imem_rdata;

    if_id_reg my_if_id_reg (
        .clk           (clk),
        .rst           (rst), 
        .clr           (if_id_clr), 
        .en            (if_id_en),  
        .if_pc         (if_pc),
        .if_pc_plus_4  (if_pc_plus_4),
        .if_instruction(if_instruction),
        .id_pc         (id_pc),
        .id_pc_plus_4  (id_pc_plus_4),
        .id_instruction(id_instruction)
    );

    wire        id_Branch, id_MemRead, id_MemWrite, id_ALUSrc;
    wire [1:0]  id_ALUSrcA, id_ALUOp, id_Jump;
    wire        id_RegWrite;
    wire [2:0]  id_ImmSrc, id_MemtoReg;
    wire [3:0]  id_ALU_Ctrl;
    wire        is_system_id, id_is_ecall, id_is_ebreak, id_csr_we, id_is_fence_i;

    reg fence_active;
    always @(posedge clk) begin
        if (rst) begin
            fence_active <= 1'b0;
        end else begin
            if (id_is_fence_i && !fence_active)
                fence_active <= 1'b1; // Lock stall
            else if (fence_active && dcache_flush_done)
                fence_active <= 1'b0; // Release stall
        end
    end

    assign dcache_flush_out = id_is_fence_i && !fence_active; 
    
    assign icache_flush_out = fence_active && dcache_flush_done;
    
    wire fence_stall = id_is_fence_i && (!fence_active || !dcache_flush_done);

    wire [4:0]  id_rs1_addr = id_instruction[19:15];
    wire [4:0]  id_rs2_addr = id_instruction[24:20];
    wire [31:0] id_rs1_data, id_rs2_data, id_imm_ext;
    wire        id_is_mret;  

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
        .is_mret    (id_is_mret),
        .MemtoReg  (id_MemtoReg),
        .id_csr_we (id_csr_we),
        .Is_System (is_system_id),
        .is_ecall  (id_is_ecall),
        .is_ebreak (id_is_ebreak),
        .is_fence_i(id_is_fence_i)
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

    wire [3:0] mem_we_map;
    wire dmem_req_active = mem_MemRead | (mem_we_map != 4'b0000);

    hazard_detection_unit my_hdu (
        .id_rs1_addr  (id_rs1_addr),
        .id_rs2_addr  (id_rs2_addr),
        .ex_rd_addr   (ex_rd_addr),
        .ex_MemRead   (ex_MemRead),
        .is_system_id (is_system_id),
        .id_funct3    (id_instruction[14:12]),
        .id_csr_addr  (id_csr_addr),
        .ex_csr_we    (ex_csr_we),
        .ex_csr_addr  (ex_csr_addr),
        .mem_csr_we   (mem_csr_we),
        .mem_csr_addr (mem_csr_addr),
        
        .if_req       (imem_req),
        .if_ready     (imem_ready),
        .mem_req      (dmem_req_active),
        .mem_ready    (dmem_ready),
        
        .trap_flush   (trap_flush),
        .control_flush(control_flush),
        .halt_cpu     (fence_stall),        
        .pc_en        (pc_en),
        .if_id_en     (if_id_en),
        .id_ex_en     (id_ex_en),
        .ex_mem_en    (ex_mem_en),
        .mem_wb_en    (mem_wb_en),
        .if_id_clr    (if_id_clr),
        .id_ex_clr    (id_ex_clr)
    );

    id_ex_reg my_id_ex_reg (
        .clk          (clk), 
        .rst          (rst),
        .en           (id_ex_en),
        .clr          (id_ex_clr),      
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

    wire [31:0] csr_mtvec, csr_mepc;
    wire        wb_is_ecall, wb_is_ebreak, wb_is_mret;
    
    wire csr_mie;
    wire async_irq = ext_irq & csr_mie; 
    wire wb_trap_taken = wb_is_ecall | wb_is_ebreak | async_irq; 
    
    assign if_pc_next = wb_trap_taken ? csr_mtvec : 
                        wb_is_mret    ? csr_mepc :
                        (id_Jump == 2'b10) ? ((branch_fwd_A + id_imm_ext) & 32'hFFFFFFFE) : 
                        (id_Jump == 2'b01 | branch_condition) ? id_branch_target : 
                        id_is_fence_i ? (id_pc + 32'd4) : 
                        if_pc_plus_4;
    
    assign control_flush = !id_ex_clr && (branch_condition || (id_Jump == 2'b01) || (id_Jump == 2'b10) || id_is_fence_i);

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
    
    wire [31:0] op_data = ex_ALUSrc ? ex_imm_ext : forward_rs1_data; 
    wire [31:0] ex_csr_wdata_computed;
    
    csr_alu u_csr_alu (
        .csr_rdata (ex_csr_rdata),        
        .op_data   (op_data),             
        .funct3    (ex_funct3),           
        .csr_wdata (ex_csr_wdata_computed)
    );
    
    wire [31:0] ex_branch_target = ex_pc + ex_imm_ext; 
    assign trap_flush = wb_trap_taken | wb_is_mret;

    ex_mem_reg my_ex_mem_reg (
        .clk              (clk), 
        .rst              (rst),
        .en               (ex_mem_en),
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
    
    mem_wb_reg my_mem_wb_reg (
        .clk              (clk), 
        .rst              (rst),
        .en               (mem_wb_en),
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

    wire [31:0] mem_shifted_wdata; 
    wire [31:0] raw_ram_out = dmem_rdata;

    store_decoder my_store_decoder (
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
