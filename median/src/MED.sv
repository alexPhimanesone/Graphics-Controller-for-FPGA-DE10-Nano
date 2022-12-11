module MED (DI, DSI, BYP, clk, DO);

    parameter SIZE  = 9;
    parameter WIDTH = 8;

    input  [WIDTH-1:0] DI;
    input              DSI;
    input              BYP;
    input              clk;
    output [WIDTH-1:0] DO;
    
    logic [3:0] compteur;
    logic [WIDTH-1:0] V [0:WIDTH-1];

    // initialiser compteur a 0
    initial
    begin
        compteur = '0;    
    end

    always_ff @(posedge clk)
    begin
        if (DSI == 1)
        begin
            V[compteur] =
        end
    end








endmodule