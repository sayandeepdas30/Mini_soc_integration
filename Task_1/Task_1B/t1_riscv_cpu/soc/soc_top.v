// soc_top.v - core + AHB-Lite master + interconnect + 2 RAMs + default slave
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

wire        HSEL0, HSEL1, HSELD;
wire [31:0] HRDATA0, HRDATA1, HRDATAD;
wire        HREADYOUT0, HREADYOUT1, HREADYOUTD;
wire        HRESP0, HRESP1, HRESPD;

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

ahb_interconnect xbar (.HCLK(clk), .HRESETn(~reset),
    .HADDR(HADDR), .HTRANS(HTRANS),
    .HRDATA(HRDATA), .HREADY(HREADY), .HRESP(HRESP),
    .HSEL0(HSEL0), .HSEL1(HSEL1), .HSELD(HSELD),
    .HRDATA0(HRDATA0), .HRDATA1(HRDATA1), .HRDATAD(HRDATAD),
    .HREADYOUT0(HREADYOUT0), .HREADYOUT1(HREADYOUT1), .HREADYOUTD(HREADYOUTD),
    .HRESP0(HRESP0), .HRESP1(HRESP1), .HRESPD(HRESPD));

ahb_slave_mem #(WAIT_CYCLES, 4096) datamem (.HCLK(clk), .HRESETn(~reset),
    .HSEL(HSEL0), .HADDR(HADDR), .HTRANS(HTRANS), .HWRITE(HWRITE), .HSIZE(HSIZE),
    .HWDATA(HWDATA), .HREADY(HREADY), .HREADYOUT(HREADYOUT0),
    .HRDATA(HRDATA0), .HRESP(HRESP0));

ahb_slave_mem #(WAIT_CYCLES, 4096) ram1 (.HCLK(clk), .HRESETn(~reset),
    .HSEL(HSEL1), .HADDR(HADDR), .HTRANS(HTRANS), .HWRITE(HWRITE), .HSIZE(HSIZE),
    .HWDATA(HWDATA), .HREADY(HREADY), .HREADYOUT(HREADYOUT1),
    .HRDATA(HRDATA1), .HRESP(HRESP1));

ahb_default_slave dflt (.HCLK(clk), .HRESETn(~reset), .HSEL(HSELD),
    .HTRANS(HTRANS), .HREADY(HREADY), .HREADYOUT(HREADYOUTD),
    .HRESP(HRESPD), .HRDATA(HRDATAD));
endmodule