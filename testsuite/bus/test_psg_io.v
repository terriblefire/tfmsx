`timescale 1ns / 1ps

module test_psg_io;

`include "../clocks.vinc"
`include "bus_fixture.vinc"   
`include "../unittest.vinc"

task beginiow; 
input [7:0] addr;
input [7:0] data; 
begin 
    CPU_A = {data,addr};
    CPU_DOUT = data;
    CPU_DOUT_EN = 1'b1;

    @(posedge CLKCPU);
    #1; 
    @(negedge CLKCPU);
    #1;

    CPU_IORQ = 1'b0;
    CPU_WR   = 1'b0;
end
endtask

task beginior; 
input [7:0] addr;
begin 
    CPU_A = {addr,addr};
    CPU_DOUT_EN = 1'b0;

    @(posedge CLKCPU);
    #1; 
    @(negedge CLKCPU);
    #1;

    CPU_IORQ = 1'b0;
    CPU_RD   = 1'b0;
end
endtask


task endcycle; 
begin 
    @(posedge CLKCPU);
    #1; 
    @(negedge CLKCPU);
    #1;
    CPU_DOUT_EN = 1'b0;
    CPU_IORQ = 1'b1;
    CPU_MREQ = 1'b1;
    CPU_RFSH = 1'b1;
    CPU_RD   = 1'b1;
    CPU_WR   = 1'b1;
    #1;
end 
endtask 
 

initial begin

    // test address selection

	$dumpfile("test_psg_io.vcd");
    $dumpvars(0, test_psg_io);
   
    #100;
    wait(RESET);

    // inactive 
    assertexactly(3'b010, {YMBDIR, YMBC});

    beginiow(8'hA0, 8'h0F );
    #1; 
    // address write 
    assertexactly(3'b111, {YMBDIR, YMBC});
    
    endcycle();

    #1000;

    beginiow( 8'hA1, 8'h03 );
    #1;

    // data write 
    assertexactly(3'b110, {YMBDIR, YMBC});

    endcycle();

    #1000;

    beginior(8'hA2);
    #1;

    // data read 
    assertexactly(3'b011, {YMBDIR, YMBC});
    
    endcycle();

    #1000;

    $finish();

end 

endmodule
