`timescale 1ns / 1ps

`ifndef BFM_APB_TASKS_V
`define BFM_APB_TASKS_V


task apb_write;
    input [31:0] addr;
    input [31:0] data;
    input [2:0]  size;
begin
    @(posedge PCLK);
    PADDR  <= #1 addr;
    PWRITE <= #1 1'b1;
    PSEL   <= #1 decoder(addr);
    PWDATA <= #1 data;
    PSTRB  <= #1 get_pstrob(addr, size);
    @(posedge PCLK);
    PENABLE <= #1 1'b1;
    @(posedge PCLK);
    while (get_pready(addr) == 1'b0) @(posedge PCLK);
`ifndef LOW_POWER
    PADDR  <= #1 32'h0;
    PWRITE <= #1 1'b0;
    PWDATA <= #1 ~32'h0;
`endif
    PSEL    <= #1 {P_NUM{1'b0}};
    PENABLE <= #1 1'b0;
    if (get_pslverr(addr) == 1'b1)
        $display($time,,"%m PSLVERR");
end
endtask

//--------------------------------------------------------
task apb_read;
    input  [31:0] addr;
    output [31:0] data;
    input  [2:0]  size;
begin
    @(posedge PCLK);
    PADDR  <= #1 addr;
    PWRITE <= #1 1'b0;
    PSEL   <= #1 decoder(addr);
    PSTRB  <= #1 {P_STRB{1'b1}};
    @(posedge PCLK);
    PENABLE <= #1 1'b1;
    @(posedge PCLK);
    while (get_pready(addr) == 1'b0) @(posedge PCLK);
`ifndef LOW_POWER
    PADDR  <= #1 32'h0;
`endif
    PSEL    <= #1 {P_NUM{1'b0}};
    PENABLE <= #1 1'b0;
    if (get_pslverr(addr) == 1'b1)
        $display($time, "%m PSLVERR");
    data = get_prdata(addr); // it should be blocking
end
endtask

//--------------------------------------------------------
// decoder
function [P_NUM-1:0] decoder;
    input [31:0] addr;
begin
    decoder = 'b0;
    if (P_NUM >= 1) begin
        if ((addr >= P_ADDR_START0) && (addr <= P_ADDR_START0 + P_SIZE0 - 1)) decoder = 1 << 0;
    end
    if (P_NUM >= 2) begin
        if ((addr >= P_ADDR_START1) && (addr <= P_ADDR_START1 + P_SIZE1 - 1)) decoder = 1 << 1;
    end
    if (P_NUM >= 3) begin
        if ((addr >= P_ADDR_START2) && (addr <= P_ADDR_START2 + P_SIZE2 - 1)) decoder = 1 << 2;
    end
    if (P_NUM >= 4) begin
        if ((addr >= P_ADDR_START3) && (addr <= P_ADDR_START3 + P_SIZE3 - 1)) decoder = 1 << 3;
    end
    if (decoder == 0)
        $display($time,,"%m ERROR: address 0x%08x out of range", addr);
end
endfunction

//--------------------------------------------------------
// get_pstrob
//function [P_STRB-1:0] get_pstrob;
//    input [31:0] addr;
//    input [2:0]  size;
//    integer i;
//begin
//    get_pstrob = 0;
//    for (i = 0; i < size; i = i + 1)
//        get_pstrob[addr[1:0] + i] = 1'b1;
//end
//endfunction
//
function [P_STRB-1:0] get_pstrob;
    input [31:0] addr;
    input [2:0]  size;
begin
    case (addr[1:0])
        2'b00: case (size)
            3'd1: get_pstrob = 4'b0001;
            3'd2: get_pstrob = 4'b0011;
            3'd4: get_pstrob = 4'b1111;
            default: $display($time,,"%m mis-aligned access");
        endcase

        2'b01: case (size)
            3'd1: get_pstrob = 4'b0010;
            default: $display($time,,"%m mis-aligned access");
        endcase

        2'b10: case (size)
            3'd1: get_pstrob = 4'b0100;
            3'd2: get_pstrob = 4'b1100;
            default: $display($time,,"%m mis-aligned access");
        endcase

        2'b11: case (size)
            3'd1: get_pstrob = 4'b1000;
            default: $display($time,,"%m mis-aligned access");
        endcase
    endcase
end
endfunction


//--------------------------------------------------------
// get_pready
function get_pready;
    input [31:0] addr;
begin
    get_pready = 1'b1;
    if (P_NUM >= 1 && (addr >= P_ADDR_START0) && (addr <= P_ADDR_START0 + P_SIZE0 - 1)) get_pready = PREADY[0];
    else if (P_NUM >= 2 && (addr >= P_ADDR_START1) && (addr <= P_ADDR_START1 + P_SIZE1 - 1)) get_pready = PREADY[1];
    else if (P_NUM >= 3 && (addr >= P_ADDR_START2) && (addr <= P_ADDR_START2 + P_SIZE2 - 1)) get_pready = PREADY[2];
    else if (P_NUM >= 4 && (addr >= P_ADDR_START3) && (addr <= P_ADDR_START3 + P_SIZE3 - 1)) get_pready = PREADY[3];
end
endfunction

//--------------------------------------------------------
// get_pslverr
function get_pslverr;
    input [31:0] addr;
begin
    get_pslverr = 1'b0;
    if (P_NUM >= 1 && (addr >= P_ADDR_START0) && (addr <= P_ADDR_START0 + P_SIZE0 - 1)) get_pslverr = PSLVERR[0];
    else if (P_NUM >= 2 && (addr >= P_ADDR_START1) && (addr <= P_ADDR_START1 + P_SIZE1 - 1)) get_pslverr = PSLVERR[1];
    else if (P_NUM >= 3 && (addr >= P_ADDR_START2) && (addr <= P_ADDR_START2 + P_SIZE2 - 1)) get_pslverr = PSLVERR[2];
    else if (P_NUM >= 4 && (addr >= P_ADDR_START3) && (addr <= P_ADDR_START3 + P_SIZE3 - 1)) get_pslverr = PSLVERR[3];
end
endfunction

//--------------------------------------------------------
// get_prdata
function [31:0] get_prdata;
    input [31:0] addr;
begin
    get_prdata = 32'hDEAD_BEEF;
    if (P_NUM >= 1 && (addr >= P_ADDR_START0) && (addr <= P_ADDR_START0 + P_SIZE0 - 1)) get_prdata = PRDATA0;
    else if (P_NUM >= 2 && (addr >= P_ADDR_START1) && (addr <= P_ADDR_START1 + P_SIZE1 - 1)) get_prdata = PRDATA1;
    else if (P_NUM >= 3 && (addr >= P_ADDR_START2) && (addr <= P_ADDR_START2 + P_SIZE2 - 1)) get_prdata = PRDATA2;
    else if (P_NUM >= 4 && (addr >= P_ADDR_START3) && (addr <= P_ADDR_START3 + P_SIZE3 - 1)) get_prdata = PRDATA3;
end
endfunction

`endif

