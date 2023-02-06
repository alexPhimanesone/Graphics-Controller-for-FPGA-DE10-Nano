`default_nettype none

module wshb_intercon (
    wshb_if.slave  wshb_ifs_mire,
    wshb_if.slave  wshb_ifs_vga,
    wshb_if.master wshb_ifm
);


//====================================================
// Déclaration des signaux internes
//====================================================

enum logic {MIRE, VGA} token_owner, n_token_owner;


//====================================================
// Arbitrage
//====================================================

// Maj de l'etat courant
always_ff @(posedge wshb_ifm.clk)
if (wshb_ifm.rst)
    token_owner <= MIRE;
else
    token_owner <= n_token_owner;

// Calcul de l'etat futur
always_comb
begin
    n_token_owner = token_owner;
    case(token_owner)
        MIRE: if (~wshb_ifs_mire.cyc)
            n_token_owner = VGA;
        VGA : if (~wshb_ifs_vga.cyc)
            n_token_owner = MIRE;
    endcase
end


//====================================================
// Master work (sdram)
//====================================================

// Signal CYC
always_comb
    if (token_owner == MIRE)
        wshb_ifm.cyc = wshb_ifs_mire.cyc;
    else
        wshb_ifm.cyc = wshb_ifs_vga.cyc;


// Signal STB
always_comb
    if (token_owner == MIRE)
        wshb_ifm.stb = wshb_ifs_mire.stb;
    else
        wshb_ifm.stb = wshb_ifs_vga.stb;

// Signal WE
always_comb
    if (token_owner == MIRE)
        wshb_ifm.we = wshb_ifs_mire.we;
    else
        wshb_ifm.we = wshb_ifs_vga.we;

// Signal ADDR
always_comb
    if (token_owner == MIRE)
        wshb_ifm.adr = wshb_ifs_mire.adr;
    else
        wshb_ifm.adr = wshb_ifs_vga.adr;

// Signal SEL
always_comb
    if (token_owner == MIRE)
        wshb_ifm.sel = wshb_ifs_mire.sel;
    else
        wshb_ifm.sel = wshb_ifs_vga.sel;

// Signal DAT_MS
always_comb
    if (token_owner == MIRE)
        wshb_ifm.dat_ms = wshb_ifs_mire.dat_ms;
    else
        wshb_ifm.dat_ms = wshb_ifs_vga.dat_ms;


//====================================================
// Slave work (mire)
//====================================================

// Signal ACK
always_comb
    if (token_owner == MIRE)
        wshb_ifs_mire.ack = wshb_ifm.ack;
    else
        wshb_ifs_mire.ack = 0;

//====================================================
// Slave work (vga)
//====================================================

// Signal ACK
always_comb
    if (token_owner == VGA)
        wshb_ifs_vga.ack = wshb_ifm.ack;
    else
        wshb_ifs_vga.ack = 0;

// Signal DAT_SM
assign wshb_ifs_vga.dat_sm = wshb_ifm.dat_sm;


endmodule