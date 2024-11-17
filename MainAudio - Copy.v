
module MainAudio(
	// Inputs
	CLOCK_50,
	KEY,
	x0,
	x1,
	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK,
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0] KEY;
input		[3:0]	x0;
input		[3:0]	x1;
//input [8:0] SW;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [18:0] delay_cnt;
reg  [18:0] delay;

reg snd;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end else delay_cnt <= delay_cnt + 1;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/



 //This current version of audio frequency selection assumes an 8x8 minesweeper grid. Selection code will expand if more modes are considered
    always@(posedge CLOCK_50)
    begin
	 if(~KEY[0])
	delay<=19'b0; // 32'd###

	else if(x0==4'b0101&&x1==4'b1010)
			delay<=19'd50620;
	else if(x0==4'b0101&&x1==4'b1001)
		delay<=19'd85132;
	else if( (x0==4'b0001&&x1==4'b0110)||(x0==4'b0001&&x1==4'b1110)||(x0==4'b0010&&x1==4'b0110)||(x0==4'b0110&&x1==4'b0101)||(x0==4'b0010&&x1==4'b1110)||(x0==4'b0011&&x1==4'b0110)||(x0==4'b0011&&x1==4'b1101)||(x0==4'b0011&&x1==4'b1110))
		delay <= 19'd95555;
		
    end 
	 
wire [31:0] sound = snd ? 32'd10000000 : -32'd10000000;



assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
//assign LEDR[0] = write_audio_out;
assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0]) //watch out
);

endmodule













/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_Avalon_Audio                                      *
 * Description:                                                              *
 *      This module reads and writes data to the Audio chip on Altera's DE2  *
 *   Development and Education Board. The audio chip must be in master mode  *
 *   and the digital format must be left justified.                          *
 *                                                                           *
 *****************************************************************************/

module Audio_Controller(
	// Inputs
	CLOCK_50,
	reset,

	clear_audio_in_memory,	
	read_audio_in,

	clear_audio_out_memory,
	left_channel_audio_out,
	right_channel_audio_out,
	write_audio_out,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	// Outputs
	left_channel_audio_in,
	right_channel_audio_in,
	audio_in_available,

	audio_out_allowed,

	AUD_XCK,
	AUD_DACDAT
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

localparam AUDIO_DATA_WIDTH	= 32;
localparam BIT_COUNTER_INIT	= 5'd31;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input				reset;

input				clear_audio_in_memory;
input				read_audio_in;

input				clear_audio_out_memory;
input		[AUDIO_DATA_WIDTH:1]	left_channel_audio_out;
input		[AUDIO_DATA_WIDTH:1]	right_channel_audio_out;
input				write_audio_out;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

// Outputs
output	reg			audio_in_available;
output		[AUDIO_DATA_WIDTH:1]	left_channel_audio_in;
output		[AUDIO_DATA_WIDTH:1]	right_channel_audio_in;

output	reg			audio_out_allowed;

output				AUD_XCK;
output				AUD_DACDAT;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire				bclk_rising_edge;
wire				bclk_falling_edge;

wire				adc_lrclk_rising_edge;
wire				adc_lrclk_falling_edge;

wire				dac_lrclk_rising_edge;
wire				dac_lrclk_falling_edge;

wire		[7:0]	left_channel_read_available;
wire		[7:0]	right_channel_read_available;

wire		[7:0]	left_channel_write_space;
wire		[7:0]	right_channel_write_space;

// Internal Registers
reg					done_adc_channel_sync;
reg					done_dac_channel_sync;

// State Machine Registers


/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

// Output Registers
always @ (posedge CLOCK_50)
begin
	if (reset == 1'b1)
		audio_in_available <= 1'b0;
	else if ((left_channel_read_available[7] | left_channel_read_available[6])
			& (right_channel_read_available[7] | right_channel_read_available[6]))
		audio_in_available <= 1'b1;
	else
		audio_in_available <= 1'b0;
end

always @ (posedge CLOCK_50)
begin
	if (reset == 1'b1)
		audio_out_allowed <= 1'b0;
	else if ((left_channel_write_space[7] | left_channel_write_space[6])
			& (right_channel_write_space[7] | right_channel_write_space[6]))
		audio_out_allowed <= 1'b1;
	else
		audio_out_allowed <= 1'b0;
end

// Internal Registers
always @ (posedge CLOCK_50)
begin
	if (reset == 1'b1)
		done_adc_channel_sync <= 1'b0;
	else if (adc_lrclk_rising_edge == 1'b1)
		done_adc_channel_sync <= 1'b1;
end

always @ (posedge CLOCK_50)
begin
	if (reset == 1'b1)
		done_dac_channel_sync <= 1'b0;
	else if (dac_lrclk_falling_edge == 1'b1)
		done_dac_channel_sync <= 1'b1;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

assign AUD_BCLK		= 1'bZ;
assign AUD_ADCLRCK	= 1'bZ;
assign AUD_DACLRCK	= 1'bZ;


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Altera_UP_Clock_Edge Bit_Clock_Edges (
	// Inputs
	.clk			(CLOCK_50),
	.reset			(reset),
	
	.test_clk		(AUD_BCLK),
	
	// Bidirectionals

	// Outputs
	.rising_edge	(bclk_rising_edge),
	.falling_edge	(bclk_falling_edge)
);

Altera_UP_Clock_Edge ADC_Left_Right_Clock_Edges (
	// Inputs
	.clk			(CLOCK_50),
	.reset			(reset),
	
	.test_clk		(AUD_ADCLRCK),
	
	// Bidirectionals

	// Outputs
	.rising_edge	(adc_lrclk_rising_edge),
	.falling_edge	(adc_lrclk_falling_edge)
);

Altera_UP_Clock_Edge DAC_Left_Right_Clock_Edges (
	// Inputs
	.clk			(CLOCK_50),
	.reset			(reset),
	
	.test_clk		(AUD_DACLRCK),
	
	// Bidirectionals

	// Outputs
	.rising_edge	(dac_lrclk_rising_edge),
	.falling_edge	(dac_lrclk_falling_edge)
);

Altera_UP_Audio_In_Deserializer Audio_In_Deserializer (
	// Inputs
	.clk							(CLOCK_50),
	.reset							(reset | clear_audio_in_memory),
	
	.bit_clk_rising_edge			(bclk_rising_edge),
	.bit_clk_falling_edge			(bclk_falling_edge),
	.left_right_clk_rising_edge		(adc_lrclk_rising_edge),
	.left_right_clk_falling_edge	(adc_lrclk_falling_edge),

	.done_channel_sync				(done_adc_channel_sync),

	.serial_audio_in_data			(AUD_ADCDAT),

	.read_left_audio_data_en		(read_audio_in & audio_in_available),
	.read_right_audio_data_en		(read_audio_in & audio_in_available),

	// Bidirectionals

	// Outputs
	.left_audio_fifo_read_space		(left_channel_read_available),
	.right_audio_fifo_read_space	(right_channel_read_available),

	.left_channel_data				(left_channel_audio_in),
	.right_channel_data				(right_channel_audio_in)
);
defparam
	Audio_In_Deserializer.AUDIO_DATA_WIDTH = AUDIO_DATA_WIDTH,
	Audio_In_Deserializer.BIT_COUNTER_INIT = BIT_COUNTER_INIT;

Altera_UP_Audio_Out_Serializer Audio_Out_Serializer (
	// Inputs
	.clk							(CLOCK_50),
	.reset							(reset | clear_audio_out_memory),
	
	.bit_clk_rising_edge			(bclk_rising_edge),
	.bit_clk_falling_edge			(bclk_falling_edge),
	.left_right_clk_rising_edge		(done_dac_channel_sync & dac_lrclk_rising_edge),
	.left_right_clk_falling_edge	(done_dac_channel_sync & dac_lrclk_falling_edge),
	
	.left_channel_data				(left_channel_audio_out),
	.left_channel_data_en			(write_audio_out & audio_out_allowed),

	.right_channel_data				(right_channel_audio_out),
	.right_channel_data_en			(write_audio_out & audio_out_allowed),
	
	// Bidirectionals

	// Outputs
	.left_channel_fifo_write_space	(left_channel_write_space),
	.right_channel_fifo_write_space	(right_channel_write_space),

	.serial_audio_out_data			(AUD_DACDAT)
);
defparam
	Audio_Out_Serializer.AUDIO_DATA_WIDTH = AUDIO_DATA_WIDTH;

Audio_Clock Audio_Clock (
	// Inputs
	.inclk0			(CLOCK_50),
	.areset			(),

	// Outputs
	.c0				(AUD_XCK),
	.locked			()
);

endmodule

// megafunction wizard: %ALTPLL%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altpll 

// ============================================================
// File Name: Audio_Clock.v
// Megafunction Name(s):
// 			altpll
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 7.2 Build 151 09/26/2007 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2007 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, Altera MegaCore Function License 
//Agreement, or other applicable license agreement, including, 
//without limitation, that your use is for the sole purpose of 
//programming logic devices manufactured by Altera and sold by 
//Altera or its authorized distributors.  Please refer to the 
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Audio_Clock (
	areset,
	inclk0,
	c0,
	locked);

	input	  areset;
	input	  inclk0;
	output	  c0;
	output	  locked;

	wire [5:0] sub_wire0;
	wire  sub_wire2;
	wire [0:0] sub_wire5 = 1'h0;
	wire [0:0] sub_wire1 = sub_wire0[0:0];
	wire  c0 = sub_wire1;
	wire  locked = sub_wire2;
	wire  sub_wire3 = inclk0;
	wire [1:0] sub_wire4 = {sub_wire5, sub_wire3};

	altpll	altpll_component (
				.inclk (sub_wire4),
				.areset (areset),
				.clk (sub_wire0),
				.locked (sub_wire2),
				.activeclock (),
				.clkbad (),
				.clkena ({6{1'b1}}),
				.clkloss (),
				.clkswitch (1'b0),
				.configupdate (1'b0),
				.enable0 (),
				.enable1 (),
				.extclk (),
				.extclkena ({4{1'b1}}),
				.fbin (1'b1),
				.fbmimicbidir (),
				.fbout (),
				.pfdena (1'b1),
				.phasecounterselect ({4{1'b1}}),
				.phasedone (),
				.phasestep (1'b1),
				.phaseupdown (1'b1),
				.pllena (1'b1),
				.scanaclr (1'b0),
				.scanclk (1'b0),
				.scanclkena (1'b1),
				.scandata (1'b0),
				.scandataout (),
				.scandone (),
				.scanread (1'b0),
				.scanwrite (1'b0),
				.sclkout0 (),
				.sclkout1 (),
				.vcooverrange (),
				.vcounderrange ());
	defparam
		altpll_component.clk0_divide_by = 4,
		altpll_component.clk0_duty_cycle = 50,
		altpll_component.clk0_multiply_by = 1,
		altpll_component.clk0_phase_shift = "0",
		altpll_component.compensate_clock = "CLK0",
		altpll_component.gate_lock_signal = "NO",
		altpll_component.inclk0_input_frequency = 20000,
		altpll_component.intended_device_family = "Cyclone II",
		altpll_component.invalid_lock_multiplier = 5,
		altpll_component.lpm_hint = "CBX_MODULE_PREFIX=Audio_Clock",
		altpll_component.lpm_type = "altpll",
		altpll_component.operation_mode = "NORMAL",
		altpll_component.port_activeclock = "PORT_UNUSED",
		altpll_component.port_areset = "PORT_USED",
		altpll_component.port_clkbad0 = "PORT_UNUSED",
		altpll_component.port_clkbad1 = "PORT_UNUSED",
		altpll_component.port_clkloss = "PORT_UNUSED",
		altpll_component.port_clkswitch = "PORT_UNUSED",
		altpll_component.port_configupdate = "PORT_UNUSED",
		altpll_component.port_fbin = "PORT_UNUSED",
		altpll_component.port_inclk0 = "PORT_USED",
		altpll_component.port_inclk1 = "PORT_UNUSED",
		altpll_component.port_locked = "PORT_USED",
		altpll_component.port_pfdena = "PORT_UNUSED",
		altpll_component.port_phasecounterselect = "PORT_UNUSED",
		altpll_component.port_phasedone = "PORT_UNUSED",
		altpll_component.port_phasestep = "PORT_UNUSED",
		altpll_component.port_phaseupdown = "PORT_UNUSED",
		altpll_component.port_pllena = "PORT_UNUSED",
		altpll_component.port_scanaclr = "PORT_UNUSED",
		altpll_component.port_scanclk = "PORT_UNUSED",
		altpll_component.port_scanclkena = "PORT_UNUSED",
		altpll_component.port_scandata = "PORT_UNUSED",
		altpll_component.port_scandataout = "PORT_UNUSED",
		altpll_component.port_scandone = "PORT_UNUSED",
		altpll_component.port_scanread = "PORT_UNUSED",
		altpll_component.port_scanwrite = "PORT_UNUSED",
		altpll_component.port_clk0 = "PORT_USED",
		altpll_component.port_clk1 = "PORT_UNUSED",
		altpll_component.port_clk2 = "PORT_UNUSED",
		altpll_component.port_clk3 = "PORT_UNUSED",
		altpll_component.port_clk4 = "PORT_UNUSED",
		altpll_component.port_clk5 = "PORT_UNUSED",
		altpll_component.port_clkena0 = "PORT_UNUSED",
		altpll_component.port_clkena1 = "PORT_UNUSED",
		altpll_component.port_clkena2 = "PORT_UNUSED",
		altpll_component.port_clkena3 = "PORT_UNUSED",
		altpll_component.port_clkena4 = "PORT_UNUSED",
		altpll_component.port_clkena5 = "PORT_UNUSED",
		altpll_component.port_extclk0 = "PORT_UNUSED",
		altpll_component.port_extclk1 = "PORT_UNUSED",
		altpll_component.port_extclk2 = "PORT_UNUSED",
		altpll_component.port_extclk3 = "PORT_UNUSED",
		altpll_component.valid_lock_multiplier = 1;


endmodule


/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_Audio_Out_Serializer                              *
 * Description:                                                              *
 *      This module writes data to the Audio DAC on the Altera DE2 board.    *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_Audio_Out_Serializer (
	// Inputs
	clk,
	reset,
	
	bit_clk_rising_edge,
	bit_clk_falling_edge,
	left_right_clk_rising_edge,
	left_right_clk_falling_edge,
	
	left_channel_data,
	left_channel_data_en,

	right_channel_data,
	right_channel_data_en,
	
	// Bidirectionals

	// Outputs
	left_channel_fifo_write_space,
	right_channel_fifo_write_space,

	serial_audio_out_data
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter AUDIO_DATA_WIDTH	= 32;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				clk;
input				reset;

input				bit_clk_rising_edge;
input				bit_clk_falling_edge;
input				left_right_clk_rising_edge;
input				left_right_clk_falling_edge;

input		[AUDIO_DATA_WIDTH:1]		left_channel_data;
input				left_channel_data_en;

input		[AUDIO_DATA_WIDTH:1]		right_channel_data;
input				right_channel_data_en;

// Bidirectionals

// Outputs
output	reg	[7:0]	left_channel_fifo_write_space;
output	reg	[7:0]	right_channel_fifo_write_space;

output	reg			serial_audio_out_data;


/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire				read_left_channel;
wire				read_right_channel;

wire				left_channel_fifo_is_empty;
wire				right_channel_fifo_is_empty;

wire				left_channel_fifo_is_full;
wire				right_channel_fifo_is_full;

wire		[6:0]	left_channel_fifo_used;
wire		[6:0]	right_channel_fifo_used;

wire		[AUDIO_DATA_WIDTH:1]		left_channel_from_fifo;
wire		[AUDIO_DATA_WIDTH:1]		right_channel_from_fifo;

// Internal Registers
reg					left_channel_was_read;
reg			[AUDIO_DATA_WIDTH:1]	data_out_shift_reg;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		left_channel_fifo_write_space <= 8'h00;
	else
		left_channel_fifo_write_space <= 8'h80 - {left_channel_fifo_is_full,left_channel_fifo_used};
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		right_channel_fifo_write_space <= 8'h00;
	else
		right_channel_fifo_write_space <= 8'h80 - {right_channel_fifo_is_full,right_channel_fifo_used};
end


always @(posedge clk)
begin
	if (reset == 1'b1)
		serial_audio_out_data <= 1'b0;
	else
		serial_audio_out_data <= data_out_shift_reg[AUDIO_DATA_WIDTH];
end


always @(posedge clk)
begin
	if (reset == 1'b1)
		left_channel_was_read <= 1'b0;
	else if (read_left_channel)
		left_channel_was_read <=1'b1;
	else if (read_right_channel)
		left_channel_was_read <=1'b0;
end


always @(posedge clk)
begin
	if (reset == 1'b1)
		data_out_shift_reg	<= {AUDIO_DATA_WIDTH{1'b0}};
	else if (read_left_channel)
		data_out_shift_reg	<= left_channel_from_fifo;
	else if (read_right_channel)
		data_out_shift_reg	<= right_channel_from_fifo;
	else if (left_right_clk_rising_edge | left_right_clk_falling_edge)
		data_out_shift_reg	<= {AUDIO_DATA_WIDTH{1'b0}};
	else if (bit_clk_falling_edge)
		data_out_shift_reg	<= 
			{data_out_shift_reg[(AUDIO_DATA_WIDTH - 1):1], 1'b0};
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

assign read_left_channel	= left_right_clk_rising_edge &
								 ~left_channel_fifo_is_empty & 
								 ~right_channel_fifo_is_empty;
assign read_right_channel	= left_right_clk_falling_edge &
								left_channel_was_read;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Altera_UP_SYNC_FIFO Audio_Out_Left_Channel_FIFO(
	// Inputs
	.clk			(clk),
	.reset			(reset),

	.write_en		(left_channel_data_en & ~left_channel_fifo_is_full),
	.write_data		(left_channel_data),

	.read_en		(read_left_channel),
	
	// Bidirectionals

	// Outputs
	.fifo_is_empty	(left_channel_fifo_is_empty),
	.fifo_is_full	(left_channel_fifo_is_full),
	.words_used		(left_channel_fifo_used),

	.read_data		(left_channel_from_fifo)
);
defparam 
	Audio_Out_Left_Channel_FIFO.DATA_WIDTH	= AUDIO_DATA_WIDTH,
	Audio_Out_Left_Channel_FIFO.DATA_DEPTH	= 128,
	Audio_Out_Left_Channel_FIFO.ADDR_WIDTH	= 7;

Altera_UP_SYNC_FIFO Audio_Out_Right_Channel_FIFO(
	// Inputs
	.clk			(clk),
	.reset			(reset),

	.write_en		(right_channel_data_en & ~right_channel_fifo_is_full),
	.write_data		(right_channel_data),

	.read_en		(read_right_channel),
	
	// Bidirectionals

	// Outputs
	.fifo_is_empty	(right_channel_fifo_is_empty),
	.fifo_is_full	(right_channel_fifo_is_full),
	.words_used		(right_channel_fifo_used),

	.read_data		(right_channel_from_fifo)
);
defparam 
	Audio_Out_Right_Channel_FIFO.DATA_WIDTH	= AUDIO_DATA_WIDTH,
	Audio_Out_Right_Channel_FIFO.DATA_DEPTH	= 128,
	Audio_Out_Right_Channel_FIFO.ADDR_WIDTH	= 7;

endmodule

/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_Audio_In_Deserializer                             *
 * Description:                                                              *
 *      This module read data from the Audio ADC on the Altera DE2 board.    *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_Audio_In_Deserializer (
	// Inputs
	clk,
	reset,
	
	bit_clk_rising_edge,
	bit_clk_falling_edge,
	left_right_clk_rising_edge,
	left_right_clk_falling_edge,

	done_channel_sync,

	serial_audio_in_data,

	read_left_audio_data_en,
	read_right_audio_data_en,

	// Bidirectionals

	// Outputs
	left_audio_fifo_read_space,
	right_audio_fifo_read_space,

	left_channel_data,
	right_channel_data
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter AUDIO_DATA_WIDTH	= 32;
parameter BIT_COUNTER_INIT	= 5'd31;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				clk;
input				reset;

input				bit_clk_rising_edge;
input				bit_clk_falling_edge;
input				left_right_clk_rising_edge;
input				left_right_clk_falling_edge;

input				done_channel_sync;

input				serial_audio_in_data;

input				read_left_audio_data_en;
input				read_right_audio_data_en;

// Bidirectionals

// Outputs
output	reg	[7:0]	left_audio_fifo_read_space;
output	reg	[7:0]	right_audio_fifo_read_space;

output		[AUDIO_DATA_WIDTH:1]	left_channel_data;
output		[AUDIO_DATA_WIDTH:1]	right_channel_data;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				valid_audio_input;

wire				left_channel_fifo_is_empty;
wire				right_channel_fifo_is_empty;

wire				left_channel_fifo_is_full;
wire				right_channel_fifo_is_full;

wire		[6:0]	left_channel_fifo_used;
wire		[6:0]	right_channel_fifo_used;

// Internal Registers
reg			[AUDIO_DATA_WIDTH:1]	data_in_shift_reg;

// State Machine Registers


/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		left_audio_fifo_read_space			<= 8'h00;
	else
	begin
		left_audio_fifo_read_space[7]		<= left_channel_fifo_is_full;
		left_audio_fifo_read_space[6:0]		<= left_channel_fifo_used;
	end
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		right_audio_fifo_read_space			<= 8'h00;
	else
	begin
		right_audio_fifo_read_space[7]		<= right_channel_fifo_is_full;
		right_audio_fifo_read_space[6:0]	<= right_channel_fifo_used;
	end
end




always @(posedge clk)
begin
	if (reset == 1'b1)
		data_in_shift_reg	<= {AUDIO_DATA_WIDTH{1'b0}};
	else if (bit_clk_rising_edge & valid_audio_input)
		data_in_shift_reg	<= 
			{data_in_shift_reg[(AUDIO_DATA_WIDTH - 1):1], 
			 serial_audio_in_data};
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Altera_UP_Audio_Bit_Counter Audio_Out_Bit_Counter (
	// Inputs
	.clk							(clk),
	.reset							(reset),
	
	.bit_clk_rising_edge			(bit_clk_rising_edge),
	.bit_clk_falling_edge			(bit_clk_falling_edge),
	.left_right_clk_rising_edge		(left_right_clk_rising_edge),
	.left_right_clk_falling_edge	(left_right_clk_falling_edge),

	// Bidirectionals

	// Outputs
	.counting						(valid_audio_input)
);
defparam 
	Audio_Out_Bit_Counter.BIT_COUNTER_INIT	= BIT_COUNTER_INIT;

Altera_UP_SYNC_FIFO Audio_In_Left_Channel_FIFO(
	// Inputs
	.clk			(clk),
	.reset			(reset),

	.write_en		(left_right_clk_falling_edge & ~left_channel_fifo_is_full & done_channel_sync),
	.write_data		(data_in_shift_reg),

	.read_en		(read_left_audio_data_en & ~left_channel_fifo_is_empty),
	
	// Bidirectionals

	// Outputs
	.fifo_is_empty	(left_channel_fifo_is_empty),
	.fifo_is_full	(left_channel_fifo_is_full),
	.words_used		(left_channel_fifo_used),

	.read_data		(left_channel_data)
);
defparam 
	Audio_In_Left_Channel_FIFO.DATA_WIDTH	= AUDIO_DATA_WIDTH,
	Audio_In_Left_Channel_FIFO.DATA_DEPTH	= 128,
	Audio_In_Left_Channel_FIFO.ADDR_WIDTH	= 7;

Altera_UP_SYNC_FIFO Audio_In_Right_Channel_FIFO(
	// Inputs
	.clk			(clk),
	.reset			(reset),

	.write_en		(left_right_clk_rising_edge & ~right_channel_fifo_is_full & done_channel_sync),
	.write_data		(data_in_shift_reg),

	.read_en		(read_right_audio_data_en & ~right_channel_fifo_is_empty),
	
	// Bidirectionals

	// Outputs
	.fifo_is_empty	(right_channel_fifo_is_empty),
	.fifo_is_full	(right_channel_fifo_is_full),
	.words_used		(right_channel_fifo_used),

	.read_data		(right_channel_data)
);
defparam 
	Audio_In_Right_Channel_FIFO.DATA_WIDTH	= AUDIO_DATA_WIDTH,
	Audio_In_Right_Channel_FIFO.DATA_DEPTH	= 128,
	Audio_In_Right_Channel_FIFO.ADDR_WIDTH	= 7;

endmodule

/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_Audio_Bit_Counter                                 *
 * Description:                                                              *
 *      This module counts which bits for serial audio transfers. The module *
 *   assume that the data format is I2S, as it is described in the audio     *
 *   chip's datasheet.                                                       *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_Audio_Bit_Counter (
	// Inputs
	clk,
	reset,
	
	bit_clk_rising_edge,
	bit_clk_falling_edge,
	left_right_clk_rising_edge,
	left_right_clk_falling_edge,
	
	// Bidirectionals

	// Outputs
	counting
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter BIT_COUNTER_INIT	= 5'd31;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				clk;
input				reset;
	
input				bit_clk_rising_edge;
input				bit_clk_falling_edge;
input				left_right_clk_rising_edge;
input				left_right_clk_falling_edge;

// Bidirectionals

// Outputs
output	reg			counting;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/


/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire				reset_bit_counter;

// Internal Registers
reg			[4:0]	bit_counter;

// State Machine Registers


/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		bit_counter <= 5'h00;
	else if (reset_bit_counter == 1'b1)
		bit_counter <= BIT_COUNTER_INIT;
	else if ((bit_clk_falling_edge == 1'b1) && (bit_counter != 5'h00))
		bit_counter <= bit_counter - 5'h01;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		counting <= 1'b0;
	else if (reset_bit_counter == 1'b1)
		counting <= 1'b1;
	else if ((bit_clk_falling_edge == 1'b1) && (bit_counter == 5'h00))
		counting <= 1'b0;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

assign reset_bit_counter = left_right_clk_rising_edge | 
							left_right_clk_falling_edge;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

endmodule

/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_SYNC_FIFO                                         *
 * Description:                                                              *
 *      This module is a FIFO with same clock for both reads and writes.     *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_SYNC_FIFO (
	// Inputs
	clk,
	reset,

	write_en,
	write_data,

	read_en,
	
	// Bidirectionals

	// Outputs
	fifo_is_empty,
	fifo_is_full,
	words_used,

	read_data
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter	DATA_WIDTH	= 32;
parameter	DATA_DEPTH	= 128;
parameter	ADDR_WIDTH	= 7;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				clk;
input				reset;

input				write_en;
input		[DATA_WIDTH:1]	write_data;

input				read_en;

// Bidirectionals

// Outputs
output				fifo_is_empty;
output				fifo_is_full;
output		[ADDR_WIDTH:1]	words_used;

output		[DATA_WIDTH:1]	read_data;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires

// Internal Registers

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/


/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


scfifo	Sync_FIFO (
	// Inputs
	.clock			(clk),
	.sclr			(reset),

	.data			(write_data),
	.wrreq			(write_en),

	.rdreq			(read_en),

	// Bidirectionals

	// Outputs
	.empty			(fifo_is_empty),
	.full			(fifo_is_full),
	.usedw			(words_used),
	
	.q				(read_data)

	// Unused
	// synopsys translate_off
	,
	.aclr			(),
	.almost_empty	(),
	.almost_full	()
	// synopsys translate_on
);
defparam
	Sync_FIFO.add_ram_output_register	= "OFF",
	Sync_FIFO.intended_device_family	= "Cyclone II",
	Sync_FIFO.lpm_numwords				= DATA_DEPTH,
	Sync_FIFO.lpm_showahead				= "ON",
	Sync_FIFO.lpm_type					= "scfifo",
	Sync_FIFO.lpm_width					= DATA_WIDTH,
	Sync_FIFO.lpm_widthu				= ADDR_WIDTH,
	Sync_FIFO.overflow_checking			= "OFF",
	Sync_FIFO.underflow_checking		= "OFF",
	Sync_FIFO.use_eab					= "ON";

endmodule

module avconf (	//	Host Side
						CLOCK_50,
						reset,
						//	I2C Side
						FPGA_I2C_SCLK,
						FPGA_I2C_SDAT	);
//	Host Side
input		CLOCK_50;
input		reset;
//	I2C Side
output		FPGA_I2C_SCLK;
inout		FPGA_I2C_SDAT;
//	Internal Registers/Wires
reg	[15:0]	mI2C_CLK_DIV;
reg	[23:0]	mI2C_DATA;
reg			mI2C_CTRL_CLK;
reg			mI2C_GO;
wire		mI2C_END;
wire		mI2C_ACK;
wire		iRST_N = !reset;
reg	[15:0]	LUT_DATA;
reg	[5:0]	LUT_INDEX;
reg	[3:0]	mSetup_ST;

parameter USE_MIC_INPUT		= 1'b0;

parameter AUD_LINE_IN_LC	= 9'd24;
parameter AUD_LINE_IN_RC	= 9'd24;
parameter AUD_LINE_OUT_LC	= 9'd119;
parameter AUD_LINE_OUT_RC	= 9'd119;
parameter AUD_ADC_PATH		= 9'd17;
parameter AUD_DAC_PATH		= 9'd6;
parameter AUD_POWER			= 9'h000;
parameter AUD_DATA_FORMAT	= 9'd77;
parameter AUD_SAMPLE_CTRL	= 9'd0;
parameter AUD_SET_ACTIVE	= 9'h001;

//	Clock Setting
parameter	CLK_Freq	=	50000000;	//	50	MHz
parameter	I2C_Freq	=	20000;		//	20	KHz
//	LUT Data Number
parameter	LUT_SIZE	=	50;
//	Audio Data Index
parameter	SET_LIN_L	=	0;
parameter	SET_LIN_R	=	1;
parameter	SET_HEAD_L	=	2;
parameter	SET_HEAD_R	=	3;
parameter	A_PATH_CTRL	=	4;
parameter	D_PATH_CTRL	=	5;
parameter	POWER_ON	=	6;
parameter	SET_FORMAT	=	7;
parameter	SAMPLE_CTRL	=	8;
parameter	SET_ACTIVE	=	9;
//	Video Data Index
parameter	SET_VIDEO	=	10;

/////////////////////	I2C Control Clock	////////////////////////
always@(posedge CLOCK_50 or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		mI2C_CTRL_CLK	<=	0;
		mI2C_CLK_DIV	<=	0;
	end
	else
	begin
		if( mI2C_CLK_DIV	< (CLK_Freq/I2C_Freq) )
		mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
		else
		begin
			mI2C_CLK_DIV	<=	0;
			mI2C_CTRL_CLK	<=	~mI2C_CTRL_CLK;
		end
	end
end
////////////////////////////////////////////////////////////////////
I2C_Controller 	u0	(	.CLOCK(mI2C_CTRL_CLK),		//	Controller Work Clock
						.FPGA_I2C_SCLK(FPGA_I2C_SCLK),		//	I2C CLOCK
 	 	 	 	 	 	.FPGA_I2C_SDAT(FPGA_I2C_SDAT),		//	I2C DATA
						.I2C_DATA(mI2C_DATA),		//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
						.GO(mI2C_GO),      			//	GO transfor
						.END(mI2C_END),				//	END transfor 
						.ACK(mI2C_ACK),				//	ACK
						.RESET(iRST_N)	);
////////////////////////////////////////////////////////////////////
//////////////////////	Config Control	////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mSetup_ST	<=	0;
		mI2C_GO		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
			case(mSetup_ST)
			0:	begin
					if(LUT_INDEX<SET_VIDEO)
					mI2C_DATA	<=	{8'h34,LUT_DATA};
					else
					mI2C_DATA	<=	{8'h40,LUT_DATA};
					mI2C_GO		<=	1;
					mSetup_ST	<=	1;
				end
			1:	begin
					if(mI2C_END)
					begin
						if(!mI2C_ACK)
						mSetup_ST	<=	2;
						else
						mSetup_ST	<=	0;							
						mI2C_GO		<=	0;
					end
				end
			2:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mSetup_ST	<=	0;
				end
			endcase
		end
	end
end
////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////	
always
begin
	LUT_DATA	<=	16'h0000;
	case(LUT_INDEX)
	//	Audio Config Data
	SET_LIN_L	:	LUT_DATA	<=	{7'h0, AUD_LINE_IN_LC};
	SET_LIN_R	:	LUT_DATA	<=	{7'h1, AUD_LINE_IN_RC};
	SET_HEAD_L	:	LUT_DATA	<=	{7'h2, AUD_LINE_OUT_LC};
	SET_HEAD_R	:	LUT_DATA	<=	{7'h3, AUD_LINE_OUT_RC};
	A_PATH_CTRL	:	LUT_DATA	<=	{7'h4, AUD_ADC_PATH} + (16'h0004 * USE_MIC_INPUT);
	D_PATH_CTRL	:	LUT_DATA	<=	{7'h5, AUD_DAC_PATH};
	POWER_ON	:	LUT_DATA	<=	{7'h6, AUD_POWER};
	SET_FORMAT	:	LUT_DATA	<=	{7'h7, AUD_DATA_FORMAT};
	SAMPLE_CTRL	:	LUT_DATA	<=	{7'h8, AUD_SAMPLE_CTRL};
	SET_ACTIVE	:	LUT_DATA	<=	{7'h9, AUD_SET_ACTIVE};
	//	Video Config Data
	SET_VIDEO+0	:	LUT_DATA	<=	16'h1500;
	SET_VIDEO+1	:	LUT_DATA	<=	16'h1741;
	SET_VIDEO+2	:	LUT_DATA	<=	16'h3a16;
	SET_VIDEO+3	:	LUT_DATA	<=  16'h503f; // 16'h5004;
	SET_VIDEO+4	:	LUT_DATA	<=	16'hc305;
	SET_VIDEO+5	:	LUT_DATA	<=	16'hc480;
	SET_VIDEO+6	:	LUT_DATA	<=	16'h0e80;
	SET_VIDEO+7	:	LUT_DATA	<=	16'h503f; // 16'h5020;
	SET_VIDEO+8	:	LUT_DATA	<=	16'h5218;
	SET_VIDEO+9	:	LUT_DATA	<=	16'h58ed;
	SET_VIDEO+10:	LUT_DATA	<=	16'h77c5;
	SET_VIDEO+11:	LUT_DATA	<=	16'h7c93;
	SET_VIDEO+12:	LUT_DATA	<=	16'h7d00;
	SET_VIDEO+13:	LUT_DATA	<=	16'hd048;
	SET_VIDEO+14:	LUT_DATA	<=	16'hd5a0;
	SET_VIDEO+15:	LUT_DATA	<=	16'hd7ea;
	SET_VIDEO+16:	LUT_DATA	<=	16'he43e;
	SET_VIDEO+17:	LUT_DATA	<=	16'hea0f;
	SET_VIDEO+18:	LUT_DATA	<=	16'h3112;
	SET_VIDEO+19:	LUT_DATA	<=	16'h3281;
	SET_VIDEO+20:	LUT_DATA	<=	16'h3384;
	SET_VIDEO+21:	LUT_DATA	<=	16'h37A0;
	SET_VIDEO+22:	LUT_DATA	<=	16'he580;
	SET_VIDEO+23:	LUT_DATA	<=	16'he603;
	SET_VIDEO+24:	LUT_DATA	<=	16'he785;
	SET_VIDEO+25:	LUT_DATA	<=	16'h2778; // 16'h503f; // 16'h5000;
	SET_VIDEO+26:	LUT_DATA	<=	16'h5100;
	SET_VIDEO+27:	LUT_DATA	<=	16'h0050;
	SET_VIDEO+28:	LUT_DATA	<=	16'h1000;
	SET_VIDEO+29:	LUT_DATA	<=	16'h0402;
	SET_VIDEO+30:	LUT_DATA	<=	16'h0860;
	SET_VIDEO+31:	LUT_DATA	<=	16'h0a18;
	SET_VIDEO+32:	LUT_DATA	<=	16'h1100;
	SET_VIDEO+33:	LUT_DATA	<=	16'h2b00;
	SET_VIDEO+34:	LUT_DATA	<=	16'h2c8c;
	SET_VIDEO+35:	LUT_DATA	<=	16'h2df8;
	SET_VIDEO+36:	LUT_DATA	<=	16'h2eee;
	SET_VIDEO+37:	LUT_DATA	<=	16'h2ff4;
	SET_VIDEO+38:	LUT_DATA	<=	16'h30d2;
	SET_VIDEO+39:	LUT_DATA	<=	16'h0e05;
	endcase
end
////////////////////////////////////////////////////////////////////
endmodule
// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altrea Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL or Verilog source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:i2c controller
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Joe Yang          :| 05/07/10  :|      Initial Revision
//   V2.0 :| Paul Chow         :| 10/31/17  :| For DE1_SoC
// --------------------------------------------------------------------
module I2C_Controller (
	CLOCK,
	FPGA_I2C_SCLK,//I2C CLOCK
 	FPGA_I2C_SDAT,//I2C DATA
	I2C_DATA,//DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
	GO,      //GO transfor
	END,     //END transfor 
	W_R,     //W_R
	ACK,      //ACK
	RESET,
	//TEST
	SD_COUNTER,
	SDO
);
	input  CLOCK;
	input  [23:0]I2C_DATA;	
	input  GO;
	input  RESET;	
	input  W_R;
 	inout  FPGA_I2C_SDAT;	
	output FPGA_I2C_SCLK;
	output END;	
	output ACK;

//TEST
	output [5:0] SD_COUNTER;
	output SDO;


reg SDO;
reg SCLK;
reg END;
reg [23:0]SD;
reg [5:0]SD_COUNTER;

wire FPGA_I2C_SCLK=SCLK | ( ((SD_COUNTER >= 4) & (SD_COUNTER <=30))? ~CLOCK :0 );
wire FPGA_I2C_SDAT=SDO?1'bz:0 ;

reg ACK1,ACK2,ACK3;
wire ACK=ACK1 | ACK2 |ACK3;

//--I2C COUNTER
always @(negedge RESET or posedge CLOCK ) begin
if (!RESET) SD_COUNTER=6'b111111;
else begin
if (GO==0) 
	SD_COUNTER=0;
	else 
	if (SD_COUNTER < 6'b111111) SD_COUNTER=SD_COUNTER+1;	
end
end
//----

always @(negedge RESET or  posedge CLOCK ) begin
if (!RESET) begin SCLK=1;SDO=1; ACK1=0;ACK2=0;ACK3=0; END=1; end
else
case (SD_COUNTER)
	6'd0  : begin ACK1=0 ;ACK2=0 ;ACK3=0 ; END=0; SDO=1; SCLK=1;end
	//start
	6'd1  : begin SD=I2C_DATA;SDO=0;end
	6'd2  : SCLK=0;
	//SLAVE ADDR
	6'd3  : SDO=SD[23];
	6'd4  : SDO=SD[22];
	6'd5  : SDO=SD[21];
	6'd6  : SDO=SD[20];
	6'd7  : SDO=SD[19];
	6'd8  : SDO=SD[18];
	6'd9  : SDO=SD[17];
	6'd10 : SDO=SD[16];	
	6'd11 : SDO=1'b1;//ACK

	//SUB ADDR
	6'd12  : begin SDO=SD[15]; ACK1=FPGA_I2C_SDAT; end
	6'd13  : SDO=SD[14];
	6'd14  : SDO=SD[13];
	6'd15  : SDO=SD[12];
	6'd16  : SDO=SD[11];
	6'd17  : SDO=SD[10];
	6'd18  : SDO=SD[9];
	6'd19  : SDO=SD[8];
	6'd20  : SDO=1'b1;//ACK

	//DATA
	6'd21  : begin SDO=SD[7]; ACK2=FPGA_I2C_SDAT; end
	6'd22  : SDO=SD[6];
	6'd23  : SDO=SD[5];
	6'd24  : SDO=SD[4];
	6'd25  : SDO=SD[3];
	6'd26  : SDO=SD[2];
	6'd27  : SDO=SD[1];
	6'd28  : SDO=SD[0];
	6'd29  : SDO=1'b1;//ACK

	
	//stop
    6'd30 : begin SDO=1'b0;	SCLK=1'b0; ACK3=FPGA_I2C_SDAT; end	
    6'd31 : SCLK=1'b1; 
    6'd32 : begin SDO=1'b1; END=1; end 

endcase
end



endmodule

/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_Clock_Edge                                        *
 * Description:                                                              *
 *      This module finds clock edges of one clock at the frquency of        *
 *   another clock.                                                          *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_Clock_Edge (
	// Inputs
	clk,
	reset,
	
	test_clk,
	
	// Bidirectionals

	// Outputs
	rising_edge,
	falling_edge
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				clk;
input				reset;
	
input				test_clk;

// Bidirectionals

// Outputs
output				rising_edge;
output				falling_edge;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire				found_edge;

// Internal Registers
reg					cur_test_clk;
reg					last_test_clk;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
	cur_test_clk	<= test_clk;

always @(posedge clk)
	last_test_clk	<= cur_test_clk;

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

// Output Assignments
assign rising_edge	= found_edge & cur_test_clk;
assign falling_edge	= found_edge & last_test_clk;

// Internal Assignments
assign found_edge	= last_test_clk ^ cur_test_clk;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

endmodule





