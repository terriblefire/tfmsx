`timescale 1ns / 1ps

module test_vdp_io;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "bus_tasks.vinc"
`include "../unittest.vinc"

initial begin

    $dumpfile("test_vdp_io.vcd");
    $dumpvars(0, test_vdp_io);

    #100;
    wait(RESET);

    // VDP ports are at 0x98-0x9B
    // 0x98: VRAM data read/write
    // 0x99: VDP register write / status read
    // 0x9A: Palette data
    // 0x9B: Indirect register access

    // Test 1: Write to VDP data port (0x98)
    beginiow(8'h98, 8'hA5);
    `WAIT_CLKCPU_POSEDGE
    // VDPW should be active (low) for write
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);  // Read should be inactive
    endcycle();
    #100;

    // Test 2: Write to VDP register port (0x99)
    beginiow(8'h99, 8'h12);
    `WAIT_CLKCPU_POSEDGE
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);
    endcycle();
    #100;

    // Test 3: Read from VDP data port (0x98)
    beginior(8'h98);
    `WAIT_CLKCPU_POSEDGE
    // VDPR should be active (low) for read
    assert(1'b0, VDPR);
    assert(1'b1, VDPW);  // Write should be inactive
    endcycle();
    #100;

    // Test 4: Read from VDP status register (0x99)
    beginior(8'h99);
    `WAIT_CLKCPU_POSEDGE
    assert(1'b0, VDPR);
    assert(1'b1, VDPW);
    endcycle();
    #100;

    // Test 5: Write to palette register (0x9A)
    beginiow(8'h9A, 8'h77);
    `WAIT_CLKCPU_POSEDGE
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);
    endcycle();
    #100;

    // Test 6: Write to indirect register (0x9B)
    beginiow(8'h9B, 8'h88);
    `WAIT_CLKCPU_POSEDGE
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);
    endcycle();
    #100;

    // Test 7: Inactive state - no I/O access
    #100;
    assert(1'b1, VDPW);  // Both should be inactive (high)
    assert(1'b1, VDPR);
    #100;

    // Test 8: Sequential VDP writes
    beginiow(8'h98, 8'h00);
    endcycle();
    #50;
    beginiow(8'h98, 8'h01);
    endcycle();
    #50;
    beginiow(8'h98, 8'h02);
    endcycle();
    #100;

    // Test 9: Sequential VDP reads
    beginior(8'h98);
    endcycle();
    #50;
    beginior(8'h98);
    endcycle();
    #50;
    beginior(8'h98);
    endcycle();
    #100;

    $display("All VDP I/O tests passed!");
    $finish();

end

endmodule
