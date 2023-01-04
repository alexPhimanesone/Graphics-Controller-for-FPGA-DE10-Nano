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

      assign ack_w = wb_s.we & wb_s.stb;

      

      always_ff @(posedge clk)
      if (wb_s.rst)
            ack_r <= 0;
      else
            ack_r <= ~wb_s.we & wb_s.stb;

      assign wb_s.ack = ack_w | ack_r;
      
      // code de la memoire
      always_ff @(posedge wb_s.clk)
      begin
            if(wb_s.we)
                  mem[wb_s.adr] <= wb_s.dat_sm;
            wb_s.dat <= mem[wb_s.adr];
      end






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
- (mettre rty et err à 0)
*/