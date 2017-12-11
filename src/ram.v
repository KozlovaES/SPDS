// Quartus II Verilog Template
// True Dual Port RAM with single clock

module ram
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=4)
(
	input [(DATA_WIDTH-1):0] data_a, data_b,
	input [(ADDR_WIDTH-1):0] addr_a, addr_b,
	input we_a, we_b, clk,
	output reg [(DATA_WIDTH-1):0] q_a, q_b
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	initial begin
        $readmemh ("data.hex", ram);
    end

	// Asynchronous reading
	always @ (*)
	begin
		q_a <= ram[addr_a];
		q_b <= ram[addr_b];
	end 
	
	// Synchronized writing
	always @ (posedge clk)
	begin
		if (we_a) 
		begin
			ram[addr_a] <= data_a;
		end
		if (we_b) 
		begin
			ram[addr_b] <= data_b;
		end
	end 

endmodule
