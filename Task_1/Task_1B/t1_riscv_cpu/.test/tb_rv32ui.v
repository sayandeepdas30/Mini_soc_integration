`timescale 1ns/1ps
module tb_rv32ui;
  reg clk = 0, reset = 1;
  reg Ext_MemWrite = 0;
  reg [31:0] Ext_WriteData = 0, Ext_DataAdr = 0;
  wire MemWrite;
  wire [31:0] WriteData, DataAdr, ReadData, PC, Result;

  t1_riscv_cpu uut (clk, reset, Ext_MemWrite, Ext_WriteData, Ext_DataAdr,
                    MemWrite, WriteData, DataAdr, ReadData, PC, Result);

  always #5 clk = ~clk;

  reg [8*256-1:0] hexfile;
  reg [31:0] last_pc;
  integer same, cycles;

  initial begin
    if (!$value$plusargs("hex=%s", hexfile)) begin
      $display("ERROR: no +hex given"); $finish;
    end
    $readmemh(hexfile, uut.instrmem.instr_ram);
    $readmemh(hexfile, uut.datamem.data_ram);
    repeat (4) @(posedge clk);
    reset = 0;

    same = 0; cycles = 0; last_pc = 32'hFFFFFFFF;
    while (same < 20 && cycles < 200000) begin
      @(posedge clk);
      cycles = cycles + 1;
      if (PC === last_pc) same = same + 1;
      else begin same = 0; last_pc = PC; end
    end

    if (uut.rvcpu.dp.rf.reg_file_arr[3] == 1)
      $display("PASS  %0s", hexfile);
    else
      $display("FAIL  %0s  x3=%0d  (sub-test %0d)", hexfile,
               uut.rvcpu.dp.rf.reg_file_arr[3],
               uut.rvcpu.dp.rf.reg_file_arr[3] >> 1);
    $finish;
  end
endmodule