library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.testbench_utils.all;

entity TempSensorCtl_tb is
end TempSensorCtl_tb;
architecture behaviour of TempSensorCtl_tb is
    constant clk_period: time := 1 ms;

    component TempSensorCtl is
        port (
            TMP_SCL : inout STD_LOGIC;
            TMP_SDA : inout STD_LOGIC;
            
            TEMP_O : out STD_LOGIC_VECTOR(16-1 downto 0);
            RDY_O : out STD_LOGIC;
            ERR_O : out STD_LOGIC;
            
            CLK_I : in STD_LOGIC;
            SRST_I : in STD_LOGIC
        );
    end component;
    for TempSensorCtl_0 : TempSensorCtl use entity work.TempSensorCtl;
    signal test_scl, test_sda, test_rdy, test_err, test_clk, test_srst: std_logic;
    signal test_temp : std_logic_vector(16-1 downto 0);

    begin
        TempSensorCtl_0: TempSensorCtl 
            port map(
                TMP_SCL => test_scl,
                TMP_SDA => test_sda,
                TEMP_O => test_temp,
                RDY_O => test_rdy,
                ERR_O => test_err,
                CLK_I => test_clk,
                SRST_I => test_srst
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
        test_srst <= '1';
        wait for clk_period;
        test_srst <= '0';
        wait for clk_period;
        wait for  2* ((2+TSCL_CYCLES) * clk_period);

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

        wait for 1000 ms;
        assert false report "test end" severity failure;
    end process p_stimuli;
end behaviour;
