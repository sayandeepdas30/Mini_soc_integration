// t1_riscv_cpu.v - Top Module to test riscv_cpu

module t1_riscv_cpu #(parameter WAIT_CYCLES = 0) (
    input         clk, reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;
wire [31:0] DataAdr_rv32, WriteData_rv32;
wire        MemWrite_rv32, MemRead_rv32;
wire [3:0]  ByteEn_rv32;
wire        Mem_Ready;

// wait-state generator: a memory request takes WAIT_CYCLES extra cycles
reg [3:0] wait_cnt;
wire      req = MemRead_rv32 | MemWrite_rv32;
always @(posedge clk) begin
    if (reset)                    wait_cnt <= 0;
    else if (req && !Mem_Ready)   wait_cnt <= wait_cnt + 1;
    else                          wait_cnt <= 0;
end
assign Mem_Ready = (wait_cnt >= WAIT_CYCLES);

// processor and memories
riscv_cpu rvcpu (
    .clk(clk), .reset(reset), .PC(PC), .Instr(Instr),
    .MemWrite(MemWrite_rv32), .MemRead(MemRead_rv32), .Mem_ByteEn(ByteEn_rv32),
    .Mem_WrAddr(DataAdr_rv32), .Mem_WrData(WriteData_rv32),
    .ReadData(ReadData), .Mem_Ready(Mem_Ready), .Result(Result));

instr_mem instrmem (PC, Instr);

wire ext_wr = Ext_MemWrite && reset;

assign MemWrite  = ext_wr ? 1'b1 : (MemWrite_rv32 & Mem_Ready);
assign WriteData = ext_wr ? Ext_WriteData : WriteData_rv32;
assign DataAdr   = reset  ? Ext_DataAdr   : DataAdr_rv32;
wire [3:0] be    = ext_wr ? 4'b1111 : ByteEn_rv32;

data_mem #(32, 32, 4096) datamem (clk, MemWrite, DataAdr, WriteData, ReadData, be);

endmodule