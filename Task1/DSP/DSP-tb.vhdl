-------------------------------------------------------------------------------
--
-- DSP testbench
--
-------------------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.testbench_utils.all;

entity DSP_tb is
end DSP_tb;

--
-------------------------------------------------------------------------------
--
architecture behav of DSP_tb is

	constant Tperiod : time := 10 ns;
	shared variable testcase : integer range 0 to 100 := 0;

	--  Declaration of the component that will be instantiated.
	component DSP
  		port (
		in_clk  : in std_logic;
		in_rst  : in std_logic;
		in_drdy : in std_logic;
		in_err  : in std_logic;
		in_data : in std_logic_vector((16-1) downto 0);
		in_size : in std_logic_vector((3-1) downto 0);
		out_vld : out std_logic;
		out_avg : out std_logic_vector((16-1) downto 0);
		in_dbg_sw3 : in std_logic;
		dbg_ld2  : out std_logic;
		dbg_size : out std_logic_vector(7 downto 0);
		dbg_ptr : out std_logic_vector(5 downto 0)
		);
	end component;

	--  Specifies which entity is bound with the component.
	for DSP_0: DSP use entity work.DSP;

	signal idata : std_logic_vector((16-1) downto 0) := x"0000";
	signal size  : std_logic_vector((3-1) downto 0)  := "010";
	signal avg   : std_logic_vector((16-1) downto 0) := x"0000";
	signal drdy  : std_logic := '0';
	signal rst   : std_logic := '1';
	signal err   : std_logic := '0';
	signal vld   : std_logic;
	signal clk : std_logic := '0';
	signal dbg_ld2 : std_logic;
	signal dbg_size : std_logic_vector(7 downto 0);
	signal dbg_ptr :  std_logic_vector(5 downto 0);


	signal Finish : std_logic := '0';
begin

	clk <= not clk after Tperiod/2 when Finish /= '1' else '0';

	--  Component instantiation.
	DSP_0: DSP port map (
		in_clk  => clk,
		in_data => idata,
		in_drdy => drdy,
	 	in_size => size,
		in_rst  => rst,
		in_err  => err,
		out_vld => vld,
		out_avg => avg,
		in_dbg_sw3 => '0',
		dbg_ld2 => dbg_ld2,
		dbg_size => dbg_size,	
    	dbg_ptr => dbg_ptr
	);

----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	size <= "010";
	rst <= '0';
	wait for Tperiod;
	rst <= '1';
	wait for Tperiod/2;
	wait for Tperiod*2;
	put_data(x"0F30", idata, size, drdy);

	put_data(x"0F33", idata, size, drdy);
	wait for 2*Tperiod;
	put_data(x"0F32", idata, size, drdy);
	put_data(x"0F31", idata, size, drdy);
	wait for 5*Tperiod;
	put_data(x"0F34", idata, size, drdy);
	put_data(x"0F30", idata, size, drdy);
	put_data(x"0F31", idata, size, drdy);
	put_data(x"0F30", idata, size, drdy);

	put_data(x"7E20", idata, size, drdy);
	put_data(x"7E10", idata, size, drdy);
	put_data(x"7F30", idata, size, drdy);
	put_data(x"7F32", idata, size, drdy);
	put_data(x"7F31", idata, size, drdy);
	put_data(x"7F39", idata, size, drdy);
	put_data(x"7F37", idata, size, drdy);
	put_data(x"7F40", idata, size, drdy);
	put_data(x"7F39", idata, size, drdy);
	put_data(x"7F80", idata, size, drdy);
	size <= "100";
	put_data(x"0F30", idata, size, drdy);
	put_data(x"0F33", idata, size, drdy);
	put_data(x"0F32", idata, size, drdy);
	put_data(x"0F31", idata, size, drdy);
	put_data(x"0F34", idata, size, drdy);
	put_data(x"0F30", idata, size, drdy);
	put_data(x"0F31", idata, size, drdy);
	put_data(x"0F30", idata, size, drdy);
	wait for 1 us;

--	size <= x"04";
--	drdy <= '1';
--	idata <= x"0008";
--	wait for Tperiod;
--	drdy <= '0';
--	wait for 3*Tperiod;
--	wait for to_integer(unsigned(size))*Tperiod;
--	size <= x"04";
--	idata <= x"0001";
--	drdy <= '1';
--	wait for Tperiod;
--	drdy <= '0';
--	wait for to_integer(unsigned(size))*Tperiod;
--	idata <= x"000F";
--	drdy <= '1';
--	wait for Tperiod;
--	drdy <= '0';
--	wait for to_integer(unsigned(size))*Tperiod;
--	wait for 10*Tperiod;
--	size <= x"0F";
--	wait for Tperiod;
--	testcase := 0;
--	wait for Tperiod*20;
--	testcase :=2;
--	wait for Tperiod;
--	testcase :=0;
--	idata <= x"0000";
--	wait for Tperiod*100;
--	idata <= x"0001";
--	wait for Tperiod;
--	idata <= x"0002";
--
--	wait for Tperiod;
--	idata <= x"0003";
--
--	wait for Tperiod;
--	idata <= x"0004";
--	size <= x"02";
--	testcase := 3;
--	wait for Tperiod;
--	idata <= x"0005";
--	wait for Tperiod;
--	idata <= x"0006";
--	wait for Tperiod;
--	idata <= x"0008";
--	wait for Tperiod;
--	testcase := 4;
--	idata <= x"0009";
--	wait for Tperiod;
--	testcase := 0;
--	size <= x"03";
--	idata <= x"000A";
--	wait for Tperiod;
--	testcase := 5;
--	idata <= x"000B";
--	wait for Tperiod;
--	testcase := 0;
--	idata <= x"000C";
--	wait for Tperiod;
	

	Finish <= '1';
	wait;
end process STIMULI;	

-----------------
-- test check
-----------------
CHECK: process(clk)
begin
if rising_edge(clk) then
	case testcase is
		when 1 => assert (avg=x"0008") report "Average testcase 1 funktioniert nicht" severity error;
		when 2 => assert (avg=x"0100") report "average testcase 2 funktioniret nicht" severity error;
		when 3 => assert (avg=x"0002") report "Average testcase 3 funktionirt nicht" severity error;
		when 4 => assert (avg=x"0009") report "Average testcase 4 funktionirt nicht" severity error;
		when others => null;
	end case;
end if;
end process CHECK;

end behav;
