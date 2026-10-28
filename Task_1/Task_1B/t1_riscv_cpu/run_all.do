vlib work
vlog {*}[glob code/*.v] {*}[glob code/components/*.v] .test/tb_rv32ui.v
foreach h [lsort [glob C:/Users/User/rv32ui_tests/out/*.hex]] {
    vsim -c -onfinish stop -GWAIT_CYCLES=0 work.tb_rv32ui +hex=$h
  run -all
  quit -sim
}
quit -f
