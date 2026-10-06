`timescale 1ns / 1ps

module dcache (
    input wire clk,
    input wire rst,

    // CPU Interface
    input  wire        cpu_req,      // CPU is requesting a memory operation
    input  wire [31:0] cpu_addr,
    input  wire        cpu_we,       // 1 for Write, 0 for Read
    input  wire [31:0] cpu_wdata,
    input  wire [3:0]  cpu_wstrb,
    output reg  [31:0] cpu_rdata,
    output wire        cpu_ready,    // 1 when hit or operation complete, 0 when stalling

    // Bus Interface (to Fake Memory / Arbiter)
    output reg         bus_req,
    output reg  [31:0] bus_addr,
    output reg         bus_we,
    output reg  [31:0] bus_wdata,
    output reg  [3:0]  bus_wstrb,
    input  wire [31:0] bus_rdata,
    input  wire        bus_ready     // Memory signals read/write is complete
);

    // ==========================================
    // 1. Cache Geometry & Addressing
    // ==========================================
    // Total Size: 1KB
    // Line Size: 16 Bytes (4 words)
    // Number of Lines: 1024 / 16 = 64 lines
    
    wire [3:0]  offset      = cpu_addr[3:0];
    wire [1:0]  word_offset = cpu_addr[3:2]; // 00, 01, 10, 11
    wire [5:0]  index       = cpu_addr[9:4];
    wire [21:0] tag         = cpu_addr[31:10];
    
    // The Hardware Switch: MSB (addr[31])
    // 0 = Cacheable (Boot ROM 0x0..., Main RAM 0x4...)
    // 1 = Non-Cacheable (MMIO 0x8..., Reserved 0xC...)
    wire is_cacheable = (cpu_addr[31] == 1'b0);

    // ==========================================
    // 2. Cache Storage Arrays
    // ==========================================
    reg [127:0] data_array  [0:63]; // 4 words per line
    reg [21:0]  tag_array   [0:63];
    reg         valid_array [0:63];

    // Combinational read of the arrays
    wire [127:0] cache_line  = data_array[index];
    wire [21:0]  cache_tag   = tag_array[index];
    wire         cache_valid = valid_array[index];

    wire is_hit = cache_valid && (cache_tag == tag);

    // ==========================================
    // 3. Finite State Machine
    // ==========================================
    localparam IDLE          = 3'd0;
    localparam BYPASS_READ   = 3'd1;
    localparam BYPASS_WRITE  = 3'd2;
    localparam WRITE_THROUGH = 3'd3;
    localparam REFILL_W0     = 3'd4;
    localparam REFILL_W1     = 3'd5;
    localparam REFILL_W2     = 3'd6;
    localparam REFILL_W3     = 3'd7;

    reg [2:0] state, next_state;

    // Temporary storage for cache line refill
    reg [31:0] fill_buf [0:3];

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cpu_req) begin
                    if (!is_cacheable) begin
                        next_state = cpu_we ? BYPASS_WRITE : BYPASS_READ;
                    end else begin
                        if (cpu_we) begin
                            next_state = WRITE_THROUGH;
                        end else if (!is_hit) begin
                            next_state = REFILL_W0; // Read Miss
                        end
                    end
                end
            end
            
            BYPASS_READ, BYPASS_WRITE, WRITE_THROUGH: begin
                if (bus_ready) next_state = IDLE;
            end
            
            REFILL_W0: if (bus_ready) next_state = REFILL_W1;
            REFILL_W1: if (bus_ready) next_state = REFILL_W2;
            REFILL_W2: if (bus_ready) next_state = REFILL_W3;
            REFILL_W3: if (bus_ready) next_state = IDLE; // Line filled, ready to serve CPU on next cycle

            default: next_state = IDLE;
        endcase
    end

    // Sequential logic (State + Data Updates)
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            for (i = 0; i < 64; i = i + 1) begin
                valid_array[i] <= 1'b0;
            end
        end else begin
            state <= next_state;
            
            // Handle Write-Through Hit (Update local copy)
            if (state == WRITE_THROUGH && bus_ready && is_hit) begin
                if (cpu_wstrb[0]) data_array[index][{word_offset, 5'd0} +: 8]  <= cpu_wdata[7:0];
                if (cpu_wstrb[1]) data_array[index][{word_offset, 5'd8} +: 8]  <= cpu_wdata[15:8];
                if (cpu_wstrb[2]) data_array[index][{word_offset, 5'd16} +: 8] <= cpu_wdata[23:16];
                if (cpu_wstrb[3]) data_array[index][{word_offset, 5'd24} +: 8] <= cpu_wdata[31:24];
            end
            
            // Store fetched words during refill
            if (bus_ready) begin
                if (state == REFILL_W0) fill_buf[0] <= bus_rdata;
                if (state == REFILL_W1) fill_buf[1] <= bus_rdata;
                if (state == REFILL_W2) fill_buf[2] <= bus_rdata;
                if (state == REFILL_W3) begin
                    // Entire line is fetched, write to cache array
                    data_array[index] <= {bus_rdata, fill_buf[2], fill_buf[1], fill_buf[0]};
                    tag_array[index]  <= tag;
                    valid_array[index] <= 1'b1;
                end
            end
        end
    end

    // ==========================================
    // 4. Output Logic
    // ==========================================
    
    // CPU Ready signal
    assign cpu_ready = (state == IDLE && cpu_req && is_cacheable && !cpu_we && is_hit) || // Read Hit
                       (state == BYPASS_READ   && bus_ready) ||
                       (state == BYPASS_WRITE  && bus_ready) ||
                       (state == WRITE_THROUGH && bus_ready); // Writes finish when bus acknowledges

    // CPU Read Data routing
    always @(*) begin
        if (state == BYPASS_READ) begin
            cpu_rdata = bus_rdata;
        end else begin
            // Extract the requested word from the cache line
            case (word_offset)
                2'b00: cpu_rdata = cache_line[31:0];
                2'b01: cpu_rdata = cache_line[63:32];
                2'b10: cpu_rdata = cache_line[95:64];
                2'b11: cpu_rdata = cache_line[127:96];
            endcase
        end
    end

    // Bus Output driving
    wire [31:0] base_line_addr = {cpu_addr[31:4], 4'h0}; // 16-byte aligned

    always @(*) begin
        bus_req   = 1'b0;
        bus_addr  = 32'b0;
        bus_we    = 1'b0;
        bus_wdata = cpu_wdata;
        bus_wstrb = cpu_wstrb;

        case (state)
            BYPASS_READ: begin
                bus_req  = 1'b1;
                bus_addr = cpu_addr;
            end
            BYPASS_WRITE, WRITE_THROUGH: begin
                bus_req  = 1'b1;
                bus_we   = 1'b1;
                bus_addr = cpu_addr;
            end
            REFILL_W0: begin
                bus_req  = 1'b1;
                bus_addr = base_line_addr + 32'd0;
            end
            REFILL_W1: begin
                bus_req  = 1'b1;
                bus_addr = base_line_addr + 32'd4;
            end
            REFILL_W2: begin
                bus_req  = 1'b1;
                bus_addr = base_line_addr + 32'd8;
            end
            REFILL_W3: begin
                bus_req  = 1'b1;
                bus_addr = base_line_addr + 32'd12;
            end
            default: ; // IDLE
        endcase
    end

endmodule
