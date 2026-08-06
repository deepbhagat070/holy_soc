`timescale 1ns / 1ps

module hazard_detection_unit(
    input  wire [4:0]  id_rs1_addr,
    input  wire [4:0]  id_rs2_addr,
    input  wire [4:0]  ex_rd_addr,
    input  wire        ex_MemRead,
    
    input  wire        is_system_id,
    input  wire [2:0]  id_funct3,
    input  wire [11:0] id_csr_addr,
    input  wire        ex_csr_we,
    input  wire [11:0] ex_csr_addr,
    input  wire        mem_csr_we,
    input  wire [11:0] mem_csr_addr,

    input  wire        if_req,
    input  wire        if_ready,
    input  wire        mem_req,
    input  wire        mem_ready,
    
    input  wire        trap_flush,
    input  wire        control_flush,
    input  wire        halt_cpu,

    output wire        pc_en,
    output wire        if_id_en,
    output wire        id_ex_en,
    output wire        ex_mem_en,
    output wire        mem_wb_en,
    
    output wire        if_id_clr,
    output wire        id_ex_clr
);

    wire icache_stall = if_req & ~if_ready;
    wire dcache_stall = mem_req & ~mem_ready;
    wire mem_stall    = icache_stall | dcache_stall;
    wire global_en    = ~mem_stall;


    wire load_use_hazard = ex_MemRead && (ex_rd_addr != 5'b0) && 
                           ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

    wire csr_hazard = is_system_id && (id_funct3 != 3'b000) && (
        (ex_csr_we  && (ex_csr_addr  == id_csr_addr)) ||
        (mem_csr_we && (mem_csr_addr == id_csr_addr))
    );

    wire reg_stall = load_use_hazard | csr_hazard;

    assign pc_en     = global_en & (trap_flush | ~reg_stall) & ~halt_cpu;
    assign if_id_en  = global_en & (trap_flush | ~reg_stall) & ~halt_cpu;
    assign id_ex_en  = global_en;
    assign ex_mem_en = global_en;
    assign mem_wb_en = global_en; 

    assign if_id_clr = global_en & (trap_flush | control_flush);
    assign id_ex_clr = global_en & (trap_flush | reg_stall);

endmodule