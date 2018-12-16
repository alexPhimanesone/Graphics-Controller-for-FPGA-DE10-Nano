// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// THIS FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THIS FILE OR THE USE OR OTHER DEALINGS
// IN THIS FILE.

/******************************************************************************
 *                                                                            *
 * This module generators a sample video input stream for DE boards.          *
 *                                                                            *
 ******************************************************************************/

module tpg_video 
(
    wshb_if.master wshb_ifm
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

localparam DW                       = 23;
localparam WW                       = 8;
localparam HW                       = 7;

localparam WIDTH                    = 160;
localparam HEIGHT                   = 90;

localparam VALUE                    = 8'd160;
localparam P_RATE                   = 24'd116508;
localparam TQ_START_RATE            = 25'd393216;
localparam TQ_RATE_DECELERATION     = 25'd4369;

localparam  MAX_TRANS               = 16; // Max transaction number during one cyc assertion
/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires

wire            [ 7: 0]    red;
wire            [ 7: 0]    green;
wire            [ 7: 0]    blue;

// Internal Registers
logic            [WW: 0]    x;
logic            [HW: 0]    y;

logic            [10: 0]    hue;
logic            [ 2: 0]    hue_i;

logic            [23: 0]    p;
logic            [24: 0]    q;
logic            [24: 0]    t;

logic            [24: 0]    rate;

logic                       stall;

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

// Color Space Conversion from HSV to RGB
//
// HSV - Hue, Saturation, and Value
//
// Hue            - 0 to 360
// Saturation    - 0 to 1
// Value        - 0 to 1
//
// h_i    = floor (h / 60) mod 6
// f    = (h / 60) - floor (h / 60)
// p    = v * (1 - s) 
// q    = v * (1 - f * s) 
// t    = v * (1 - (1 - f) * s) 
//
//       { (v, t, p) if h_i = 0
//       { (q, v, p) if h_i = 1
// RGB = { (p, v, t) if h_i = 2
//       { (p, q, v) if h_i = 3
//       { (t, p, v) if h_i = 4
//       { (v, p, q) if h_i = 5
//
// Source: http://en.wikipedia.org/wiki/HSL_color_space#Conversion_from_HSV_to_RGB
//

// Output Registers

// Internal Registers
always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
        x <= 'h0;
    else if (wshb_ifm.ack)
    begin
        if (x == (WIDTH - 1))
            x <= 'h0;
        else
            x <= x + 1'b1;
    end
end

always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
        y <= 'h0;
    else if (wshb_ifm.ack && (x == (WIDTH - 1)))
    begin
        if (y == (HEIGHT - 1))
            y <= 'h0;
        else
            y <= y + 1'b1;
    end
end

always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
        stall <= 1'b1;
    else 
    begin
        stall <= 1'b0;
        if (wshb_ifm.ack)
           stall <= ((y*WIDTH+x) % MAX_TRANS) == MAX_TRANS - 1;
    end
end

always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
    begin
        hue    <= 'h0;
        hue_i    <= 'h0;
    end
    else if (wshb_ifm.ack)
    begin
        if (x == (WIDTH - 1))
        begin
            hue    <= 'h0;
            hue_i    <= 'h0;
        end
        else if (hue == ((WIDTH / 6) - 1))
        begin
            hue    <= 'h0;
            hue_i    <= hue_i + 1'b1;
        end
        else
            hue    <= hue + 1'b1;
    end
end

always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
    begin
        p        <= 'h0;
        q        <= {1'b0, VALUE, 16'h0000};
        t        <= 'h0;
        rate    <= TQ_START_RATE;
    end
    else if (wshb_ifm.ack)
    begin
        if ((x == (WIDTH - 1)) && (y == (HEIGHT - 1)))
        begin
            p       <= 'h0;
            rate    <= TQ_START_RATE;
        end
        else if (x == (WIDTH - 1))
        begin
            p        <= p + P_RATE;
            rate    <= rate - TQ_RATE_DECELERATION;
        end

        if ((x == (WIDTH - 1)) && (y == (HEIGHT - 1)))
        begin
            q        <= {1'b0, VALUE, 16'h0000};
            t        <= 'h0;
        end
        else if (x == (WIDTH - 1))
        begin
            q        <= {1'b0, VALUE, 16'h0000};
            t        <= p + P_RATE;
        end
        else if ((hue == ((WIDTH / 6) - 1)) && (hue_i != 5))
        begin
            q        <= {1'b0, VALUE, 16'h0000};
            t        <= p;
        end
        else
        begin
            q        <= q - rate;
            t        <= t + rate;
        end


    end
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// Output Assignments

assign wshb_ifm.adr     = (y*WIDTH+x) << 2'b10;
assign wshb_ifm.dat_ms  = {8'h0, red, green, blue};
assign wshb_ifm.sel     = 4'hf; 
assign wshb_ifm.we      = 1'b1; 
assign wshb_ifm.cyc     = !stall;
assign wshb_ifm.stb     = !stall;
assign wshb_ifm.cti     = '0;
assign wshb_ifm.bte     = '0;

// Internal Assignments
assign red = 
        (hue_i == 0) ?    VALUE :
        (hue_i == 1) ?    q[23:16] & {8{~q[24]}}: // 8'h00 :
        (hue_i == 2) ?    p[23:16] :
        (hue_i == 3) ?    p[23:16] :
        (hue_i == 4) ?    t[23:16] | {8{t[24]}} : // 8'h00 :
                        VALUE;
    
assign green = 
        (hue_i == 0) ?    t[23:16] | {8{t[24]}} : // 8'h00 :
        (hue_i == 1) ?    VALUE :
        (hue_i == 2) ?    VALUE :
        (hue_i == 3) ?    q[23:16] & {8{~q[24]}} : // 8'h00 :
        (hue_i == 4) ?    p[23:16] :
                        p[23:16];
assign blue = 
        (hue_i == 0) ?    p[23:16] :
        (hue_i == 1) ?    p[23:16] :
        (hue_i == 2) ?    t[23:16] | {8{t[24]}} : // 8'h00 :
        (hue_i == 3) ?    VALUE :
        (hue_i == 4) ?    VALUE :
                        q[23:16] & {8{~q[24]}}; // 8'h00;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

