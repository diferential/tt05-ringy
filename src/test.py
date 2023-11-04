import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_ringosc_cnt(dut):
	# input  wire [7:0] ui_in,	// Dedicated inputs
	# output wire [7:0] uo_out,	// Dedicated outputs
	# input  wire [7:0] uio_in,	// IOs: Input path
	# output wire [7:0] uio_out,	// IOs: Output path
	# output wire [7:0] uio_oe,	// IOs: Enable path (active high: 0=input, 1=output)
	# input  wire       ena,
	# input  wire       clk,
	# input  wire       rst_n

    dut._log.info("Reset the counter")
    dut.ui_in.value = 0;
    dut.rst_n.value = 0;
    dut.ena.value = 1;
    dut.clk.value = 0;
    dut.uio_in.value = 0;

    await Timer(1, units="ns")
    dut._log.info("Counter: " + str(dut.uio_oe.value));

    dut.clk.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 0;
    await Timer(1, units="ns")

    # out of reset
    dut.rst_n.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 0;
    await Timer(1, units="ns")
    dut.clk.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 0;
    await Timer(1, units="ns")

    dut.ui_in.value = 0b100;
    dut.clk.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 0;
    await Timer(1, units="ns")

    # start fast clk but in reset
    dut.ui_in.value = 0b100101;
    dut.clk.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 0;
    await Timer(1, units="ns")

    await Timer(10, units="ns")

    # clear fast_reset
    dut.ui_in.value = 0b000101;
    dut.clk.value = 1;
    await Timer(1, units="ns")
    dut.clk.value = 0;
    await Timer(1, units="ns")

    await Timer(50, units="ns")

    assert str(dut.uio_oe.value) == "00000000";
    assert dut.uio_out.value == 0;

    await Timer(10, units="ns")

    dut._log.info("All good!")

