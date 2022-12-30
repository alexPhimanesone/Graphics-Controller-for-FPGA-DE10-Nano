module MED (DI, DSI, BYP, clk, DO);

    parameter SIZE  = 9;
    parameter WIDTH = 8;

    input  [WIDTH-1:0] DI;
    input              DSI;
    input              BYP;
    input              clk;
    output [WIDTH-1:0] DO;
    
    logic [WIDTH-1:0] V [0:SIZE-1];
    logic [WIDTH-1:0] MAX,MIN;

    MCE MCE0 (.A(V[SIZE-1]), .B(V[SIZE-2]), .MAX(MAX), .MIN(MIN));

    always_ff @(posedge clk)
    if (DSI == 1)
        V[0] <= DI;
    else
        V[0] <= MIN;
    
    always_ff @(posedge clk)
        V[1:SIZE-2] <= V[0:SIZE-3];
    
    always_ff @(posedge clk)
    if (BYP == 0)
        V[SIZE-1] <= MAX;
    else
        V[SIZE-1] <= V[SIZE-2];
    
    assign DO = V[SIZE-1];
    
endmodule
