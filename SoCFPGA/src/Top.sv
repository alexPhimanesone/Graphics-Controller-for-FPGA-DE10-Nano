`default_nettype none
module Top (
    // Les signaux externes de la partie FPGA
	input  wire         FPGA_CLK1_50,
	input  wire  [1:0]	KEY,
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,
    // Les signaux du support matériel son regroupés dans une interface
    hws_if.master       hws_ifm
);

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        sys_rst;   // Le signal de reset
  wire        pixel_clk; // L'horloge de la video 32 Mhz

//=======================================================
//  La PLL pour la génération des horloges
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // sortie a 32 Mhz
		   .outclk_1(sys_clk)       // sortie a 100 Mhz
);

//=============================
//  Les bus Wishbone internes
//=============================
wshb_if #( .DATA_BYTES(4)) wshb_if_sdram  (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_stream (sys_clk, sys_rst);

//=============================
//  Le support matériel
//=============================
hw_support hw_support_inst (
    .wshb_ifs (wshb_if_sdram),
    .wshb_ifm (wshb_if_stream),
    .hws_ifm  (hws_ifm),
	.sys_rst  (sys_rst), // output
    .SW_0     ( SW[0] ),
    .KEY      ( KEY )
 );

//=============================
// On neutralise l'interface
// du flux video pour l'instant
//=============================
assign wshb_if_stream.ack = 1'b1;
assign wshb_if_stream.dat_sm = '0 ;
assign wshb_if_stream.err =  1'b0 ;
assign wshb_if_stream.rty =  1'b0 ;

//=============================
// On neutralise l'interface SDRAM
// pour l'instant
//=============================
assign wshb_if_sdram.stb  = 1'b0;
assign wshb_if_sdram.cyc  = 1'b0;
assign wshb_if_sdram.we   = 1'b0;
assign wshb_if_sdram.adr  = '0  ;
assign wshb_if_sdram.dat_ms = '0 ;
assign wshb_if_sdram.sel = '0 ;
assign wshb_if_sdram.cti = '0 ;
assign wshb_if_sdram.bte = '0 ;


//--------------------------
//------- Code Eleves ------
//--------------------------
// 100 Mhz / 1 Hz * 50 % duty cycle
`ifdef SIMULATION
    localparam CNT_1HZ   = 50;
`else
    localparam CNT_1HZ   = 50_000_000;
`endif

logic [$clog2(CNT_1HZ)-1:0] count_2;
logic state_2;

// LEDR1 blink
// Clock 100 Mhz
always @(posedge sys_clk or posedge sys_rst)
   if(sys_rst)
   begin
       count_2 <= '0;
       state_2 <= 1'b0;
   end
   else if (count_2 == CNT_1HZ-1)
   begin
       state_2 <= ~state_2;
       count_2 <= '0;
   end
   else
       count_2 <= count_2 + 1'b1;

assign LED[1] = state_2;
assign LED[0] = sys_rst;

//------ End User Code


endmodule
