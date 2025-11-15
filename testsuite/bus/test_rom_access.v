`timescale 1ns / 1ps

module test_rom_access;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "bus_tasks.vinc"
`include "../unittest.vinc"

// ROM simulation - 256KB (bank selected via ROMA[18:14])
reg [7:0] rom [0:262143];

// Drive CPU data bus when ROM is being read
// ROM is active when ROMOE is low
wire [7:0] rom_dout = (!ROMOE) ? rom[{ROMA, CPU_A[13:0]}] : 8'hzz;
assign CPU_D = (!ROMOE && !CPU_RD && !CPU_MREQ) ? rom_dout : 8'hzz;

integer i;

initial begin

    $dumpfile("test_rom_access.vcd");
    $dumpvars(0, test_rom_access);

    // Initialize ROM with test pattern
    // Bank 0: 0xA0, Bank 1: 0xA1, etc.
    for (i = 0; i < 262144; i = i + 1) begin
        rom[i] = 8'hA0 + i[18:14];  // Pattern based on bank number
    end

    // Add specific test values
    rom[20'h00000] = 8'hF0;  // Bank 0, address 0x0000
    rom[20'h00100] = 8'hF1;  // Bank 0, address 0x0100
    rom[20'h04000] = 8'hE0;  // Bank 1, address 0x0000
    rom[20'h08000] = 8'hD0;  // Bank 2, address 0x0000

    #100;
    wait(RESET);

    // Test 1: Read from ROM at address 0x0000 (should be in slot 0, bank 0)
    beginmemr(16'h0000);
    #10;
    // ROM output enable should be active (low)
    assert(1'b0, ROMOE);
    // Check we get the right data
    assert(8'hF0, CPU_D);
    endcycle();
    #100;

    // Test 2: Read from ROM at address 0x0100
    beginmemr(16'h0100);
    #10;
    assert(1'b0, ROMOE);
    assert(8'hF1, CPU_D);
    endcycle();
    #100;

    // Test 3: Sequential ROM reads
    beginmemr(16'h0000);
    #10;
    assert(1'b0, ROMOE);
    endcycle();
    #50;

    beginmemr(16'h0001);
    #10;
    assert(1'b0, ROMOE);
    endcycle();
    #50;

    beginmemr(16'h0002);
    #10;
    assert(1'b0, ROMOE);
    endcycle();
    #100;

    // Test 4: ROM address bits
    // Reading from different addresses should change ROMA appropriately
    beginmemr(16'h3FFF);  // Top of first 16K page
    #10;
    assert(1'b0, ROMOE);
    endcycle();
    #100;

    $display("All ROM access tests passed!");
    $finish();

end

endmodule
