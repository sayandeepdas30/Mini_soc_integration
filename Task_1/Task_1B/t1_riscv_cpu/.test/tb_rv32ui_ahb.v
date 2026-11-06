`timescale 1ns/1ps
module tb_rv32ui_ahb;
  parameter WAIT_CYCLES = 0;
  reg clk = 0, reset = 1;
  wire [31:0] PC, Result;

  soc_top #(WAIT_CYCLES) uut (clk, reset, PC, Result);

  always #5 clk = ~clk;

  reg [8*256-1:0] hexfile;
  reg [31:0] last_pc;
  reg err_seen = 0;
  always @(posedge clk) if (uut.HRESP) err_seen <= 1;
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
    while (same < 20 && cycles < 400000) begin
      @(posedge clk);
      cycles = cycles + 1;
      if (PC === last_pc) same = same + 1;
      else begin same = 0; last_pc = PC; end
    end

    if (uut.rvcpu.dp.rf.reg_file_arr[3] == 1)
      $display("PASS  %0s  (HRESP seen: %0d)", hexfile, err_seen);
    else
      $display("FAIL  %0s  x3=%0d  (sub-test %0d)  (HRESP seen: %0d)", hexfile,
               uut.rvcpu.dp.rf.reg_file_arr[3],
               uut.rvcpu.dp.rf.reg_file_arr[3] >> 1, err_seen);
    $finish;
  end
endmodule