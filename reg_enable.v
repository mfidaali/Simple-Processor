module reg_enable(D, Enable, Clock, Q);

parameter n = 9;

input [n-1:0] D;
input Enable;
input Clock;
output [n-1:0] Q;

reg [n-1:0] Q;

always @(posedge Clock)
begin
	if (Enable)
		Q <= D;
end
	
endmodule