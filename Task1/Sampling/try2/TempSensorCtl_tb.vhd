library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.testbench_utils.all;

entity TempSensorCtl_tb is
end TempSensorCtl_tb;
architecture behaviour of TempSensorCtl_tb is
    constant clk_period: time := 500 ns;

	component ADT7420 is
		Generic (
			CLOCKFREQ : natural := 2_000_000;
			bus_clk   : integer := 400_000;
			samplet   : integer := 1
		);
		port (
			inout_sda : inout std_logic;
			inout_scl : inout std_logic;

			in_clk  : in std_logic;
			in_srst : in std_logic;

			out_tmp : out std_logic_vector((16-1) downto 0);
			out_rdy : out std_logic;
			out_err : out std_logic;
			dbg_1	: out std_logic
		);
	end component;

for ADT_0: ADT7420 use entity work.ADT7420;

--    component TempSensorCtl is
--        port (
--            TMP_SCL : inout STD_LOGIC;
--            TMP_SDA : inout STD_LOGIC;
--            
--            TEMP_O : out STD_LOGIC_VECTOR(16-1 downto 0);
--            RDY_O : out STD_LOGIC;
--            ERR_O : out STD_LOGIC;
--            
--            CLK_I : in STD_LOGIC;
--            SRST_I : in STD_LOGIC
--        );
--    end component;
--    for TempSensorCtl_0 : TempSensorCtl use entity work.TempSensorCtl;
    signal test_scl, test_sda, test_rdy, test_err, test_clk, test_srst: std_logic;
    signal test_temp : std_logic_vector(16-1 downto 0);
	signal dbg_1 : std_logic;

    begin
--        TempSensorCtl_0: TempSensorCtl 
--            port map(
--                TMP_SCL => test_scl,
--                TMP_SDA => test_sda,
--                TEMP_O => test_temp,
--                RDY_O => test_rdy,
--                ERR_O => test_err,
--                CLK_I => test_clk,
--                SRST_I => test_srst
--            );
	ADT_0: ADT7420
		port map(
			inout_sda => test_sda,
			inout_scl => test_scl,
			in_clk => test_clk,
			in_srst => test_srst,
			out_tmp => test_temp,
			out_err => test_err,
			out_rdy => test_rdy,
			dbg_1   => dbg_1
		);

    p_test_clk : process
    begin
        test_clk <= '0';
        wait for clk_period/2;
        test_clk <= '1';
        wait for clk_period/2;
    end process p_test_clk;

    p_stimuli: process 
    begin
        test_sda <= 'H';
        test_scl <= 'H';
        test_srst <= '0';
        wait for clk_period;
        test_srst <= '1';
        wait for clk_period;
		assert false report "TSCL_CYCLES " & time'image(clk_period) severity warning;
        wait for  2* ((2+TSCL_CYCLES) * clk_period);
		wait on dbg_1;
        assert_byte(x"96", test_sda); -- device address + write
        simulate_ack(test_sda);
        assert_byte(x"0B", test_sda); -- 0x0b id register address
        simulate_ack(test_sda);
        wait for (4 + TSCL_CYCLES) * clk_period; -- repeated start condition
        assert_byte(x"97", test_sda); -- device address + read
        simulate_ack(test_sda);
        simulate_byte(x"CB", test_sda); -- 0xcb id register content

        wait for  2* ((4+TSCL_CYCLES) * clk_period); -- stop and start condition
        assert_byte(x"96", test_sda); -- device address + write
        simulate_ack(test_sda);
        assert_byte(x"2F", test_sda); -- reset register address
        simulate_ack(test_sda);
        assert_byte(x"00", test_sda); -- write to reset register
        simulate_ack(test_sda);

        wait for (4 + TSCL_CYCLES) * clk_period; -- repeated start condition
        assert_byte(x"96", test_sda); -- device address + write
        simulate_ack(test_sda);
        assert_byte(x"03", test_sda); -- configuration register address
        simulate_ack(test_sda);
        assert_byte(x"01", test_sda); -- set to 16 bit mode
        simulate_ack(test_sda);

        for i in temp_patterns'range loop
            wait for (4 + TSCL_CYCLES) * clk_period; -- repeated start condition
            assert_byte(x"96", test_sda); -- device address + write
            simulate_ack(test_sda);
            assert_byte(x"00", test_sda); -- temp register register msb 
            simulate_ack(test_sda);
            wait for (4 + TSCL_CYCLES) * clk_period; -- repeated start condition
            assert_byte(x"97", test_sda); -- device address + read
            simulate_ack(test_sda);
            simulate_byte(temp_patterns(i).msb, test_sda); -- temperature msb
            assert_ack(test_sda);
            simulate_byte(temp_patterns(i).lsb, test_sda); -- temperature lsb
            
            assert test_temp = temp_patterns(i).temp report
                "bad temp value" severity error;
            wait for (4 + TSCL_CYCLES) * clk_period; -- master not ack state
        end loop;

        wait for 500 us;
        assert false report "test end" severity failure;
    end process p_stimuli;
end behaviour;
