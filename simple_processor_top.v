module simple_processor_top (

	input [9:0] SW,
	input [1:0] KEY,
	output [9:0] LEDR 
	
);

wire Resetn;
wire PClock;
wire MClock;
wire Run;
wire [8:0] DIN2proc;

wire [8:0] BusWires;
wire Done;


reg [4:0] count; //Counter for address for ROM. Controlled by MClock

assign Resetn = SW[0];
assign MClock = KEY[0];
assign PClock = KEY[1];
assign Run = SW[9];

assign BusWires = LEDR[8:0];
assign Done = LEDR[9];

	processor p0 (
		.Clock        (PClock),
		.Resetn       (Resetn), 
		.DIN          (DIN2proc), 
	   .Run          (Run),
		
	   .Done         (Done),
	   .BusWires     (BusWires)


		//.reset_reset_n              (reset_n),              //               reset.reset_n
		//.led_pio_external_export    (USER_LED[8:1]),    //    led_pio_external.export
		//.button_pio_external_export (PB[4:1])  // button_pio_external.export
	);

	inst_mem SyncRom1p (
		.address(count), //5 bit address because 32 possible addresses
		.clock (MClock), //Running on seperate clock than processor
		
		.q(DIN2proc) //Instruction/Data will be sent to processor
	
	);

	//Counter to move through address in ROM
	always @(posedge MClock or negedge Resetn)
	begin
		if (!Resetn)
			count <= 'd0;
		else begin
			if (count == 'h1f) 
				count <= 'd0;
			else	
				count <= count+1'b1;
		end		
	end	
	
endmodule