onerror {quit -f}
vlib work
vlog {*}[glob code/*.v] {*}[glob code/components/*.v] {*}[glob soc/*.v] .test/tb_rv32ui_ahb.v
vsim -c -onfinish stop -GWAIT_CYCLES=3 work.tb_rv32ui_ahb +hex=C:/Users/User/rv32ui_tests/soc_test1.hex
run -all
quit -f