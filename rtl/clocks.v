
/*	clocks.v

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

module clocks (
    input   CLK28M,
    output  reg RESET = 0,  
    output  CLKCPU, 
    output  PSGCLK, 
    output  SLOTCLK
);

localparam RESET_WIDTH = 15;    
reg [RESET_WIDTH-1:0] reset_count = 0;
    
reg clk14m = 0;
reg clk7m = 0;
reg clk3_5m = 0;
reg clk1_8m = 0;
reg clk0_9m = 0;

initial begin 

	RESET = 'd0;

end


always @(posedge CLK28M) begin
    clk14m <= ~clk14m;    
end

always @(posedge clk14m) begin
    clk7m <= ~clk7m;    
end

always @(posedge clk7m) begin
    clk3_5m <= ~clk3_5m;    
end

always @(posedge clk3_5m) begin 

    clk1_8m <= ~clk1_8m;

end

always @(posedge clk1_8m) begin 

    clk0_9m <= ~clk0_9m;

end

always @(posedge clk0_9m) begin 

	reset_count <= reset_count + 'd1;

    if (reset_count[RESET_WIDTH-1] == 1'b1) begin 
        RESET <= 1'b1;
    end

end 

assign SLOTCLK  = clk3_5m;
assign CLKCPU   = clk3_5m;
assign PSGCLK   = clk3_5m;

endmodule