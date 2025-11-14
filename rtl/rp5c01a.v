
/*	rp5c01a.v

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

module rp5c01a (

	input 		CLK, 
	input 		CS, 
	input 		RD, 
	input  		WR, 
	input [3:0] A,
	input [7:0] DIN,
	output reg [3:0] DOUT

);

reg dummy;
reg [1:0] mode;
reg [3:0] test;

reg [3:0] bank2[0:12];


reg wr_d;
wire writing = CS | WR | ~wr_d;
wire reading = CS | RD; 

always @(posedge CLK) begin 

	wr_d <= WR;

	if (writing == 1'b0) begin 

		case (A)
			'hF: dummy <= DIN[0];
			'hE: test <= DIN[3:0]; 
			'hD: mode <= DIN[1:0];
			default: begin 
				if (mode == 'b10) bank2[A] <= DIN[3:0];
			end 
		endcase
	end  

	if (reading) begin 
	
		case (A)
			'hF: DOUT <= test;
			'hE: DOUT <= test;
			'hD: DOUT <= {2'b00, mode};
			default: begin 
				if (mode == 'b10) DOUT <= bank2[A];
				else DOUT <= 'd0;
			end 
		endcase 

	end 

end 

endmodule