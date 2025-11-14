/*	TFMSX_top.v

	Copyright (c) 2021, Stephen J. Leary
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
		 * Redistributions of source code must retain the above copyright
			notice, this list of conditions and the following disclaimer.
		 * Redistributions in binary form must reproduce the above copyright
			notice, this list of conditions and the following disclaimer in the
			documentation and/or other materials provided with the distribution.
		 * Neither the name of the Stephen J. Leary nor the
			names of its contributors may be used to endorse or promote products
			derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL STEPHEN J. LEARY BE LIABLE FOR ANY
	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

module tfmsx_top(

    // clocks
    input   CLK28M, 
    output  RESET,
    output  CLKCPU, // CPU Clock is 1/8th master clock.

    // z80 bus interface
    inout   [7:0] D,
    //output        D_en,  
    input   [15:0] A,

    input   RD, 
    input   WR, 
    output  INT, 
    output  NMI, 
    input   HALT,
    output  WAIT,  
    input   MREQ, 
    input   IORQ, 
    input   M1, 
    input   RFSH,

    output  BUSRQ, 
    input   BUSAK, 

    // sram interface 
    output  SCE,
    output  [13:0] SA, 
    output  reg [4:0]  RAMSLOT, // 32 16K Pages
    inout   [7:0]  SD,
    output  SWR, // missing on rev 0

    // rom interface 

    output  [18:14] ROMA, 
    output  ROMOE, 
    //output  ROMCE, // defunc on r2
    
    // psg interface
    output  PSGCLK,  // PSG Clock is always held at 1/16th master clock.  
    //output  [9:8] YMA,
    output  [2:1] YMBC,
    output  YMBDIR,
    output  YMSEL,

    // slot control 
    output  SLOTCLK, // CLKSLOT is 1/8th Master clock 
    input   BDIR, 
    input   SLOT_INT,

    output  EXCS1,
    output  EXCS2,
    output  EXCS12,
    output  EXSLTSL1,
    output  EXSLTSL2,

    // vdp control 
    output reg VDPR = 1'b1,
    output reg VDPW = 1'b1,
    input   VDP_INT,
	input 	VDP_SEL, 
	output 	VRESET, // only on r2

    // experimental 
    output  reg    ARMINT,
    input   [7:0]  PORTB,
    output  [3:0]  PORTC,
	output         PPI_SND, 

	// ROM select 
	input	[1:0]  ROMSEL,

    input   [31:0]  INTSIG
);

wire io_access = IORQ;
wire io_read = IORQ | RD;
wire io_write = IORQ | WR;

localparam RTC_ADDRESS = 0;
localparam RTC_DATA = 0;

wire rtc_addr_write = (A[7:0] != {8'hB4}) | io_access | WR;

wire rtc_decode = (A[7:0] != {8'hB5}) | io_access;
wire rtc_data_read = rtc_decode | RD;

wire i8253_decode   = (A[7:2] != {4'h8, 2'b00}) | io_access;
wire psg_decode     = (A[7:2] != {4'hA, 2'b00}) | io_access;
wire vdp_decode     = (A[7:2] != {4'h9, 2'b10}) | io_access;
wire ssr_decode     = (A[15:0] != 16'hFFFF) | MREQ | ~M1; 
wire mapper_write   = (A[7:2] != {4'hF,2'b11}) | io_access | WR;
wire mapper_read    = (A[7:2] != {4'hF,2'b11}) | io_access | RD;

wire ppi_decode = (A[7:2] != {4'hA, 2'b10}) | io_access;
wire ppi_write = ppi_decode | WR;
wire ppi_read = ppi_decode | RD;

localparam PPI_PORTA = 2'b00;
localparam PPI_PORTB = 2'b01;
localparam PPI_PORTC = 2'b10;
localparam PPI_MODE  = 2'b11;

reg [7:0] slot_register = 8'h00;
reg [7:0] portc = 'd0;
reg [7:0] ssr = 'd0;

wire page0_n = A[15:14] != 2'b00; // 0x0000 to 0x3FFF
wire page1_n = A[15:14] != 2'b01; // 0x4000 to 0x7FFF
wire page2_n = A[15:14] != 2'b10; // 0x8000 to 0xBFFF
wire page3_n = A[15:14] != 2'b11; // 0xC000 to 0xFFFF

wire [1:0] current_slot = !page0_n ? slot_register[1:0] :
                          !page1_n ? slot_register[3:2] :
                          !page2_n ? slot_register[5:4] : 
                                     slot_register[7:6];

// signals for active slots
wire slot0_n = current_slot != 2'b00;
wire slot1_n = current_slot != 2'b01;
wire slot2_n = current_slot != 2'b10;
wire slot3_n = current_slot != 2'b11;

// mapper slots
reg [4:0] mapper_slot_register0 = 3;
reg [4:0] mapper_slot_register1 = 2;
reg [4:0] mapper_slot_register2 = 1;
reg [4:0] mapper_slot_register3 = 0;

wire [4:0] mapper_slot = !page0_n ? mapper_slot_register0 : 
                         !page1_n ? mapper_slot_register1 : 
                         !page2_n ? mapper_slot_register2 : 
                                    mapper_slot_register3; 

clocks CLOCKS ( 

    .CLK28M ( CLK28M    ),
    .RESET  ( RESET     ),

    .CLKCPU ( CLKCPU    ),
    .PSGCLK ( PSGCLK    ),
    .SLOTCLK( SLOTCLK   )

);

wire [3:0] rtc_dout;
reg [3:0] rtc_addr_latch = 0;

rp5c01a RTC (  

	.CLK 	( CLKCPU	),
	.CS		( rtc_decode),
	.RD		( RD 		),
	.WR 	( WR 		),
	.A 		( rtc_addr_latch ),
	.DIN 	( D			),
	.DOUT	( rtc_dout 	)

);

wire ssr_write = ssr_decode | WR | slot3_n;
wire ssr_read =  ssr_decode | RD | slot3_n;

wire [1:0] current_ssr  = !page0_n ? ssr[1:0] :
                          !page1_n ? ssr[3:2] :
                          !page2_n ? ssr[5:4] : 
                                     ssr[7:6];


reg register_out_en = 1'b1;
reg [7:0] register_out = 'd0;

reg sram_read_latch_en = 1'b1;
reg [7:0] sram_read_latch = 'd0;

reg sram_write_latch_en = 1'b1;
reg [7:0] sram_write_latch = 'd0;

wire ram_map1 = ({ssr[1:0]} != 2'b10) | page0_n;
wire ram_map2 = ({ssr[3:2]} != 2'b10) | page1_n;
wire ram_map3 = ({ssr[5:4]} != 2'b10) | page2_n;
wire ram_map4 = ({ssr[7:6]} != 2'b10) | page3_n;

wire sram_enable = slot3_n | MREQ | ~register_out_en | (ram_map1 & ram_map2 & ram_map3 & ram_map4) | ~ssr_decode;

wire main_rom_decode = page0_n & page1_n | slot0_n;
wire sub_rom_decode = (page0_n |  {ssr[1:0]} != 2'b11) | slot3_n;
wire slot_rom_decode = 1'b1; //EXSLTSL2 | EXCS1;

wire i8253_read  = i8253_decode | RD;
wire i8253_write = i8253_decode | WR;

reg [7:0] D_d; 
reg [7:0] SD_d;

reg  m1_wait;
reg  m1_wait_d;

// standard MSX wait circuit. 
always @(posedge CLKCPU or negedge m1_wait_d) begin 

    if (m1_wait_d == 1'b0) begin 
        m1_wait <= 1'bZ;
    end else begin 
        m1_wait <= M1;
    end 

end 


always @(posedge CLKCPU) begin

    register_out_en <= 1'b1;

    m1_wait_d <= m1_wait;
    ARMINT <= 1'b1;

	if (rtc_addr_write == 1'b0) begin 

		rtc_addr_latch <= D[3:0];
	
	end

	if (rtc_data_read == 1'b0) begin 
	
		register_out_en <= 1'b0;
		register_out <= {4'hF, rtc_dout};
	
	end

    if (ppi_write == 1'b0)  begin 
        
        case (A[1:0])

            PPI_PORTA: slot_register <= D;
            PPI_PORTC: begin 
                portc <= D;
                ARMINT <= 1'b0;
            end
            
        endcase

    end

    if (ssr_read == 1'b0) begin 
        register_out_en <= 1'b0;
        register_out <= ~ssr;
    end 

    if (ssr_write == 1'b0) begin 
        ssr <= D;
    end 
    
    if (mapper_write == 1'b0) begin 
        case (A[1:0])
            2'b00: mapper_slot_register0 <= D[4:0];
            2'b01: mapper_slot_register1 <= D[4:0];
            2'b10: mapper_slot_register2 <= D[4:0];
            2'b11: mapper_slot_register3 <= D[4:0];
        endcase
    end

    if (mapper_read == 1'b0) begin 
        register_out_en <= 1'b0;
        case (A[1:0]) 
            2'b00: register_out <= mapper_slot_register0;
            2'b01: register_out <= mapper_slot_register1;
            2'b10: register_out <= mapper_slot_register2;
            2'b11: register_out <= mapper_slot_register3;
        endcase
    end 

    if (ppi_read == 1'b0) begin 
        
        register_out_en <= 1'b0;

        case (A[1:0])
            // read by the PPI registers 
            PPI_PORTA: register_out <= slot_register;
            PPI_PORTB: register_out <= PORTB;
            PPI_PORTC: register_out <= portc;
            default: register_out <= 'h00;
            
        endcase
    
    end 

	if (i8253_read == 1'b0) begin 
		register_out_en <= 1'b0;
		register_out <= 'hFF;
	end 

    sram_read_latch_en <=  sram_enable | RD;
    sram_write_latch_en <= sram_enable | WR;
	
end


always @(posedge CLK28M) begin

	D_d <= D;
	SD_d <= SD;
   	 // vdp strobes
    VDPR <= vdp_decode | RD;
    VDPW <= vdp_decode | WR;
	
	RAMSLOT <= mapper_slot;
end


assign D =  register_out_en ? 8'bzzzz_zzzz : register_out;
assign D =  sram_read_latch_en ? 8'bzzzz_zzzz : SD_d;

//assign D_en = register_out_en & sram_read_latch_en;

// ram constants
assign SD = sram_write_latch_en ? 8'bzzzz_zzzz : D_d;
assign SCE = 1'b0;

assign INT = VDP_INT;
assign WAIT = m1_wait ? 1'bz : 1'b0;
assign BUSRQ = 1'b1;
assign NMI = 1'b1;

assign ROMA = {3'b000, ~sub_rom_decode, A[14]};

assign SA = A[13:0];
assign SWR = sram_write_latch_en;
assign ROMOE = MREQ | RD | (main_rom_decode & sub_rom_decode);

assign YMBC[2:1] = {1'b1, ~(psg_decode | A[0])};
assign YMBDIR = ~WR & ~psg_decode;
assign YMSEL = 1'b0;

assign EXSLTSL1 = slot1_n | MREQ;
assign EXSLTSL2 = slot2_n | MREQ;
assign EXCS1 = page1_n | MREQ;
assign EXCS2 = page2_n | MREQ;
assign EXCS12 =  (page1_n & page2_n) | MREQ;
assign VRESET = VDP_SEL ? 1'bz : 1'b1; 

assign PORTC = portc[3:0];
assign PPI_SND = portc[7];  

endmodule
