//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre 
// de mots de la mémoire : (2048 pour mem_adr_width=11)


module wb_bram #(parameter mem_adr_width = 11) (
      // Wishbone interface
      wshb_if.slave wb_s
      );      
      // a vous de jouer a partir d'ici

      localparam SIZE = 2 ** mem_adr_width;
      logic [31:0] mem [0:SIZE];

      wire ack_w;
      logic ack_r;
      wire [mem_adr_width + 1:2] adr;

      // Gestion de ACK

      assign ack_w = wb_s.we & wb_s.stb;

      always_ff @(posedge wb_s.clk)
      if (wb_s.rst)
            ack_r <= 0;
      else
            ack_r <= ~wb_s.we & wb_s.stb & ~ack_r;

      assign wb_s.ack = ack_w | ack_r;
      
      // Gestion de la mémoire
      
      assign adr = wb_s.adr[mem_adr_width + 1:2];

      always_ff @(posedge wb_s.clk)
      begin
            if(wb_s.we)
            begin
                  if (wb_s.sel[0])
                        mem[adr][7:0]   <= wb_s.dat_ms[7:0];
                  if (wb_s.sel[1])
                        mem[adr][15:8]  <= wb_s.dat_ms[15:8];
                  if (wb_s.sel[2])
                        mem[adr][23:16] <= wb_s.dat_ms[23:16];
                  if (wb_s.sel[3])
                        mem[adr][31:24] <= wb_s.dat_ms[31:24];
            end
            wb_s.dat_sm <= mem[adr];
      end

      // On force RTY et ERR a 0
      assign wb_s.rty = 0;
      assign wb_s.err = 0;

endmodule





/*
- au front d'horloge, écrire dans la mémoire
- "la memoire c'est juste une table"
- regarder STB (pas besoin de regarder CYC)
- generer ACK combinatoirement en ecriture
mais apres un cycle pour la lecture
(1 cycle d'horloge pour que la donnee sorte de la RAM)
(en cas d'ecriture ACK c'est STB
en cas de lecture c'est STB en retard d'un cycle)
- c'est toi qui decides si le reset est synchrone ou asynchrone
- mettre rty et err à 0 (indique dans le cours)
*/