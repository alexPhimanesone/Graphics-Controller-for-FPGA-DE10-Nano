new_project -name wb_bram -folder precision_wb_bram -createimpl_name impl
add_input_file {../../../wshb_if/wshb_if.sv}
add_input_file {../../wb_bram/wb_bram.sv}
setup_design -manufacturer "Intel FPGA" -family "MAX 10" -part 10M08DAF256C7G -speed 7 ; setup_design -frequency 1000 -input_delay 0 -output_delay 0 -max_fanout=1000
setup_design -addio=false
compile
synthesize
