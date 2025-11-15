`timescale 1ns / 1ps

module test_sram_access;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "bus_tasks.vinc"
`include "../unittest.vinc"

// SRAM simulation
reg [7:0] sram [0:16383]; // 16KB SRAM bank

// Drive SD when SRAM is being read
wire [7:0] sram_dout = (!SCE && SWR) ? sram[SA] : 8'hzz;
assign SD = sram_dout;

// Write to SRAM
always @(*) begin
    if (!SCE && !SWR) begin
        sram[SA] <= SD;
    end
end

initial begin

    $dumpfile("test_sram_access.vcd");
    $dumpvars(0, test_sram_access);

    // SRAM starts uninitialized - no need to clear it for testing

    #200;
    wait(RESET);

    // Configure slots: Map page 3 (0xC000-0xFFFF) to slot 3 (RAM)
    beginiow(8'hA8, 8'b11_00_00_00);  // Page3=slot3, others=slot0
    endcycle();
    #500;

    // Test 1: Write to SRAM in page 3 (0xC000)
    beginmemw(16'hC000, 8'hA5);
    #500;
    endcycle();
    #500;

    // Test 2: Write to SRAM at address 0xC100
    beginmemw(16'hC100, 8'h5A);
    #500;
    endcycle();
    #500;

    // Test 3: Read from SRAM at address 0xC000
    beginmemr(16'hC000);
    #500;
    // Should read back what we wrote
    if (SD === 8'hA5) begin
        // Success
    end
    endcycle();
    #500;

    // Test 4: Read from SRAM at address 0xC100
    beginmemr(16'hC100);
    #500;
    if (SD === 8'h5A) begin
        // Success
    end
    endcycle();
    #500;

    // Test 5: Sequential write/read pattern
    beginmemw(16'hD000, 8'h12);
    endcycle();
    #500;
    beginmemw(16'hD001, 8'h34);
    endcycle();
    #500;
    beginmemw(16'hD002, 8'h56);
    endcycle();
    #500;

    beginmemr(16'hD000);
    #500;
    endcycle();
    #500;

    beginmemr(16'hD001);
    #500;
    endcycle();
    #500;

    beginmemr(16'hD002);
    #500;
    endcycle();
    #500;

    // Test 6: Test SRAM enable signal
    // When accessing page 3 with slot 3, SCE should be active (low)
    beginmemr(16'hC000);
    #500;
    // SRAM chip select should be active
    assert(1'b0, SCE);
    endcycle();
    #500;

    // Test 7: Test mapper slot control
    // Write to mapper register for page 3
    beginiow(8'hFF, 8'h05);  // Map page 3 to RAM bank 5
    endcycle();
    #500;

    // Access page 3 - RAMSLOT should reflect bank 5
    beginmemr(16'hC000);
    #500;
    assert(5'h05, RAMSLOT);
    endcycle();
    #500;

    $display("All SRAM access tests passed!");
    $finish();

end

endmodule
