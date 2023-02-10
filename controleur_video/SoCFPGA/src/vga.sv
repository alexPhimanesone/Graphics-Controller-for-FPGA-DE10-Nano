`default_nettype none

module vga #(
    parameter       HDISP = 800,
    parameter       VDISP = 480) (
    input wire      pixel_clk,
    input wire      pixel_rst,
    video_if.master video_ifm,
    wshb_if.master  wshb_ifm
);

// Pour l'affichage

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

// Pour la FIFO

localparam DATA_WIDTH = 32;
localparam ALMOST_FULL_THRESHOLD = 224;


//====================================================
// Déclaration des signaux internes
//====================================================

// Pour l'affichage

logic [$clog2(TOTAL_HEIGHT):0] ln_cnt;
logic [$clog2(TOTAL_WIDTH):0]  pixel_cnt;
logic [$clog2(TOTAL_HEIGHT):0] ln_cnt_disp;
logic [$clog2(TOTAL_WIDTH):0]  pixel_cnt_disp;

// Pour la lecture dans la SDRAM

logic [31:0] pixel_adr;

// Pour la FIFO

wire                   read;
wire [DATA_WIDTH-1:0]  wdata;

logic [DATA_WIDTH-1:0] rdata;
logic                  rempty;
logic                  wfull;
logic                  walmost_full;

logic                  wfull_pixel;
logic                  preload; // avant un affichage, indique si la pile est remplie


//====================================================
// Affichage
//====================================================

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


//====================================================
// Lecture en SDRAM
//====================================================

assign wshb_ifm.we     = 1'b0;
assign wshb_ifm.sel    = 4'b0111;

assign wshb_ifm.cti    = '0;
assign wshb_ifm.bte    = '0;

// Calcul de l'adresse de lecture

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    pixel_adr <= 32'b0;
else
    if (wshb_ifm.ack)
        if (pixel_adr >= VDISP * HDISP - 1)
            pixel_adr <= 32'b0;
        else
            pixel_adr <= pixel_adr + 1;

assign wshb_ifm.adr = 4 * pixel_adr;

// Controleur de lecture en SDRAM

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    wshb_ifm.cyc <= 0;
else
    if (~walmost_full)
        wshb_ifm.cyc <= 1;
    else if (wfull)
        wshb_ifm.cyc <= 0;

assign wshb_ifm.stb = wshb_ifm.cyc & ~wfull;


//====================================================
// Ecriture et lecture de la FIFO
//====================================================

async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD))
    async_fifo1 (
    .rst(wshb_ifm.rst),
    .rclk(pixel_clk),
    .read(read),
    .rdata(rdata),
    .rempty(rempty),
    .wclk(wshb_ifm.clk),
    .wdata(wdata),
    .write(wshb_ifm.ack),
    .wfull(wfull),
    .walmost_full(walmost_full)
);

// Ecriture en FIFO

assign wdata = wshb_ifm.dat_sm[23:0];

// Lecture de la FIFO

assign video_ifm.RGB = rdata[23:0];

// Rééchantillonnage du signal wfull dans le domaine pixel_clk

logic Q;

always_ff @(posedge pixel_clk)
if (pixel_rst)
    Q <= 0;
else
    Q <= wfull;

always_ff @(posedge pixel_clk)
if (pixel_rst)
    wfull_pixel <= 0;
else
    wfull_pixel <= Q;

// Comportement du signal preload

always_ff @(posedge pixel_clk)
if (wshb_ifm.rst)
    preload <= 0;
else
    if (wfull_pixel & ~video_ifm.BLANK)
        preload <= 1;

// Controle de la lecture

assign read = video_ifm.BLANK & preload & ~rempty;


endmodule

