`timescale 1ns / 1ps

module test_vdp_io;

`include "../clocks.vinc"
`include "bus_fixture.vinc"
`include "../unittest.vinc"

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

task beginior;
input [7:0] addr;
begin
    CPU_A = {addr, addr};
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
    @(posedge CLKCPU);
    #1;
    // VDPW should be active (low) for write
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);  // Read should be inactive
    endcycle();
    #100;

    // Test 2: Write to VDP register port (0x99)
    beginiow(8'h99, 8'h12);
    @(posedge CLKCPU);
    #1;
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);
    endcycle();
    #100;

    // Test 3: Read from VDP data port (0x98)
    beginior(8'h98);
    @(posedge CLKCPU);
    #1;
    // VDPR should be active (low) for read
    assert(1'b0, VDPR);
    assert(1'b1, VDPW);  // Write should be inactive
    endcycle();
    #100;

    // Test 4: Read from VDP status register (0x99)
    beginior(8'h99);
    @(posedge CLKCPU);
    #1;
    assert(1'b0, VDPR);
    assert(1'b1, VDPW);
    endcycle();
    #100;

    // Test 5: Write to palette register (0x9A)
    beginiow(8'h9A, 8'h77);
    @(posedge CLKCPU);
    #1;
    assert(1'b0, VDPW);
    assert(1'b1, VDPR);
    endcycle();
    #100;

    // Test 6: Write to indirect register (0x9B)
    beginiow(8'h9B, 8'h88);
    @(posedge CLKCPU);
    #1;
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
