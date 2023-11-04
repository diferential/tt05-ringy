/*
 * tt_um_emilian_ringy.v
 *
 * Test user module
 *
 * Author: Emilian Miron emilian.miron@gmail.com
 */

`default_nettype none

module tt_um_diferential_ringy (
	input  wire [7:0] ui_in,	// Dedicated inputs
	output wire [7:0] uo_out,	// Dedicated outputs
	input  wire [7:0] uio_in,	// IOs: Input path
	output wire [7:0] uio_out,	// IOs: Output path
	output wire [7:0] uio_oe,	// IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,
	input  wire       clk,
	input  wire       rst_n
);

	reg rst_n_i;
	reg [31:0] cnt;

	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			rst_n_i <= 1'b0;
		else
			rst_n_i <= 1'b1;

   	localparam CELLS = 10;
	reg [7:0] mmm [CELLS-1:0];

	always @(posedge clk or negedge rst_n_i)
		if (~rst_n_i)
			cnt <= 0;
		else
		begin
			cnt <= cnt + ui_in + mmm[uio_in];
			mmm[ui_in] <= cnt;
		end

	
	assign uo_out  = ui_in[0] ? cnt[31:24] : uio_in;
	assign uio_out = ui_in[0] ? cnt : 8'h00;
	assign uio_oe  = ui_in[0] ? 8'hff : 8'h00;


endmodule // tt_um_diferential_ringy
