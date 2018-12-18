//
// avlst2wshb.sv
// @brief : 
//     A avalon stream to wishbone bridge
//
`default_nettype none

module avlst2wshb 
#(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32
)
(
    avlst_if.slave avl_ifs,
    wshb_if.master wshb_ifm
);

localparam  WB_MAX_TRANS_NB = 16; // Max transaction number during one cyc assertion

typedef enum {
               WAIT_ID_CTL_DATA, 
               RD_CTL_DATA, 
               WAIT_START_VIDEO_DATA, 
               RD_VIDEO_DATA,
               RD_VIDEO_DATA_1
             } avl_fsm;

avl_fsm r_state;

logic fifo_full;
logic fifo_alfull;
logic fifo_empty;
logic fifo_alempty;
logic fifo_write;
logic [DATA_WIDTH:0] wdata_eop;
logic [DATA_WIDTH:0] rdata_eop;


always_ff @(posedge wshb_ifm.clk)
if(wshb_ifm.rst)
begin
    r_state <= WAIT_ID_CTL_DATA;
end
else
    case (r_state)
        WAIT_ID_CTL_DATA:
            // wait for control data packet identifier
            if(avl_ifs.valid && avl_ifs.startofpacket && avl_ifs.data[3:0] == 4'hf)
            begin
                r_state   <= RD_CTL_DATA;
            end

        RD_CTL_DATA:
            // read reamin control data
            if(avl_ifs.valid && avl_ifs.endofpacket)
                r_state <= WAIT_START_VIDEO_DATA;
           
        WAIT_START_VIDEO_DATA:
            // wait for start video datat
            if(avl_ifs.valid && avl_ifs.startofpacket && avl_ifs.data[3:0] == 4'h0)
                r_state <= RD_VIDEO_DATA;

        // Transfer with backpressure, readylatency = 1    
        RD_VIDEO_DATA:
            if(fifo_alfull && avl_ifs.valid && !avl_ifs.endofpacket)
                r_state <= RD_VIDEO_DATA_1;
            else if(!fifo_full && avl_ifs.valid && avl_ifs.endofpacket)
                    r_state <= WAIT_ID_CTL_DATA;

        RD_VIDEO_DATA_1:
            // fifo is full, if ack then read fifo and send ready since 
            // one can accpet valid request nex cycle
            if(wshb_ifm.ack) 
                r_state <= RD_VIDEO_DATA;

        default:
            r_state <= WAIT_ID_CTL_DATA;
    endcase

logic [ADDR_WIDTH-1:0] r_pix_adr;
logic r_stall;

always_ff @(posedge wshb_ifm.clk)
if(wshb_ifm.rst)
begin
    r_stall   <= '1;
    r_pix_adr <= '0;
end
else
begin
    r_stall <= 1'b0;
    if(wshb_ifm.ack)
    begin
        r_stall   <= (r_pix_adr[ADDR_WIDTH-1:2] % WB_MAX_TRANS_NB) == WB_MAX_TRANS_NB - 1;
        r_pix_adr <= r_pix_adr + 4'h4;
        
        if(rdata_eop[DATA_WIDTH]) // end of packet
            r_pix_adr <= '0;
    end
end

assign fifo_write = (r_state == RD_VIDEO_DATA) && avl_ifs.valid;

assign wdata_eop = {avl_ifs.endofpacket, avl_ifs.data};

assign avl_ifs.ready    = !((r_state == RD_VIDEO_DATA) || (r_state == RD_VIDEO_DATA_1)) ||
                           ((r_state == RD_VIDEO_DATA) && !fifo_alfull) ||
                           ((r_state == RD_VIDEO_DATA_1) && wshb_ifm.ack);

assign wshb_ifm.cyc     = !r_stall;
assign wshb_ifm.stb     = !fifo_empty && !r_stall;
assign wshb_ifm.adr     = r_pix_adr;
assign wshb_ifm.we      = 1'b1;
assign wshb_ifm.sel     = 4'hf;
assign wshb_ifm.dat_ms  = rdata_eop[DATA_WIDTH-1:0];
assign wshb_ifm.cti     = '0;
assign wshb_ifm.bte     = '0;


sync_fifo
#(
    .WIDTH(DATA_WIDTH+1),
    .DEPTH(4)
)
sync_fifo_i
(
    .clk(wshb_ifm.clk),
    .reset(wshb_ifm.rst),
    .write(fifo_write),
    .wdata(wdata_eop),
    .read(wshb_ifm.ack),
    .rdata(rdata_eop),
    .empty(fifo_empty),
    .full (fifo_full),
    .almost_full (fifo_alfull),
    .almost_empty(fifo_alempty)
);


endmodule


