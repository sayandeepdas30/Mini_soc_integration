// riscv_cpu.v - single-cycle RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire        ALUSrc, RegWrite, Jump, Jalr, Zero, SLT, SLTU, PCSrc;
wire [1:0]  ResultSrc;
wire [2:0]  ImmSrc;
wire [3:0]  ALUControl;
wire [2:0]  Funct3;

controller  c   (Instr[6:0], Instr[14:12], Instr[30], Zero, SLT, SLTU,
                ResultSrc, MemWrite, PCSrc, ALUSrc, RegWrite, Jump, Jalr,
                ImmSrc, ALUControl, Funct3);

datapath    dp  (clk, reset, ResultSrc, PCSrc,
                ALUSrc, RegWrite, ImmSrc, ALUControl, Jalr, Funct3,
                Zero, SLT, SLTU, PC, Instr, Mem_WrAddr, Mem_WrData, ReadData, Result);

endmodule
