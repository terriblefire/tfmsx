`timescale 1ns / 1ps

module test_rom_access;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "bus_tasks.vinc"
`include "../unittest.vinc"

// ROM simulation - 16KB (enough for testing)
reg [7:0] rom [0:16383];

// Drive CPU data bus when ROM is being read
// ROM is active when ROMOE is low
wire [7:0] rom_dout = (!ROMOE) ? rom[CPU_A[13:0]] : 8'hzz;
assign CPU_D = (!ROMOE && !CPU_RD && !CPU_MREQ) ? rom_dout : 8'hzz;

initial begin

    $dumpfile("test_rom_access.vcd");
    $dumpvars(0, test_rom_access);

    // Initialize only the test values we need (no loop for speed)
    rom[16'h0000] = 8'hF0;
    rom[16'h0001] = 8'hAA;
    rom[16'h0002] = 8'hBB;
    rom[16'h0100] = 8'hF1;
    rom[16'h3FFF] = 8'hCC;

    #200;
    wait(RESET);

    // Test 1: Read from ROM at address 0x0000 (should be in slot 0, bank 0)
    beginmemr(16'h0000);
    #500;
    // ROM output enable should be active (low)
    assert(1'b0, ROMOE);
    // Check we get the right data
    assert(8'hF0, CPU_D);
    endcycle();
    #500;

    // Test 2: Read from ROM at address 0x0100
    beginmemr(16'h0100);
    #500;
    assert(1'b0, ROMOE);
    assert(8'hF1, CPU_D);
    endcycle();
    #500;

    // Test 3: Sequential ROM reads
    beginmemr(16'h0000);
    #500;
    assert(1'b0, ROMOE);
    endcycle();
    #500;

    beginmemr(16'h0001);
    #500;
    assert(1'b0, ROMOE);
    endcycle();
    #500;

    beginmemr(16'h0002);
    #500;
    assert(1'b0, ROMOE);
    endcycle();
    #500;

    // Test 4: ROM address bits
    // Reading from different addresses should change ROMA appropriately
    beginmemr(16'h3FFF);  // Top of first 16K page
    #500;
    assert(1'b0, ROMOE);
    endcycle();
    #500;

    $display("All ROM access tests passed!");
    $finish();

end

endmodule
