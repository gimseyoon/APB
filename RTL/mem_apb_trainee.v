`define AMBA3

`ifdef AMBA_APB4
`ifndef AMBA_APB3
ERROR AMBA_APB3 shouldb edefined when AMBA_APB4 is defined
`endif
`endif






module mem_apb
#(parameter SIZE_IN_BYTES=1024 // memory depth
, DELAY=2 ) // access delay if any for AMBA3/4
(
input wire PRESETn
, input wire PCLK
, input wire PSEL
, input wire [31:0] PADDR
, input wire PENABLE
, input wire PWRITE
, input wire [31:0] PWDATA
, output reg [31:0] PRDATA
`ifdef AMBA3
, output reg PREADY
, output reg PSLVERR
`endif
`ifdef AMBA4
, input wire [ 2:0] PPROT
, input wire [ 3:0] PSTRB
`endif
);





    //----------------------------------------------------
`ifndef AMBA3
reg PREADY = 1'b1;
reg PSLVERR = 1'b0;
`endif
`ifndef AMBA4
wire [ 2:0] PPROT = 3'h0;
wire [ 3:0] PSTRB = 4'hF;
`endif
//----------------------------------------------------


reg [7:0] mem0[0:SIZE_IN_BYTES/4];
reg [7:0] mem1[0:SIZE_IN_BYTES/4];
reg [7:0] mem2[0:SIZE_IN_BYTES/4];
reg [7:0] mem3[0:SIZE_IN_BYTES/4];


//----------------------------------------------------


localparam A_WIDTH = $clog2(SIZE_IN_BYTES);
wire [A_WIDTH-1:2] addr = PADDR[A_WIDTH-1:2];


//----------------------------------------------------


reg [31:0] dcnt = 'h1; // delay counter

localparam     ST_IDLE = 'h0,
                ST_DELAY = 'h1,
                ST_DONE = 'h2;
reg [1:0] state = ST_IDLE;




always @ (posedge PCLK or negedge PRESETn) begin
    if (PRESETn==1'b0) begin
         PRDATA <= ~32'h0;
         PREADY <= 1'b1;
         PSLVERR <= 1'b0;
         dcnt <= 'h1;
         state <= ST_IDLE;
    end 
    else begin
         case (state)
            ST_IDLE: begin
                 PREADY <= 1'b0;
                 if (PSEL==1'b1) begin
                      if (DELAY==0) begin
                           PREADY <= 1'b1;
                           state <= ST_DONE;
                           if (PWRITE==1'b1) begin
                                if (PSTRB[0]==1'b1) mem0[addr] <= PWDATA[ 7: 0];
                                if (PSTRB[1]==1'b1) mem1[addr] <= PWDATA[15: 8];
                                if (PSTRB[2]==1'b1) mem2[addr] <= PWDATA[23:16];
                                if (PSTRB[3]==1'b1) mem3[addr] <= PWDATA[31:24];
                           end else begin
                                PRDATA[ 7: 0] <= mem0[addr];
                                PRDATA[15: 8] <= mem1[addr];
                                PRDATA[23:16] <= mem2[addr];
                                PRDATA[31:24] <= mem3[addr];
                           end
                      end //if(DELAY)
                      else begin
  
                           dcnt <= 'h1;
                           state <= ST_DELAY;
                      end
                 end
            end // ST_IDLE
            ST_DELAY: begin
                 dcnt <= dcnt + 1;
                 if (dcnt>=DELAY) begin
                      PREADY <= 1'b1;
                      state <= ST_DONE;
                      if (PWRITE==1'b1) begin
                           if (PSTRB[0]==1'b1) mem0[addr] <= PWDATA[ 7: 0];
                           if (PSTRB[1]==1'b1) mem1[addr] <= PWDATA[15: 8];
                           if (PSTRB[2]==1'b1) mem2[addr] <= PWDATA[23:16];
                           if (PSTRB[3]==1'b1) mem3[addr] <= PWDATA[31:24];
                      end else begin
                           PRDATA[ 7: 0] <= mem0[addr];
                           PRDATA[15: 8] <= mem1[addr];
                           PRDATA[23:16] <= mem2[addr];
                           PRDATA[31:24] <= mem3[addr];
                      end
                 end
            end // ST_DELAY
            ST_DONE: begin
                 PREADY <= 1'b1;
                 state <= ST_IDLE;
            end // ST_DONE
         endcase
    end // if, else
end // always


//----------------------------------------------------


function integer clogb2;
input [31:0] value; reg [31:0] tmp, rt;
begin
     tmp = value - 1;
     for (rt=0; tmp>0; rt=rt+1) tmp=tmp>>1;
     clogb2 = rt;
end
endfunction


//----------------------------------------------------
endmodule

