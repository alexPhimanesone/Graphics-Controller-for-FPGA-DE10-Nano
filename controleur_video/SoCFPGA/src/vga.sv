`default_nettype none

module vga #(
    parameter       HDISP = 800,
    parameter       VDISP = 480) (
    input wire      pixel_clk,
    input wire      pixel_rst,
    video_if.master video_ifm,
    wshb_if.master  wshb_ifm
);

localparam HFP          = 40;
localparam HPULSE       = 48;
localparam HBP          = 40;
localparam VFP          = 13;
localparam VPULSE       = 3;
localparam VBP          = 29;
localparam TOTAL_WIDTH  = HFP + HPULSE + HBP + HDISP;
localparam TOTAL_HEIGHT = VFP + VPULSE + VBP + VDISP;
localparam HBLANK       = TOTAL_WIDTH - HDISP;
localparam VBLANK       = TOTAL_HEIGHT - VDISP;

//==================================
// Déclaration des signaux internes
//==================================

// Pour l'affichage

logic [$clog2(TOTAL_HEIGHT):0] ln_cnt;
logic [$clog2(TOTAL_WIDTH):0]  pixel_cnt;
logic [$clog2(VDISP):0]        ln_cnt_disp;
logic [$clog2(HDISP):0]        pixel_cnt_disp;

// Pour la lecture dans la SDRAM

logic [31:0] pixel_adr;

//===========
// Affichage
//===========

// Gestion de l'horloge

assign video_ifm.CLK = pixel_clk;

// Comportement des compteurs

always_ff @(posedge pixel_clk)
if (pixel_rst)
    pixel_cnt <= 0;
else
    if (pixel_cnt >= TOTAL_WIDTH-1)
        pixel_cnt <= 0;
    else
        pixel_cnt <= pixel_cnt + 1;

always_ff @(posedge pixel_clk)
if (pixel_rst)
    ln_cnt <= 0;
else
    if (pixel_cnt == TOTAL_WIDTH-1)
        if (ln_cnt >= TOTAL_HEIGHT-1)
            ln_cnt <= 0;
        else
            ln_cnt <= ln_cnt + 1;

always_comb
begin
    ln_cnt_disp = ln_cnt - VBLANK;
    pixel_cnt_disp = pixel_cnt - HBLANK;
end

// Comportement des signaux de synchronisation

always_ff @(posedge pixel_clk)
if (pixel_rst)
begin
    video_ifm.HS <= 1;
    video_ifm.VS <= 1;
end
else
begin
    video_ifm.HS <= ~((pixel_cnt >= HFP) && (pixel_cnt < HFP + HPULSE));
    video_ifm.VS <= ~((ln_cnt >= VFP) && (ln_cnt < VFP + VPULSE));
end

always_ff @(posedge pixel_clk)
if (pixel_rst)
    video_ifm.BLANK <= 1;
else
    video_ifm.BLANK <= ~((pixel_cnt < HBLANK) || (ln_cnt < VBLANK));

// Generation d'une mire

//always_ff @(posedge pixel_clk)
//if (pixel_rst)
//    video_ifm.RGB <= {8'h0, 8'h0, 8'h0};
//else
//begin
//    video_ifm.RGB <= {8'h0, 8'h0, 8'h0};
//    if ((ln_cnt_disp[3:0] == 4'b0) || (pixel_cnt_disp[3:0] == 4'b0))
//        video_ifm.RGB <= {8'hff, 8'hff, 8'hff};
//end

//===================
// Lecture en SDRAM
//===================

assign wshb_ifm.cyc    = 1'b1;
assign wshb_ifm.we     = 1'b0;
assign wshb_ifm.sel    = 4'b0111;

assign wshb_ifm.cti    = '0;
assign wshb_ifm.bte    = '0;

//always_ff @(posedge wshb_ifm.clk)
//if (wshb_ifm.rst)
//    (ecrire dans la fifo) <= {8'h0, 8'h0, 8'h0};
//else
//    (ecrire dans la fifo) <= wshb_ifm.ack & wshb_ifm.dat_sm[23:0]; 

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    pixel_adr <= 32'b0;
else
    if (pixel_adr >= VDISP * HDISP - 1)
        pixel_adr <= 32'b0;
    else
        if (wshb_ifm.ack)
            pixel_adr <= pixel_adr + 1;

assign wshb_ifm.adr = 4 * pixel_adr;

//pour l'instant on a pas le signal (fifo non pleine) donc simple
//always_ff @(posedge wshb_ifm.clk)
//if (wshb_ifm.rst)
//    wshb_ifm.stb <= 1'b0;
//else
//    wshb_fm.stb <= (fifo non pleine)
assign wshb_ifm.stb = 1'b1;


endmodule

/*
compteur dep de ack, +4 que si ack
droit de faire une requete que si la fifo n'est pas pleine
*/