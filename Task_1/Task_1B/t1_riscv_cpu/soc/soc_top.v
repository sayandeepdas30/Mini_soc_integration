// soc_top.v - core + AHB-Lite master + AHB slave memory
module soc_top #(parameter WAIT_CYCLES = 0) (
    input         clk, reset,
    output [31:0] PC, Result
);
wire [31:0] Instr, DataAdr, WriteData, ReadData;
wire        MemWrite, MemRead, ready;
wire [3:0]  ByteEn;

wire [31:0] HADDR, HWDATA, HRDATA;
wire        HWRITE, HREADY, HRESP;
wire [2:0]  HSIZE;
wire [1:0]  HTRANS;

riscv_cpu rvcpu (.clk(clk), .reset(reset), .PC(PC), .Instr(Instr),
    .MemWrite(MemWrite), .MemRead(MemRead), .Mem_ByteEn(ByteEn),
    .Mem_WrAddr(DataAdr), .Mem_WrData(WriteData),
    .ReadData(ReadData), .Mem_Ready(ready), .Result(Result));

instr_mem instrmem (PC, Instr);

ahb_master bridge (.HCLK(clk), .HRESETn(~reset),
    .req_rd(MemRead), .req_wr(MemWrite), .addr(DataAdr), .wdata(WriteData),
    .byte_en(ByteEn), .rdata(ReadData), .ready(ready),
    .HADDR(HADDR), .HWDATA(HWDATA), .HWRITE(HWRITE), .HSIZE(HSIZE),
    .HTRANS(HTRANS), .HRDATA(HRDATA), .HREADY(HREADY), .HRESP(HRESP));

ahb_slave_mem #(WAIT_CYCLES, 4096) datamem (.HCLK(clk), .HRESETn(~reset),
    .HSEL(1'b1), .HADDR(HADDR), .HTRANS(HTRANS), .HWRITE(HWRITE), .HSIZE(HSIZE),
    .HWDATA(HWDATA), .HREADY(HREADY), .HREADYOUT(HREADY),
    .HRDATA(HRDATA), .HRESP(HRESP));
endmodule