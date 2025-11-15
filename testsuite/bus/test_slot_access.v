`timescale 1ns / 1ps

module test_slot_access;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "bus_tasks.vinc"
`include "../unittest.vinc"

initial begin

    $dumpfile("test_slot_access.vcd");
    $dumpvars(0, test_slot_access);

    #500;
    wait(RESET);

    // MSX Slot System:
    // - Port 0xA8 (PPI Port A) controls slot selection
    // - 4 pages of memory: 0x0000-0x3FFF, 0x4000-0x7FFF, 0x8000-0xBFFF, 0xC000-0xFFFF
    // - Each page can be mapped to one of 4 slots (slot 0-3)
    // - Slot register format: [Page3 slot][Page2 slot][Page1 slot][Page0 slot]
    //   Each field is 2 bits: 00=slot0, 01=slot1, 10=slot2, 11=slot3

    // Test 1: Initialize slot register - all pages to slot 0
    beginiow(8'hA8, 8'b00_00_00_00);  // All pages to slot 0
    endcycle();
    #500;

    // Test 2: Map Page 0 (0x0000-0x3FFF) to slot 1
    beginiow(8'hA8, 8'b00_00_00_01);  // Page0=slot1, others=slot0
    endcycle();
    #500;

    // Access memory in page 0 - should use slot 1
    beginmemr(16'h0000);
    #500;
    // Check that EXSLTSL1 is active for slot 1
    assert(1'b0, EXSLTSL1);  // Active low
    endcycle();
    #500;

    // Test 3: Map Page 1 (0x4000-0x7FFF) to slot 2
    beginiow(8'hA8, 8'b00_00_10_01);  // Page0=slot1, Page1=slot2, others=slot0
    endcycle();
    #500;

    // Access memory in page 1 - should use slot 2
    beginmemr(16'h4000);
    #500;
    assert(1'b0, EXSLTSL2);  // Active low
    endcycle();
    #500;

    // Test 4: Map all pages to different slots
    beginiow(8'hA8, 8'b11_10_01_00);  // Page0=slot0, Page1=slot1, Page2=slot2, Page3=slot3
    endcycle();
    #500;

    // Access Page 0 (slot 0)
    beginmemr(16'h0000);
    #500;
    // Slot 0 is typically ROM
    endcycle();
    #500;

    // Access Page 1 (slot 1) - should activate EXSLTSL1
    beginmemr(16'h4000);
    #500;
    assert(1'b0, EXSLTSL1);
    endcycle();
    #500;

    // Access Page 2 (slot 2) - should activate EXSLTSL2
    beginmemr(16'h8000);
    #500;
    assert(1'b0, EXSLTSL2);
    endcycle();
    #500;

    // Access Page 3 (slot 3) - RAM
    beginmemr(16'hC000);
    #500;
    // Slot 3 is typically RAM
    endcycle();
    #500;

    // Test 5: Page boundary crossing
    // Set page 0 to slot 1, page 1 to slot 2
    beginiow(8'hA8, 8'b00_00_10_01);
    endcycle();
    #500;

    // Access last address of page 0
    beginmemr(16'h3FFF);
    #500;
    assert(1'b0, EXSLTSL1);
    endcycle();
    #500;

    // Access first address of page 1
    beginmemr(16'h4000);
    #500;
    assert(1'b0, EXSLTSL2);
    endcycle();
    #500;

    // Test 6: Read back slot register
    beginior(8'hA8);
    #500;
    // Should read back the slot configuration
    assert(8'b00_00_10_01, CPU_D);
    endcycle();
    #500;

    // Test 7: Mapper slot registers (0xFC-0xFF)
    // These control which 16KB RAM page is mapped to each memory page

    // Write to mapper slot 0 (controls page 0 RAM mapping)
    beginiow(8'hFC, 8'h05);  // Map page 0 to RAM page 5
    endcycle();
    #500;

    // Write to mapper slot 1 (controls page 1 RAM mapping)
    beginiow(8'hFD, 8'h0A);  // Map page 1 to RAM page 10
    endcycle();
    #500;

    // Write to mapper slot 2 (controls page 2 RAM mapping)
    beginiow(8'hFE, 8'h0F);  // Map page 2 to RAM page 15
    endcycle();
    #500;

    // Write to mapper slot 3 (controls page 3 RAM mapping)
    beginiow(8'hFF, 8'h1F);  // Map page 3 to RAM page 31
    endcycle();
    #500;

    // Read back mapper slot 0
    beginior(8'hFC);
    #500;
    assert(8'h05, CPU_D);
    endcycle();
    #500;

    // Read back mapper slot 1
    beginior(8'hFD);
    #500;
    assert(8'h0A, CPU_D);
    endcycle();
    #500;

    // Test 8: RAMSLOT output reflects current page mapping
    // When accessing different memory pages, RAMSLOT should change

    // Access page 0 - RAMSLOT should be mapper_slot_register0 (0x05)
    beginmemr(16'h0000);
    #500;
    assert(5'h05, RAMSLOT);
    endcycle();
    #500;

    // Access page 1 - RAMSLOT should be mapper_slot_register1 (0x0A)
    beginmemr(16'h4000);
    #500;
    assert(5'h0A, RAMSLOT);
    endcycle();
    #500;

    // Access page 2 - RAMSLOT should be mapper_slot_register2 (0x0F)
    beginmemr(16'h8000);
    #500;
    assert(5'h0F, RAMSLOT);
    endcycle();
    #500;

    // Access page 3 - RAMSLOT should be mapper_slot_register3 (0x1F)
    beginmemr(16'hC000);
    #500;
    assert(5'h1F, RAMSLOT);
    endcycle();
    #500;

    $display("All slot access tests passed!");
    $finish();

end

endmodule
