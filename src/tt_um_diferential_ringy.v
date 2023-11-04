/*
 * tt_um_emilian_ringy.v
 *
 * Test user module
 *
 * Author: Emilian Miron emilian.miron@gmail.com
 */

`default_nettype none


module tt_prim_diferential_dfrbp (
	input  wire D,
	output reg  Q,
	output reg  Q_N,
	input  wire CLK,
	input  wire RESET_B
);

	always @(posedge CLK or negedge RESET_B)
		if (~RESET_B) begin
			Q   <= 1'b0;
			Q_N <= 1'b1;
		end else begin
			Q   <=  D;
			Q_N <= ~D;
		end

endmodule

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

	localparam  OSC_LEN = 21;

	reg rst_n_i;
	reg [4:0] osc_cfg;
	reg [4:0] clk_cfg;

	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			rst_n_i <= 1'b0;
		else
			rst_n_i <= 1'b1;

	always @(posedge clk or negedge rst_n_i)
	begin
		if (~rst_n_i)
		begin
			osc_cfg <= 0;
			clk_cfg <= 0;
		end else begin
			case (ui_in[1:0])                                                                                          
					0: osc_cfg <= ui_in[7:2];
					1: clk_cfg <= ui_in[7:2];
					2: osc_cfg <= ui_in[7:2];
					3: osc_cfg <= ui_in[7:2];
			endcase 
		end
	end
	
	wire [OSC_LEN-1:0] osc;

	genvar i;
	generate
		// Oscillator, inspired from tt05-ringosc-counter.
		for (i = 0; i < OSC_LEN; i = i + 1) begin: ringosc
			wire y;
			if (i == 0)
				assign y = osc_cfg[0] ? osc[OSC_LEN - 1] : 0;
			else if (i == 2)
				assign y = osc_cfg[1] ? osc[i / 2 - 1] : osc[i - 1];
			else if (i == 4)
				assign y = osc_cfg[2] ? osc[i / 2 - 1] : osc[i - 1];
			else if (i == 8)
				assign y = osc_cfg[3] ? osc[i / 2 - 1] : osc[i - 1];
			else if (i == 16)
				assign y = osc_cfg[4] ? osc[i / 2 - 1] : osc[i - 1];
			else
				assign y = osc[i - 1];
			

		`ifdef SIM
			assign #0.1 osc[i] = !y;
		`else
			sky130_fd_sc_hd__inv_2 divrp_bit_I (
				.A     (y),
				.Y     (osc[i])
			);
		`endif

		end

		wire [5:0] divrp_n;
		wire [5:0] divrp;
		wire [5:0] divrp_clk = { divrp_n[4:0], osc[0] };

		// Oscillator ripple counter divider.
		for (i = 0; i < 6; i=i+1) begin: counter

`ifdef SIM
			tt_prim_diferential_dfrbp 
`else

			sky130_fd_sc_hd__dfrbp_2 
`endif
			divrp_bit_i (
		`ifdef WITH_POWER
				.VPWR (1'b1),
				.VGND (1'b0),
				.VPB  (1'b1),
				.VNB  (1'b0),
		`endif
				.D     (divrp_n[i]),
				.Q     (divrp[i]),
				.Q_N   (divrp_n[i]),
				.CLK   (divrp_clk[i]),
				.RESET_B (rst_n_i)
			);
		end
	endgenerate


	reg fast_clk;
	always @(*) begin                                                                                                
		case(clk_cfg[2:0])
			0: fast_clk = 0;
			1: fast_clk = osc[0];
			2: fast_clk = divrp[0];
			3: fast_clk = divrp[1];
			4: fast_clk = divrp[2];
			5: fast_clk = divrp[3];
			6: fast_clk = divrp[4];
			7: fast_clk = divrp[5];
		endcase                                                                                                       
	end 

	reg [7:0] fast_cnt;
	always @(posedge fast_clk) begin
		if (~rst_n_i)
			fast_cnt <= 0;
		else
		begin
			fast_cnt <= fast_cnt + 1;
		end
	end

	assign uo_out  = ui_in[0] ? fast_cnt[7:0] : uio_in;
	assign uio_out = ui_in[0] ? fast_cnt : 8'h00;
	assign uio_oe  = ui_in[0] ? 8'hff : 8'h00;

endmodule // tt_um_diferential_ringy
