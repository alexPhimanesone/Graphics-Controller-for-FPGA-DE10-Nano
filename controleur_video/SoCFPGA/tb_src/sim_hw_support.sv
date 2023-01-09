// Version testbench du module de support
// matériel. Cette version minimaliste
// contient:
// - la génération du reset système a partir de KEY[0]
// - la génération du flux vidéo sur wshb_ifm
// - un modèle d'accès dram sur wshb_ifs
// L'interface HPS est complètement ignorée

module sim_hw_support
(
    wshb_if.slave      wshb_ifs,
    wshb_if.master     wshb_ifm,

    hws_if.master      hws_ifm,

    output logic       sys_rst,
    input  wire        SW_0,
	input  wire  [1:0] KEY
);

// gestion du reset
logic tmp_rst;
always @(posedge wshb_ifs.clk or negedge KEY[0]) 
    if(!KEY[0])
        {tmp_rst,sys_rst}  <= 2'b11 ;
    else
        {tmp_rst,sys_rst}  <= {1'b0,tmp_rst} ;

// Génération du flux vidéo
tpg_video tpg_video_inst(.wshb_ifm(wshb_ifm)) ;

// Modèle du controleur de RAM
wb_ram_ctl #( .DEPTH(1024*1024), .WIDTH(32), .LATENCY(12), .INIT_FILE(`IMAGE_FILE)) wb_ram_ctl_inst ( .wshb_ifs(wshb_ifs));


endmodule


