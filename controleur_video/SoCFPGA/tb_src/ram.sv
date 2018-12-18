module ram  
    #(
        parameter ADDR_WIDTH = 10,
        parameter DATA_WIDTH = 32,
        parameter INIT_FILE = "none"
    )
    (
        input  wire                     clk,
        input  wire  [ADDR_WIDTH-1  :0] addr,
        input  wire  [DATA_WIDTH-1  :0] wdata, 
        input  wire  [DATA_WIDTH/8-1:0] Be,
        input  wire                     we,
        output logic [DATA_WIDTH-1  :0] rdata
    );

localparam DEPTH    = 2**ADDR_WIDTH; 
localparam BE_WIDTH = DATA_WIDTH/8;

logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];

generate
  if(!(INIT_FILE=="none"))
  begin
      initial 
          $readmemh(INIT_FILE, mem, 0, DEPTH - 1);
  end
endgenerate

generate
genvar i;
     for (i = 0; i < BE_WIDTH; i++) 
     begin:wstrb
       always_ff @(posedge clk)
       begin
         if (we && Be[i])
             mem[addr][8*(i) +:8] <= wdata[8*(i) +:8]; // [msb_base_exp+:width]
       end
     end
endgenerate

always_ff @(posedge clk)
begin
    if(!we)
        rdata <= mem[addr];
end

endmodule

