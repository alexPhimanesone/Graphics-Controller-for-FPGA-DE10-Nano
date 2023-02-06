`default_nettype none

module Top #(
    parameter           HDISP = 800,
    parameter           VDISP = 480) (
    // Les signaux externes de la partie FPGA
	input  wire         FPGA_CLK1_50,
	input  wire  [1:0]	KEY,
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,
    video_if.master     video_ifm,
    // Les signaux du support matériel sont regroupés dans une interface
    hws_if.master       hws_ifm
);

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_rst;   // Le signal de reset du système
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        pixel_clk; // L'horloge de la video 32 Mhz

//=======================================================
//  La PLL pour la génération des horloges
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // horloge pixels a 32 Mhz
		   .outclk_1(sys_clk)       // horloge systeme a 100MHz
);

//=============================
//  Les bus Wishbone internes
//=============================
wshb_if #( .DATA_BYTES(4)) wshb_if_sdram  (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_stream (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_mire   (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_vga    (sys_clk, sys_rst);


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
// A SUPPRIMER PLUS TARD
//=============================
assign wshb_if_stream.ack = 1'b1;
assign wshb_if_stream.dat_sm = '0 ;
assign wshb_if_stream.err =  1'b0 ;
assign wshb_if_stream.rty =  1'b0 ;


//=============================
// Neutralisation de l'interface SDRAM
//=============================
//assign wshb_if_sdram.stb  = 1'b0;
//assign wshb_if_sdram.cyc  = 1'b0;
//assign wshb_if_sdram.we   = 1'b0;
//assign wshb_if_sdram.adr  = '0  ;
//assign wshb_if_sdram.dat_ms = '0 ;
//assign wshb_if_sdram.sel = '0 ;
//assign wshb_if_sdram.cti = '0 ;
//assign wshb_if_sdram.bte = '0 ;


//--------------------------
//------- Code Eleves ------
//--------------------------

// Commandes préprocesseur

`ifdef SIMULATION
  localparam hcmpt1 = 6;
  localparam hcmpt2 = 4;
`else
  localparam hcmpt1 = 26;
  localparam hcmpt2 = 24;
`endif

// Déclaration des signaux internes

logic [hcmpt1:0] led1_cnt;
logic [hcmpt2:0] led2_cnt;
logic            pixel_rst;

// Génération de pixel_rst avec 2 bascules

logic Q;

always_ff @(posedge pixel_clk or posedge sys_rst)
if (sys_rst)
    Q <= 1;
else
    Q <= 0;

always_ff @(posedge pixel_clk or posedge sys_rst)
if (sys_rst)
    pixel_rst <= 1;
else
    pixel_rst <= Q;

// Comportement de LED[0], LED[1] et LED[2]

always_comb
    LED[0] = KEY[0];

always_ff @(posedge sys_clk)
if (sys_rst)
    led1_cnt <= 0;
else
    led1_cnt <= led1_cnt + 1;

always_comb
    LED[1] = (led1_cnt[hcmpt1] == 1);

always_ff @(posedge pixel_clk)
if (pixel_rst)
    led2_cnt <= 0;
else
    led2_cnt <= led2_cnt + 1;

always_comb
    LED[2] = (led2_cnt[hcmpt2] == 1);

// Instanciations

vga #(.HDISP(HDISP), .VDISP(VDISP)) vga1 (
    .pixel_clk(pixel_clk),
    .pixel_rst(pixel_rst),
    .video_ifm(video_ifm),
    .wshb_ifm(wshb_if_vga)
);

mire #(.HDISP(HDISP), .VDISP(VDISP)) mire1 (
    .wshb_ifm(wshb_if_mire)
);

wshb_intercon wshb_intercon1 (
    .wshb_ifs_mire(wshb_if_mire),
    .wshb_ifs_vga(wshb_if_vga),
    .wshb_ifm(wshb_if_sdram)
);


endmodule

/*



*/