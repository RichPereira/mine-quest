
module KeyBoardAudio(
//input
CLOCK_50,
KEY,
AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,
	FPGA_I2C_SDAT,
	// Bidirectionals
	PS2_CLK,
	PS2_DAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,
	FPGA_I2C_SCLK,
	keyboardinput.
);

input CLOCK_50;
input [3:0] KEY;
input AUD_ADCDAT;

	// Bidirectionals
inout	AUD_BCLK;
inout	AUD_ADCLRCK;
inout	AUD_DACLRCK;
inout	FPGA_I2C_SDAT;
	// Bidirectionals
inout	PS2_CLK;
inout	PS2_DAT;

	// Outputs
output	AUD_XCK;
output	AUD_DACDAT;
output	FPGA_I2C_SCLK;
output [7:0] keyboardinput;



wire[7:0] last_data;
wire key_pressed;


PS2 k0(// Inputs
	// Inputs
	.CLOCK_50(CLOCK_50),
	.KEY(KEY),

	// Bidirectionals
	.PS2_CLK(PS2_CLK),
	.PS2_DAT(PS2_DAT),
	
	// Outputs
	.last_data_received(last_data)
	.key_pressed(key_pressed)
	);

MainAudio k1(// Inputs
	.CLOCK_50(CLOCK_50),
	.KEY(KEY),
	.x0(last_data[7:4]),
	.x1(last_data[3:0]),
	.enable(key_pressed),
	.AUD_ADCDAT(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK(AUD_BCLK),
	.AUD_ADCLRCK(AUD_ADCLRCK),
	.AUD_DACLRCK(AUD_DACLRCK),
	.FPGA_I2C_SDAT(AUD_DACLRCK),

	// Outputs
	.AUD_XCK(AUD_XCK),
	.AUD_DACDAT(AUD_DACDAT),
	.FPGA_I2C_SCLK(FPGA_I2C_SCLK)
	);

	 
    assign keyboardinput = last_data;
	 
endmodule





