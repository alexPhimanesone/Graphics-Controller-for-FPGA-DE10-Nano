//
// fpga_bridge.sv
// @brief : 
// This module contains :
// 2 wishbone slave interfaces
// 1 wishbone interconnect
// 1 wishbone to avalon module
// 1 avalon stream to wishbon module
// 
`default_nettype none
module fpga_bridge
(
    input wire sys_clk,
    input wire sys_rst,

    avl_if.master       avl_ifm,   // avalon memory-mapped
    avlst_if.slave      avlst_ifs,   // avalon stream 

    wshb_if.slave       wshb_ifs,
    wshb_if.master      wshb_ifm,

    input wire [31:0]   img_addr
);

wshb_if
#(
    .DATA_BYTES(4)
)
wshb_if_sdram
(
    sys_clk,
    sys_rst
);

// avalon stream to wishbone bridge instantiation
avlst2wshb 
avlst2wshb_inst 
(
    .avl_ifs(avlst_ifs),
    .wshb_ifm(wshb_ifm)
);

wshb2avl 
#(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .AVL_BURST_LENGTH(32)
)
wshb2avl_i 
(
    .wshb_ifs(wshb_ifs),
    .avl_ifm(avl_ifm),
    .img_addr(img_addr)
);

endmodule

`default_nettype wire
