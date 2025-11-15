`timescale 1ns / 1ps

module test_psg_io;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "bus_tasks.vinc"
`include "../unittest.vinc" 
 

initial begin

    // test address selection

	$dumpfile("test_psg_io.vcd");
    $dumpvars(0, test_psg_io);
   
    #500;
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
