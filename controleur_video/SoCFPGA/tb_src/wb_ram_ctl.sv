
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

logic [3:0] r_lat, s_lat;
logic [7:0] r_burst_cnt, s_burst_cnt;
logic [ADDR_WIDTH -1:0] s_addr, r_addr;

typedef enum {IDLE, READ} fsm;
fsm r_state, s_state;

wire valid_read_req  = wshb_ifs.cyc && wshb_ifs.stb && !wshb_ifs.we;
wire valid_write_req = wshb_ifs.cyc && wshb_ifs.stb &&  wshb_ifs.we;

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
    .we   (valid_write_req),
    .rdata(wshb_ifs.dat_sm)
);

assign wshb_ifs.err = 1'b0;
assign wshb_ifs.rty = 1'b0;


always_comb
begin
    s_state      = r_state;
    s_addr       = r_addr;
    s_lat        = r_lat;
    s_burst_cnt  = r_burst_cnt;

    wshb_ifs.ack = 1'b0;

    case (r_state)
        IDLE:
        if(valid_read_req)
        begin
            if(r_lat == '0)
            begin
                 s_lat       = LATENCY - 1;
                 s_burst_cnt = '0;
                 s_addr      = wshb_ifs.adr[ADDR_HIGH-1:ADDR_LOW];

                 s_state     = READ;
              end
              else
              begin
                  s_lat = r_lat - 1'b1;
              end
          end
        else if(valid_write_req)
        begin
            s_addr       = wshb_ifs.adr[ADDR_HIGH-1:ADDR_LOW];
            wshb_ifs.ack = 1'b1;
        end

        READ:
        if ((valid_read_req) && (wshb_ifs.adr[ADDR_HIGH-1:ADDR_LOW] == r_addr))
        begin
            wshb_ifs.ack = 1'b1;

            if (r_burst_cnt == 3'b111)
                s_state = IDLE;
            else
            begin
                s_addr       = r_addr + 1'b1;
                s_burst_cnt  = r_burst_cnt + 1'b1;
            end
        end
        else
            s_state = IDLE;
    endcase
end
// ack_o
always_ff @(posedge wshb_ifs.clk)
  if (wshb_ifs.rst)
  begin
    r_state     <= IDLE;
    r_lat       <= LATENCY - 1;
    r_burst_cnt <= '0;
    r_addr      <= '0;
  end
  else
  begin
    r_state     <= s_state;
    r_lat       <= s_lat;
    r_burst_cnt <= s_burst_cnt;
    r_addr      <= s_addr;
  end

endmodule
