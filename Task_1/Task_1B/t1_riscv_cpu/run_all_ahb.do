vlib work
vlog {*}[glob code/*.v] {*}[glob code/components/*.v] {*}[glob soc/*.v] .test/tb_rv32ui_ahb.v
foreach h [lsort [glob C:/Users/User/rv32ui_tests/out/*.hex]] {
  vsim -c -onfinish stop -GWAIT_CYCLES=3 work.tb_rv32ui_ahb +hex=$h
  run -all
  quit -sim
}
quit -f