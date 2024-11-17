
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
	HEX0,
	HEX1,
	HEX2,
	HEX3, 
	HEX4,
	HEX5, 
	HEX6, 
	HEX7,
	LEDR
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
output [8:0] LEDR;

output	wire	[6:0]	HEX0;
output	wire	[6:0]	HEX1;
output	wire	[6:0]	HEX2;
output	wire	[6:0]	HEX3;
output	wire	[6:0]	HEX4;
output	wire	[6:0]	HEX5;
output	wire	[6:0]	HEX6;
output	wire	[6:0]	HEX7;



wire[7:0] last_data;


PS2 k0(// Inputs
	// Inputs
	.CLOCK_50(CLOCK_50),
	.KEY(KEY),

	// Bidirectionals
	.PS2_CLK(PS2_CLK),
	.PS2_DAT(PS2_DAT),
	
	// Outputs
	.HEX0(HEX0),
	.HEX1(HEX1),
	.HEX2(HEX2),
	.HEX3(HEX3),
	.HEX4(HEX4),
	.HEX5(HEX5),
	.HEX6(HEX6),
	.HEX7(HEX7),
	.last_data_received(last_data)
	);

MainAudio k1(// Inputs
	.CLOCK_50(CLOCK_50),
	.KEY(KEY),
	.x0(last_data[7:4]),
	.x1(last_data[3:0]),
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

	 assign LEDR[3:0]=last_data[3:0];
	 assign LEDR[7:4]=last_data[7:4];
    
	 
endmodule





