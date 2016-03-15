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

`timescale 1ns/1ns

import PACKET::*;
import WSHB_M::*;

program test #(type virtual_master_t);
  initial begin
    //
    packet dataIn,  expData, dataOut, dataOut0;
    sel_packet selIn ;
    sel_packet selIn0 ;
    int addr;
    int trErrors, trExpErrors;
    int itrNum;
    int chkResult ;
    int data_bytes ;
    time t0,t1,t2,t3 ;
    int maxAddr ;
    //
    WSHB_m_env #(virtual_master_t) wshb_m;
    automatic Packet pkt  = new();
    automatic Checker chk = new();
    itrNum = 10000;

    // Create WSHB master
    wshb_m    = new(testbench_top.wshb_if_0);
    // Get number of data bytes of the bus
    data_bytes = wshb_m.blockSize ;
    // Start master and slave vips
    wshb_m.startEnv();
    //
    wshb_m.setRndDelay(0, 100, 0, 10);
    wshb_m.setTimeOut(100, 3);
    trExpErrors = 0;

    // Max 2048 word address
    maxAddr = ((1<<11)-1) << $clog2(data_bytes) ;
    
    // Wait several clocks to be sure that DUT is ready
    repeat (10) @(posedge testbench_top.clk);
    
    $write("\n\n-Verification de la plage d'adressage de la RAM: \n") ;
    $write("  * boucle en ecriture sur les %5d  adresses RAM avec une donnees egale a l'adresse (sel = 1111).\n",(maxAddr+data_bytes)/data_bytes) ;
    $write("  * suivie d'une boucle  en lecture sur les %5d  adresses RAM.\n",(maxAddr+data_bytes)/data_bytes) ;
    // Verify that there is no address aliasing in the choosen space
    selIn  = { 1'b1, 1'b1 ,1'b1, 1'b1 } ;
    for(addr=0;addr <= maxAddr  ; addr=addr+data_bytes) begin
        dataIn = { addr[31:24], addr[23:16], addr[15:8], addr[7:0]} ; 
        wshb_m.writeData(addr,dataIn,selIn,without_burst_tags);
        wshb_m.busIdle(0);
    end
    for(addr=0;addr <= maxAddr  ; addr=addr+data_bytes) begin
        dataIn = { addr[31:24], addr[23:16], addr[15:8], addr[7:0]} ; 
        wshb_m.readData(addr,dataOut,selIn,dataIn.size(),without_burst_tags);
        wshb_m.busIdle(0);
        if(dataIn != dataOut) begin
           $display("Erreur  (Eventuellement écrasement en memoire)") ;
           $display("La donnee à l'adresse %h devrait  être %h, la valeur lue est %h%h%h%h",addr, addr , dataOut[0], dataOut[1], dataOut[2], dataOut[3]) ;
           $fatal() ;
        end
    end
    $write("-Fin de verification de la plage d'adressage de la RAM\n") ;
    $fflush(0) ;
    $fflush(1) ;


    // Master read/write in classic mode
    $display("\n\n-Demarrage de %5d sequences transferts paquets de donnees de taille aleatoire en utilisant  le mode \"wishbone classic\"",itrNum) ;
    $display("   * chaque paquet est transmit puis relu pour verification.") ;
    $display("   * chaque mot d'un paquet est tire aleatoirement avec des bits de selection aleatoires") ;
    t0 = $time ;
    for(int itr=1;itr <=itrNum;itr++) begin
     
      // Generate an aligned address (repeat 2 times the same address in order to test overwritten values)
      if(itr %2) addr = pkt.genRndNum(0, 100000,data_bytes);
      
      // Generate a packet of data to write aligned to the word size
      pkt.genAlignedRndPkt(pkt.genRndNum(1, 32,data_bytes), random_selection, data_bytes, dataIn, selIn);
     
      // Get current data at current address
      for(int i=0;i<selIn.size();i++) selIn0[i] = 1 ;
      wshb_m.readData(addr,dataOut0,selIn0,dataIn.size(),without_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      
      // Write a new packet 
      wshb_m.writeData(addr,dataIn,selIn,without_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      
      // Read the written data
      wshb_m.readData(addr,dataOut,selIn0,dataIn.size(),without_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));

      chkResult = chk.CheckPkt(dataOut0, dataOut, dataIn,selIn,addr,data_bytes);
      if(chkResult < 0) $fatal ;  
    end
    t1 = $time ;
    $display("-Fin de la sequence en mode \"wishbone classic\" ") ;
    // Master read/write in burst mode mode
    $display("\n\n-Demarrage de %5d sequences transferts paquets de donnees de taille aleatoire en utilisant  le mode \"registered feedback\"",itrNum) ;
    t2 = $time ;
    for(int itr=1;itr <=itrNum;itr++) begin
      // Generate an aligned address (repeat 2 times the same address in order to test overwriteent values)
      if(itr %2) addr = pkt.genRndNum(0, 100000,data_bytes);
      // Generate a packet of data aligned to the word size
      pkt.genAlignedRndPkt(pkt.genRndNum(1, 32, data_bytes), random_burst_selection, data_bytes, dataIn, selIn); // Force multiple of words
      //$display("address == %h", addr);
      //$display("Length  == %d", dataIn.size());
      // Get current data at current address
      wshb_m.readData(addr,dataOut0,selIn,dataIn.size(),with_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      // Write a new packet 
      wshb_m.writeData(addr,dataIn,selIn,with_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      // Read the written data
      wshb_m.readData(addr,dataOut,selIn,dataIn.size(),with_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      chkResult = chk.CheckPkt(dataOut0, dataOut, dataIn,selIn,addr,data_bytes);
      if(chkResult < 0)  $fatal ;
    end
    t3 = $time ;
    $display("-Fin de la sequence en mode \"registered feedback\" ") ;

    $display("\n\n-Temps total pour les sequences en mode \wishbone classic\" : %d",t1-t0) ;
    $display("-Temps total pour les sequences en mode \"registered feedback\"  : %d",t3-t2) ;
    //
    repeat (5) @testbench_top.wshb_if_0.tbm.cbm;
    //
        //trErrors = wshb_m.printStatus();
    //$display("-----------------------Test Done------------------------");
    //$display("------------------Printing Test Status------------------");
    //if (trErrors == trExpErrors) begin
    //  $display("-Transactions have 0 unexpected TimeOut or Slave Errors-");
    //end else begin
    //  $display("--Transactions have unexpected TimeOut or Slave Errors--");
    //  $display("Expected  error amount is %d", trExpErrors);
    //  $display("Generated error amount is %d", trErrors);
    //end
    //$display("--------------------------------------------------------");
    //chk.printFullStatus();
    //$display("--------------------------------------------------------");
    //
  end
endprogram
