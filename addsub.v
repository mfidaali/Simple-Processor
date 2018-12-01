module addsub
(
	input [8:0] dataa,
	input [8:0] datab,
	input add_sub,	  // if this is 0, add; if 1, subtract
	input clk,
	output reg [8:0] result
);

	always @ (posedge clk)
	begin
		if (add_sub)
			result <= dataa - datab;
		else
			result <= dataa + datab;
	end

endmodule
