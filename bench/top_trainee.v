`timescale 1ns/1ps

`define AMBA3
`define VCD  // 파형 확인용

`ifndef CLK_FREQ
`define CLK_FREQ       50000000
`endif
`ifndef MEM_DELAY
`define MEM_DELAY 0
`endif

module top ;
   //------------------------------------------------
   localparam P_NUM        = 4,   // num of APB slaves
              SIZE_IN_BYTES=1024, // memory size
              DELAY        =`MEM_DELAY; // access delay if any for AMBA3/4
   //------------------------------------------------
   reg               PRESETn =1'b0;
   reg               PCLK    =1'b0;
   wire  [P_NUM-1:0] PSEL    ;
   wire  [31:0]      PADDR   ;
   wire              PENABLE ;
   wire              PWRITE  ;
   wire  [31:0]      PWDATA  ;
   wire  [31:0]      PRDATA[0:P_NUM-1];
   `ifdef AMBA3
   wire  [P_NUM-1:0] PREADY  ;
   wire  [P_NUM-1:0] PSLVERR ;
   `endif
   `ifdef AMBA4
   wire  [ 2:0]      PPROT   ;
   wire  [ 3:0]      PSTRB   ; // mind PWDATA[31:0]
   `endif
   //------------------------------------------------
    bfm_apb_s4 #(
        .P_NUM           (P_NUM),
        .P_DELAY         (DELAY),
        .P_DWIDTH        (32),
        .P_STRB          (4),
        .P_SIZE_IN_BYTES (SIZE_IN_BYTES),
        .P_ADDR_START0   (32'h0000_0000), .P_SIZE0(SIZE_IN_BYTES),
        .P_ADDR_START1   (32'h0001_0000), .P_SIZE1(SIZE_IN_BYTES),
        .P_ADDR_START2   (32'h0002_0000), .P_SIZE2(SIZE_IN_BYTES),
        .P_ADDR_START3   (32'h0003_0000), .P_SIZE3(SIZE_IN_BYTES)
    ) u_bfm_apb (
        .PRESETn (PRESETn),
        .PCLK    (PCLK),
        .PSEL    (PSEL),
        .PADDR   (PADDR),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA0 (PRDATA[0]),
        .PRDATA1 (PRDATA[1]),
        .PRDATA2 (PRDATA[2]),
        .PRDATA3 (PRDATA[3])
    `ifdef AMBA3
        , .PREADY  (PREADY)
        , .PSLVERR (PSLVERR)
    `endif
    `ifdef AMBA4
        , .PPROT   (PPROT)
        , .PSTRB   (PSTRB)
    `endif
    );

   //-----------------------------------------------------
   generate
   genvar pn;
   for (pn=0; pn<P_NUM; pn=pn+1) begin : P_BLOCK

        mem_apb #(
            .SIZE_IN_BYTES (SIZE_IN_BYTES),
            .DELAY         (DELAY)
        ) u_mem_apb (
            .PRESETn (PRESETn),
            .PCLK    (PCLK),
            .PSEL    (PSEL[pn]),
            .PADDR   (PADDR),
            .PENABLE (PENABLE),
            .PWRITE  (PWRITE),
            .PWDATA  (PWDATA),
            .PRDATA  (PRDATA[pn])
        `ifdef AMBA3
            , .PREADY   (PREADY[pn])
            , .PSLVERR (PSLVERR[pn])
        `endif
        `ifdef AMBA4
            , .PPROT    (PPROT)
            , .PSTRB    (PSTRB)
        `endif
        );
    end
    endgenerate

   //-----------------------------------------------------
   localparam CLK_FREQ=`CLK_FREQ;
   localparam CLK_PERIOD_HALF=1000000000/(CLK_FREQ*2);
   //-----------------------------------------------------
   always #CLK_PERIOD_HALF PCLK <= ~PCLK;
   //-----------------------------------------------------
   real stamp_x, stamp_y, delta;
   initial begin
       PRESETn <= 1'b0;
       repeat (5) @ (posedge PCLK);
       `ifdef RIGOR
        @ (posedge PCLK);
        @ (posedge PCLK); stamp_x = $time;
        @ (posedge PCLK); stamp_y = $time; delta = stamp_y - stamp_x;
        @ (negedge PCLK); $display("%m PCLK %f nsec %f Mhz", delta, 1000.0/delta);
       `endif
       repeat (5) @ (posedge PCLK);
       PRESETn <= 1'b1;
   end
   //------------------------------------------------
   `ifdef VCD
   initial begin
       $dumpfile("wave.vcd");
       $dumpvars(0);
   end
   `endif
endmodule


