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
      logic [31:0] mem [0:SIZE-1];

      wire ack_w;
      logic ack_r;
      logic [mem_adr_width + 1:2] adr;
      logic [mem_adr_width + 1:2] start_adr;
      logic [mem_adr_width + 1:2] cnt;
      wire incr_bst;

      assign incr_bst = (wb_s.cti == 3'b010);

      // Gestion de ACK

      assign ack_w = wb_s.we & wb_s.stb;

      always_ff @(posedge wb_s.clk)
      if (wb_s.rst)
            ack_r <= 0;
      else
            ack_r <= ~wb_s.we & wb_s.stb & (~ack_r | incr_bst);

      assign wb_s.ack = ack_w | ack_r;
      
      // Determination de l'adresse

      always_comb
            if (cnt == 0)
                  adr = wb_s.adr[mem_adr_width + 1:2];
            else
                  adr = start_adr + cnt;

      always_ff @(posedge wb_s.clk)
      if (wb_s.rst)
            cnt <= 0;
      else
            if (wb_s.stb && incr_bst)
                  cnt <= cnt + 1;
            else
                  cnt <= 0;

      always_ff @(posedge wb_s.clk)
            if (wb_s.stb && cnt == 0)
                  start_adr <= wb_s.adr[mem_adr_width + 1:2];
      
      // Ecriture et lecture

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

endmodule
