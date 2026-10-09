`timescale 1ns  1ps

module soc_top (
    input  wire clk,          Onboard 100MHz or 50MHz clock
    input  wire resetn,       Active-low reset button

     External UART pins
    input  wire uart_rx,
    output wire uart_tx
);

     -------------------------------------------------------------
     1. CPU Bus Signals
     -------------------------------------------------------------
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [310] mem_addr;
    wire [310] mem_wdata;
    wire [ 30] mem_wstrb;
    wire [310] mem_rdata;

     -------------------------------------------------------------
     2. Instantiate PicoRV32 CPU
     -------------------------------------------------------------
    picorv32 #(
        .PROGADDR_RESET(32'h 0000_0000),  Boots at address 0
        .STACKADDR     (32'h 0000_2000),  8KB Stack top
        .ENABLE_COUNTERS(1),
        .TWO_CYCLE_ALU (0)
    ) cpu (
        .clk      (clk),
        .resetn   (resetn),
        .trap     (),

        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr (mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),

        .pcpi_valid(), .pcpi_insn(), .pcpi_rs1(), .pcpi_rs2(),
        .pcpi_wr(1'b0), .pcpi_rd(32'b0), .pcpi_wait(1'b0), .pcpi_ready(1'b0),
        .irq(32'b0), .eoi()
    );

     -------------------------------------------------------------
     3. Address Decoder (MMIO Mapping)
     -------------------------------------------------------------
     Address 0x00xxxxxx Internal RAM (Code & Variables)
    wire sel_ram   = mem_valid && (mem_addr[3124] == 8'h00);

     Address 0x02xxxxxx UART Peripheral
    wire sel_uart  = mem_valid && (mem_addr[3124] == 8'h02);

     Address 0x20xxxxxx YOUR ACCELERATOR BLOCK
    wire sel_accel = mem_valid && (mem_addr[3124] == 8'h20);

     Response wires
    wire        ram_ready;
    wire [310] ram_rdata;

    wire        uart_ready;
    wire [310] uart_rdata;

    wire        accel_ready;
    wire [310] accel_rdata;

     Bus Multiplexer (Returns ready and read data back to CPU)
    assign mem_ready = sel_ram    ram_ready   
                       sel_uart   uart_ready  
                       sel_accel  accel_ready  1'b0;

    assign mem_rdata = sel_ram    ram_rdata   
                       sel_uart   uart_rdata  
                       sel_accel  accel_rdata  32'h0;

     -------------------------------------------------------------
     4. 8KB BRAM Memory (Stores compiled C Firmware)
     -------------------------------------------------------------
    reg [310] bram [02047];  2048 words  4 bytes = 8KB
    reg        ram_ack;

     Initial load of compiled firmware
    initial begin
         The embedded teammate puts their compiled firmware hex here
        $readmemh(firmware.hex, bram);
    end

    always @(posedge clk) begin
        ram_ack = sel_ram && !ram_ack;
        if (sel_ram && mem_wstrb) begin
            if (mem_wstrb[0]) bram[mem_addr[122]][ 7 0] = mem_wdata[ 7 0];
            if (mem_wstrb[1]) bram[mem_addr[122]][15 8] = mem_wdata[15 8];
            if (mem_wstrb[2]) bram[mem_addr[122]][2316] = mem_wdata[2316];
            if (mem_wstrb[3]) bram[mem_addr[122]][3124] = mem_wdata[3124];
        end
    end
    assign ram_ready = ram_ack;
    assign ram_rdata = bram[mem_addr[122]];

     -------------------------------------------------------------
     5. Official SimpleUART (From PicoRV32 Repo)
     -------------------------------------------------------------
    simpleuart uart (
        .clk         (clk),
        .resetn      (resetn),
        .ser_tx      (uart_tx),
        .ser_rx      (uart_rx),
        .reg_div_we  (sel_uart && mem_addr[30] == 4'h4 && mem_wstrb),
        .reg_div_di  (mem_wdata),
        .reg_div_do  (),
        .reg_dat_we  (sel_uart && mem_addr[30] == 4'h0 && mem_wstrb),
        .reg_dat_re  (sel_uart && mem_addr[30] == 4'h0 && !mem_wstrb),
        .reg_dat_di  (mem_wdata),
        .reg_dat_do  (uart_rdata),
        .reg_dat_wait()
    );
    assign uart_ready = sel_uart;

     -------------------------------------------------------------
     6. YOUR EDGE DETECTION ACCELERATOR (Integrated via MMIO!)
     -------------------------------------------------------------
    image_edge_accelerator_top #(
        .BASE_ADDR(32'h2000_0000),
        .IMG_WIDTH(64)
    ) my_accel (
        .clk       (clk),
        .rst_n     (resetn),

         Connect directly to CPU MMIO wires
        .mem_valid (sel_accel),
        .mem_ready (accel_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (accel_rdata)
    );

endmodule