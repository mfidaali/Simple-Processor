module processor (

	input [8:0] DIN,
	input Resetn, 
	input Clock, 
	input Run,
	output reg Done,
	output reg [8:0] BusWires
	
	);


parameter T0 = 2'b00, T1 = 2'b01, T2 = 2'b10, T3 = 2'b11;
reg [1:0] Tstep_D, Tstep_Q;

//**********************
//Output of Control FSM
//**********************
wire [9:0] select; //select for mux output (BusWires)
reg [7:0] RSel;
reg GSel, DINsel;

reg [7:0] Rin; //Enable signals for R# Registers

reg IRin; //Enable signal
reg AddOrSub; //0 means add, 1 mean subtract
reg Ain; //Enable signal
reg Gin; //Enable signal

//Instruction Reg declarations
wire [8:0] IR; //Instruction Register value, set when IRin from FSM goes high
wire [2:0] Instruction;
wire [2:0] InstRegX;
wire [2:0] InstRegY;

//Accumulator, Adder, G Reg declarations
wire [8:0] A;
wire [8:0] AddSubOut;
wire [8:0] G;


//R0-R7 reg declarations
wire [8:0] R0;
wire [8:0] R1;
wire [8:0] R2;
wire [8:0] R3;
wire [8:0] R4;
wire [8:0] R5;
wire [8:0] R6;
wire [8:0] R7;


//Xreg and Yreg declarations from Instruction register
wire [7:0] Xreg;
wire [7:0] Yreg;


//Breaking apart the Instruction Data
assign Instruction = IR[2:0];
assign InstRegX = IR[5:3];
assign InstRegY = IR[8:6];

dec3to8 decX (InstRegX, 1'b1, Xreg);
dec3to8 decY (InstRegY, 1'b1, Yreg);


// Control FSM state table
always @(Tstep_Q, Run, Done)
begin
	case (Tstep_Q)
		T0: // data is loaded into IR in this time step
			if (!Run) 
				Tstep_D = T0;
			else 
				Tstep_D = T1;
		T1: // 1st time step run
			if (Done) 
				Tstep_D = T0; //Load new instruction because current instruction has completed
			else 
				Tstep_D = T2; //Go to next time step because current instruction has not completed
		T2: // 2nd time step run
			if (Done) 
				Tstep_D = T0; //Load new instruction because current instruction has completed
			else 
				Tstep_D = T3; //Go to next time step because current instruction has not completed		
		T3: // 3rd time step run
				Tstep_D = T0; //Add and Sub instructions should be complete by now
	endcase
end


// Control FSM outputs
always @(Tstep_Q or Instruction or Xreg or Yreg)
begin
	//specify initial values
	IRin  = 1'b0;
	RSel[7:0] = 8'b0; 
	GSel = 1'b0; 
	DINsel = 1'b0;
	
	AddOrSub = 1'b0;
	
	Ain = 1'b0;
	Gin = 1'b0;
	Rin[7:0] = 8'b0;
	
	Done  = 1'b0;

	case (Tstep_Q)
		T0: // store DIN in IR in time step 0
		begin
				IRin = 1'b1;
		end
		T1: //define signals in time step 1
			case (Instruction)
				3'b000: //mv instruction
					begin
						RSel = Yreg;
						Rin = Xreg;
						Done = 1;
					end
				3'b001: //mvi instruction
					begin
						DINsel = 1;
						Rin = Xreg;
						Done = 1;
					end
				3'b010: //add instruction
					begin
						RSel = Xreg;
						Ain = 0;
						Done = 0;
					end	
				3'b011: //subtract instruction
					begin
						RSel = Xreg;
						Ain = 0;
						Done = 0;
					end
			endcase
		T2: //define signals in time step 2
			case (Instruction)
				3'b010: //add instruction
					begin
						RSel = Yreg;
						Gin = 1;
						Done = 0;
					end	
				3'b011: //subtract instruction
					begin
						RSel = Yreg;
						Gin = 1;
						AddOrSub = 1;
						Done = 0;
					end
			endcase
		T3: //define signals in time step 3
			case (Instruction)
				3'b010: //add instruction
					begin
						Rin = Xreg;
						GSel = 1;
						Done = 1;
					end	
				3'b011: //subtract instruction
					begin
						Rin = Xreg;
						GSel = 1;
						Done = 1;
					end
			endcase
			
	endcase
end


// Control FSM flip-flops
always @(posedge Clock, negedge Resetn)
begin
	if (!Resetn)
		Tstep_Q <= T0;
	else
		Tstep_Q <= Tstep_D;
end	

//Instruction Register Instantiation
reg_enable InstReg_0 (DIN, IRin, Clock, IR);

//Accumulator, Adder, and G Register Instantiation
reg_enable A_reg (BusWires, Ain, Clock, A);
addsub Addsub (A, BusWires, AddOrSub, Clock, AddSubOut); 
reg_enable G_reg (AddSubOut, Gin, Clock, G);

//Reg0-7 instantiation
reg_enable reg_0 (BusWires, Rin[0], Clock, R0);
reg_enable reg_1 (BusWires, Rin[1], Clock, R1);
reg_enable reg_2 (BusWires, Rin[2], Clock, R2);
reg_enable reg_3 (BusWires, Rin[3], Clock, R3);
reg_enable reg_4 (BusWires, Rin[4], Clock, R4);
reg_enable reg_5 (BusWires, Rin[5], Clock, R5);
reg_enable reg_6 (BusWires, Rin[6], Clock, R6);
reg_enable reg_7 (BusWires, Rin[7], Clock, R7);


//Mux instantiation for BusWires definition
assign select = {RSel[7:0], GSel, DINsel};

always @(select or RSel or GSel or DINsel) begin
	case(select)
		10'b0000000001: BusWires = DIN;
		10'b0000000010: BusWires = G;
		10'b0000000100: BusWires = R0;
		10'b0000001000: BusWires = R1;
		10'b0000010000: BusWires = R2;
		10'b0000100000: BusWires = R3;
		10'b0001000000: BusWires = R4;
		10'b0010000000: BusWires = R5;
		10'b0100000000: BusWires = R6;
		10'b1000000000: BusWires = R7;
	   default: BusWires = DIN;	
	endcase
end


endmodule