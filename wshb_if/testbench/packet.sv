/*
Copyright (C) 2009 SysWip

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// YM for clean colored output (out of modelsim transcript)
`define STDERR 32'h8000_0002 

// YM / TPT added 1 bit selection to packet bit8 packet
package PACKET;

typedef bit [7:0]  bit8;
typedef bit8       packet[$];
typedef bit        sel_packet[$];
// Flag types
typedef enum {random_selection, full_selection, random_burst_selection} selection_mode ;
typedef enum {with_burst_tags, without_burst_tags} burst_tags ;


///////////////////////////////////////////////////////////////////////////////
// Class Packet:
///////////////////////////////////////////////////////////////////////////////
class Packet;
  /////////////////////////////////////////////////////////////////////////////
  //************************ Class Variables ********************************//
  /////////////////////////////////////////////////////////////////////////////
  rand int unsigned      rndNum;
  int unsigned           rndNumMin;
  int unsigned           rndNumMax;
  int unsigned           rndNumMult;
  // Constraints for "preadyDelay" random variable
  constraint c_rundNum {
                             rndNum inside {[rndNumMin:rndNumMax]};
                             rndNum%rndNumMult == 0;
                       }
  // Constraints for aligned masks
  rand bit[7:0] rndMask;
  int dbytes ;
  constraint word_align { 
                          dbytes == 8 ->  rndMask[7:0] inside { 8'b00000000, 8'b00000001, 8'b00000010, 8'b00000100, 
                                                                8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000, 
                                                                8'b10000000, 8'b00000011, 8'b00001100, 8'b00110000, 
                                                                8'b11000000, 8'b00001111, 8'b11110000, 8'b11111111 } ;
                          dbytes == 4 ->  rndMask[3:0] inside { 4'b0000, 4'b0001, 4'b0010, 4'b0100, 
                                                                4'b1000, 4'b0011, 4'b1100, 4'b1111} ;
                          dbytes == 2 -> rndMask[1:0] inside { 2'b00, 2'b01, 4'b10, 4'b11 }  ;
                        }
  /////////////////////////////////////////////////////////////////////////////
  //************************* Class Methods *********************************//
  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////
  //- genRndPkt(): Generates random packet with the given length.
  // added random selection bit / or all selected bits  
  // ...
  /////////////////////////////////////////////////////////////////////////////
  task genRndPkt(input int length, input selection_mode selMode, input int data_bytes, output packet pkt, output sel_packet selpkt);
    bit [7:0] selpattern ;
    pkt = {};
    selpkt = {};
    // in random_burst_selection mode, selection bits have a pattern of length data_bytes in order 
    // to have a constant selection partern on with data_byte  words busses.
    for (int i = 0; i < data_bytes; i++) begin
      selpattern[i] = $urandom_range(0,1) ;
    end

    for (int i = 0; i < length; i++) begin
      pkt.push_back($urandom_range(0, 255)); // random byte 
      if(selMode == random_selection)
        selpkt.push_back($urandom_range(0, 1)); // random selection bit
      if(selMode == random_burst_selection) begin
        selpkt.push_back(selpattern[i%data_bytes]); // random selection bit
      end
      else // all bytes are selected
        selpkt.push_back(1'b1) ; 
    end
  endtask

  /////////////////////////////////////////////////////////////////////////////
  //- genRndPkt(): Generates random packet of given number of aligned words
  // added random selection bit / or all selected bits  
  // added round packet size to an integer number of word of size "data_bytes"
  // added generate masks coherents with the word size (id correct byte addressing, or halfword addressing or word addressing)
  // for a 16 bits bus allowed masks are (01,10,11)
  // for a 32 bits bus (0001, 0010, 0101, 1111)
  // ...
  /////////////////////////////////////////////////////////////////////////////
  task genAlignedRndPkt(input int nbWords, input selection_mode selMode, input int data_bytes, output packet pkt, output sel_packet selpkt);
    automatic bit [7:0] selpattern = '1;
    pkt = {};
    selpkt = {};
    this.dbytes = data_bytes ;
    // in random_burst_selection mode, selection bits have a pattern of length data_bytes in order 
    // to have a constant selection partern on with data_byte  words busses.
    if(selMode == random_burst_selection) begin
      assert (this.randomize() ) 
      //assert (this.randomize() ) 
      else $fatal(0, "Gen Randon Number: Randomize failed");
      selpattern =  this.rndMask ;
    end

    for (int i = 0; i < nbWords; i++) begin
      if(selMode == random_selection)
       begin
         assert (this.randomize() ) 
         else $fatal(0, "Gen Randon Number: Randomize failed");
         selpattern =  this.rndMask ;
       end
      for(int j=0 ; j < data_bytes; j++) begin
        pkt.push_back($urandom_range(0, 255)); // random byte 
        selpkt.push_back(selpattern[j]); // random selection bit
      end
    end
  endtask


  /////////////////////////////////////////////////////////////////////////////
  //- genCntPkt(): Generates packet with the given length where the first byte
  // is 0 the second is 1 the third is 2 etc.
  // no mask selection in this mode (selection is always 1)
  /////////////////////////////////////////////////////////////////////////////
  task genCntPkt(input int length, output packet pkt, output sel_packet selpkt);
    bit8 pktElement = 8'b0; // data=0
    pkt = {};
    selpkt = {} ;
    for (int i = 0; i < length; i++) begin
      pkt.push_back(pktElement);
      selpkt.push_back(1'b1);
      pktElement++;
    end
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- genRndNum(): Generates random number with a given range and then rounds
  // up to be multiple to "mult" value.*/
  /////////////////////////////////////////////////////////////////////////////
  function int genRndNum(int unsigned min, max, mult=1);
    this.rndNumMin = min;
    this.rndNumMax = max;
    this.rndNumMult= mult;
    assert (this.randomize())
    else $fatal(0, "Gen Randon Number: Randomize failed");
    genRndNum = this.rndNum;
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- genRndPkt(): Generates random packet. The packet length will be generated
  // randomly in the given range and will be multiple to "mult" value.*/
  // added selection packet
  /////////////////////////////////////////////////////////////////////////////
  task genFullRndPkt(input int min, max, mult, input selection_mode selMode, input int data_bytes, output packet pkt, output sel_packet selpkt );
    int length = this.genRndNum(min, max, mult);
    this.genRndPkt(length, selMode, data_bytes, pkt, selpkt);
  endtask

  /////////////////////////////////////////////////////////////////////////////
  /*- Print3Pkt(): Prints given "str" string and then packet containt.*/
  // added selection packet
  // YM added padding for a clear display of word / bytes
  // Warning only usable for aligned packets
  /////////////////////////////////////////////////////////////////////////////
  function void Print3Pkt(string str, packet initPkt, packet resPkt, packet expPkt, sel_packet selpkt, sel_packet errPkt, int addr, int data_bytes, bit addErrColor, bit useSel, int length=0);
  int mask ;
    int naddr ;
    int pos ;
    string results[$] ;
    string sr ;
    bit sel;

    if(length==0) begin
      length = expPkt.size();
    end
    $fwrite(`STDERR,"%s: Packet size is %d bytes\n", str, expPkt.size());
    $fwrite(`STDERR,"%s\n", str);
    if(data_bytes==4) $fwrite(`STDERR,"address   Initial read data         Written data              Read data\n") ;
    if(data_bytes==2) $fwrite(`STDERR,"address   Initial read  Written data  Read data\n") ;
    
    // Check alignement
    mask = addr & ((1 << $clog2(data_bytes)) - 1) ;
    naddr = addr ;
    assert (mask == 0 ) else $fatal(0, "Packet is not word aligned");
    

    for (int i = 0; i <= length/data_bytes; i++) begin
      $fwrite(`STDERR,"%h  ", naddr) ;
      naddr = naddr + data_bytes ;
      for (int j=0; j < data_bytes; j++) begin
         $swrite(sr,"(%b,%h)",1'b1,initPkt[data_bytes*i+j]);
         results.push_front(sr) ;
      end
      for(int j = 0; j < data_bytes;j++) $fwrite(`STDERR,results.pop_front()) ;
      $fwrite(`STDERR,"  "); 

      for (int j=0; j < data_bytes; j++) begin
         $swrite(sr,"(%b,%h)",selpkt[data_bytes*i+j],expPkt[data_bytes*i+j]);
         results.push_front(sr) ;
      end
      for(int j = 0; j < data_bytes;j++) $fwrite(`STDERR,results.pop_front()) ;
      $fwrite(`STDERR,"  "); 
      
      for (int j=0; j < data_bytes; j++) begin
         if(errPkt[data_bytes*i+j]) 
            $swrite(sr,"\033[91m(%b,%h)\033[0m",selpkt[data_bytes*i+j],resPkt[data_bytes*i+j]);
         else
            $swrite(sr,"\033[92m(%b,%h)\033[0m",selpkt[data_bytes*i+j],resPkt[data_bytes*i+j]);
         results.push_front(sr) ;
      end
      for(int j = 0; j < data_bytes;j++) $fwrite(`STDERR,results.pop_front()) ;
      $fwrite(`STDERR,"\n");
    end
    $fwrite(`STDERR,"\n");
  endfunction

  /////////////////////////////////////////////////////////////////////////////
  /*- PrintPkt(): Prints given "str" string and then packet containt.*/
  // added selection packet
  // YM added padding for a clear display of word / bytes
  /////////////////////////////////////////////////////////////////////////////
  function void PrintPkt(string str, packet pkt, sel_packet selpkt, sel_packet errPkt, int addr, int data_bytes, bit addErrColor, bit useSel, int length=0);
    int mask ;
    int naddr ;
    int pos ;
    string results[$] ;
    string sr ;
    bit sel;

    if(length==0)begin
      length = pkt.size();
    end
    //$fwrite(`STDERR,"%s: Packet size is %d bytes\n", str, pkt.size());
    $fwrite(`STDERR,"%s\n", str);
    // Padding in order to obtain an aligned word
    mask = addr & ((1 << $clog2(data_bytes)) - 1) ;
    naddr = (addr >> $clog2(data_bytes)) << $clog2(data_bytes) ;
    if(mask > 0) begin
      for (int i=0;i<(mask & addr);i++) begin
        results.push_front("(0,xx)");
      end
    end

    for (int i = 1; i <= length; i++) begin
      if (results.size() == data_bytes)  
      begin
        $fwrite(`STDERR,"address == %h ", naddr) ;
        for(int i = 0; i < data_bytes;i++) 
          $fwrite(`STDERR,results.pop_front()) ;
        $fwrite(`STDERR,"\n");
        naddr = naddr + data_bytes ;
      end
      if(useSel) sel=selpkt[i-1] ; else sel=1 ;
      if(addErrColor) begin
        if(errPkt[i-1] == 1) begin
          $swrite(sr,"\033[91m(%b,%h)\033[0m",sel,pkt[i-1]);
        end
        else
          $swrite(sr,"\033[92m(%b,%h)\033[0m",sel,pkt[i-1]);
      end 
      else
        $swrite(sr,"(%b,%h)",sel,pkt[i-1]);

      results.push_front(sr) ;
    end
    pos = results.size() ;
    if(pos == data_bytes) 
        $fwrite(`STDERR,"address == %h ", naddr) ;
    while (results.size() != 0) 
            $fwrite(`STDERR,results.pop_front()) ;
    if(pos != 0) 
    while (pos != data_bytes) 
    begin
         $fwrite(`STDERR,"(0,xx)");
         pos++ ;
    end
    $fwrite(`STDERR,"\n");
  endfunction
  //
endclass // Packet
///////////////////////////////////////////////////////////////////////////////
// Class Checker:
///////////////////////////////////////////////////////////////////////////////
class Checker;
  /////////////////////////////////////////////////////////////////////////////
  //************************ Class Variables ********************************//
  /////////////////////////////////////////////////////////////////////////////
  static int AllChecks     = 0;
  static int AllChecksFail = 0;
  local  int Checks        = 0;
  local  int ChecksFail    = 0;
  local Packet pkt;
  /////////////////////////////////////////////////////////////////////////////
  //************************* Class Methods *********************************//
  /////////////////////////////////////////////////////////////////////////////
  function new();
    pkt = new();
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- CheckPkt(): Compares 2 given packets and returns '0' if they are equal.
  // Otherwise returns '-1'.*/
  // added selection packet to take into account real selected bytes in the packet
  // added prvPkt : previous value read at the same address (in order to check selection efficiency)
  /////////////////////////////////////////////////////////////////////////////
  function int CheckPkt(packet initPkt, packet resPkt, expPkt, sel_packet selPkt, int addr, int data_bytes, int length = 0);
    sel_packet errPkt ;
    int dataError = 0;
    if(length == 0) begin
      length = expPkt.size();
    end
    this.Checks++;
    this.AllChecks++;
    if((expPkt.size()==0) || (initPkt.size()==0) || (initPkt.size() == 0)) begin
      $fwrite(`STDERR,"#-----Check %0d",this.Checks);
      $fwrite(`STDERR,"   Failed. Empty packet detected \n");
      $fwrite(`STDERR,"           Initial  read  packet length is %d \n", expPkt.size());
      $fwrite(`STDERR,"                    write packet length is %d \n", expPkt.size());
      $fwrite(`STDERR,"           Result   read  packet length is %d \n", resPkt.size());
      CheckPkt = -1;
      this.ChecksFail++;
      this.AllChecksFail++;
    end else begin
      for (int i = 0; i < length; i++) begin
        errPkt[i] = 0 ;
        if (((resPkt[i] != expPkt[i])  && selPkt[i]) ||   // Selected bytes of final read packet should be identical to written bytes
            ((resPkt[i] != initPkt[i]) && !selPkt[i])     // Unselected bytes of final read packet should be identical to unwritten bytes
         ) begin
          dataError++;
          errPkt[i] = 1 ;
        end
      end
      if (dataError == 0) begin
        //$fwrite(`STDERR,"   Passed!!! \n");
        CheckPkt = 0;
      end else begin
        $fwrite(`STDERR,"#-----Check %0d",this.Checks);
        $fwrite(`STDERR,"   Failed. Current Check has %0d errors\n", dataError);
        pkt.Print3Pkt("", initPkt, resPkt, expPkt, selPkt, errPkt, addr,data_bytes,1,1,length);
        CheckPkt = -1;
        this.ChecksFail++;
        this.AllChecksFail++;
      end
    end
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- printStatus(): Print checks and failed checks information.*/
  /////////////////////////////////////////////////////////////////////////////
  function void printStatus();
    $fwrite(`STDERR,"---Number of Checks        %0d \n", this.Checks);
    $fwrite(`STDERR,"---Number of failed Checks %0d \n", this.ChecksFail);
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- printFullStatus(): Print checks and failed checks information.*/
  /////////////////////////////////////////////////////////////////////////////
  function void printFullStatus();
    $fwrite(`STDERR,"---Number of Checks        %0d \n", this.AllChecks);
    $fwrite(`STDERR,"---Number of failed Checks %0d \n", this.AllChecksFail);
  endfunction
endclass // Checker
//
endpackage
