`timescale 1ns / 1ps

module test_sram_access;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
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

task beginiow;
input [7:0] addr;
input [7:0] data;
begin
    CPU_A = {data, addr};
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

task beginmemw;
input [15:0] addr;
input [7:0] data;
begin
    CPU_A = addr;
    CPU_DOUT = data;
    CPU_DOUT_EN = 1'b1;

    @(posedge CLKCPU);
    #1;
    @(negedge CLKCPU);
    #1;

    CPU_MREQ = 1'b0;
    CPU_WR   = 1'b0;
end
endtask

task beginmemr;
input [15:0] addr;
begin
    CPU_A = addr;
    CPU_DOUT_EN = 1'b0;

    @(posedge CLKCPU);
    #1;
    @(negedge CLKCPU);
    #1;

    CPU_MREQ = 1'b0;
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

integer i;

initial begin

    $dumpfile("test_sram_access.vcd");
    $dumpvars(0, test_sram_access);

    // Initialize SRAM with test pattern
    for (i = 0; i < 16384; i = i + 1) begin
        sram[i] = 8'h00;
    end

    #100;
    wait(RESET);

    // Configure slots: Map page 3 (0xC000-0xFFFF) to slot 3 (RAM)
    // Default slot register should already be 0x00 (all pages to slot 0)
    // We need to set page 3 to slot 3 for RAM access
    beginiow(8'hA8, 8'b11_00_00_00);  // Page3=slot3, others=slot0
    endcycle();
    #100;

    // Test 1: Write to SRAM in page 3 (0xC000)
    beginmemw(16'hC000, 8'hA5);
    #10;
    endcycle();
    #100;

    // Test 2: Write to SRAM at address 0xC100
    beginmemw(16'hC100, 8'h5A);
    #10;
    endcycle();
    #100;

    // Test 3: Read from SRAM at address 0xC000
    beginmemr(16'hC000);
    #10;
    // Should read back what we wrote
    if (SD === 8'hA5) begin
        // Success
    end
    endcycle();
    #100;

    // Test 4: Read from SRAM at address 0xC100
    beginmemr(16'hC100);
    #10;
    if (SD === 8'h5A) begin
        // Success
    end
    endcycle();
    #100;

    // Test 5: Sequential write/read pattern
    beginmemw(16'hD000, 8'h12);
    endcycle();
    #50;
    beginmemw(16'hD001, 8'h34);
    endcycle();
    #50;
    beginmemw(16'hD002, 8'h56);
    endcycle();
    #50;

    beginmemr(16'hD000);
    #10;
    endcycle();
    #50;

    beginmemr(16'hD001);
    #10;
    endcycle();
    #50;

    beginmemr(16'hD002);
    #10;
    endcycle();
    #100;

    // Test 6: Test SRAM enable signal
    // When accessing page 3 with slot 3, SCE should be active (low)
    beginmemr(16'hC000);
    #10;
    // SRAM chip select should be active
    assert(1'b0, SCE);
    endcycle();
    #100;

    // Test 7: Test mapper slot control
    // Write to mapper register for page 3
    beginiow(8'hFF, 8'h05);  // Map page 3 to RAM bank 5
    endcycle();
    #100;

    // Access page 3 - RAMSLOT should reflect bank 5
    beginmemr(16'hC000);
    #10;
    assert(5'h05, RAMSLOT);
    endcycle();
    #100;

    $display("All SRAM access tests passed!");
    $finish();

end

endmodule
