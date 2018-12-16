
// October 2018 
// @brief : wishbone ram controller using latency and burst mode for read operations 
`default_nettype none
 module wb_ram_ctl
 #(
    parameter DEPTH   = 1024,
    parameter WIDTH   = 32,
    parameter LATENCY = 16,
    parameter INIT_FILE = "none"
 )
 (
    wshb_if.slave wshb_ifs
 );

localparam ADDR_WIDTH = $clog2(DEPTH);
localparam DATA_WIDTH = WIDTH;
localparam ADDR_OFFSET = $clog2(DATA_WIDTH/8);

localparam ADDR_HIGH  = ADDR_WIDTH + ADDR_OFFSET;
localparam ADDR_LOW   = ADDR_OFFSET;

logic r_ack;
logic [3:0] r_lat;
logic [7:0] r_burst_cnt;
logic [ADDR_WIDTH -1:0] r_addr;

typedef enum {IDLE, READ} fsm;
fsm r_state;

wire [ADDR_WIDTH-1:0] s_addr = (r_state == IDLE) ? wshb_ifs.adr[ADDR_HIGH-1:ADDR_LOW] : r_addr + 1'b1;

ram
#(
    ADDR_WIDTH,
    DATA_WIDTH,
    INIT_FILE
)
ram_inst
(
    .clk  (wshb_ifs.clk),
    .addr (s_addr),
    .wdata(wshb_ifs.dat_ms),
    .Be   (wshb_ifs.sel),
    .we   (wshb_ifs.cyc && wshb_ifs.stb && wshb_ifs.we),
    .rdata(wshb_ifs.dat_sm)
);


assign wshb_ifs.ack = ((r_state == IDLE) && wshb_ifs.cyc && wshb_ifs.stb && wshb_ifs.we) || r_ack;
assign wshb_ifs.err = 1'b0;
assign wshb_ifs.rty = 1'b0;


// ack_o
always_ff @(posedge wshb_ifs.clk)
  if (wshb_ifs.rst)
  begin
    r_state     <= IDLE;
    r_ack       <= 1'b0;
    r_lat       <= LATENCY - 1;
    r_burst_cnt <= '0;
    r_addr      <= '0;
  end
  else
      case (r_state)
          IDLE:
              if(wshb_ifs.cyc && wshb_ifs.stb && !wshb_ifs.we)
              begin
                  if(r_lat == '0)
                  begin
                      r_ack       <= 1'b1;
                      r_lat       <= LATENCY - 1;
                      r_burst_cnt <= '0;
                      r_addr      <= wshb_ifs.adr[ADDR_HIGH-1:ADDR_LOW];

                      r_state <= READ;
                  end
                  else
                  begin
                      r_lat <= r_lat - 1'b1;
                      r_ack <= 1'b0;
                  end
              end
          
           READ:
           begin
               if (r_burst_cnt == 3'b111)
               begin
                   r_ack <= 1'b0;
                   r_state <= IDLE;
               end
               else if (wshb_ifs.cyc && wshb_ifs.stb)
               begin
                   if(wshb_ifs.adr[ADDR_HIGH-1:ADDR_LOW] == r_addr)
                   begin
                       r_ack       <= 1'b1;
                       r_addr      <= r_addr + 1'b1;
                       r_burst_cnt <= r_burst_cnt + 1'b1; 
                   end
                   else
                   begin
                       r_ack   <= 1'b0;
                       r_state <= IDLE;
                   end
               end;
           end
      endcase  
 
endmodule
