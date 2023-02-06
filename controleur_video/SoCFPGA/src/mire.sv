`default_nettype none

module mire #(
    parameter       HDISP = 800,
    parameter       VDISP = 480) (
    wshb_if.master  wshb_ifm
);

// Déclaration des signaux internes

logic [$clog2(VDISP):0] ln_cnt_disp;
logic [$clog2(HDISP):0] pixel_cnt_disp;

logic [5:0] cyc_stb_cnt;

// Comportement des compteurs

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    pixel_cnt_disp <= 0;
else
    if (wshb_ifm.ack)
        if (pixel_cnt_disp >= HDISP-1)
            pixel_cnt_disp <= 0;
        else
            pixel_cnt_disp <= pixel_cnt_disp + 1;

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    ln_cnt_disp <= 0;
else
    if (wshb_ifm.ack)
        if (pixel_cnt_disp == HDISP-1)
            if (ln_cnt_disp >= VDISP-1)
                ln_cnt_disp <= 0;
            else
                ln_cnt_disp <= ln_cnt_disp + 1;

// Controleur d'ecriture

assign wshb_ifm.we  = 1'b1;
assign wshb_ifm.sel = 4'b0111;

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    cyc_stb_cnt <= 0;
else
begin
    logic en;
    en = ((cyc_stb_cnt < 6'b111111) || wshb_ifm.ack);
    if (en)
        cyc_stb_cnt <= cyc_stb_cnt + 1;
end

assign wshb_ifm.cyc = ~(cyc_stb_cnt == 0);
assign wshb_ifm.stb = ~(cyc_stb_cnt == 0);

// Donnees a ecrire

always_comb
begin
    wshb_ifm.dat_ms = {8'h0, 8'h0, 8'h0};
    if ((ln_cnt_disp[3:0] == 4'b0) || (pixel_cnt_disp[3:0] == 4'b0))
        wshb_ifm.dat_ms = {8'hff, 8'hff, 8'hff};
end

// Adresse d'ecriture

always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    wshb_ifm.adr <= 32'b0;
else
    if (wshb_ifm.ack)
        if (wshb_ifm.adr >= 4 * (VDISP * HDISP - 1))
            wshb_ifm.adr <= 32'b0;
        else
            wshb_ifm.adr <= wshb_ifm.adr + 4;

endmodule