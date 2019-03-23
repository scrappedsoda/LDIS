-------------------------------------------------------------------------------
--
-- DSP testbench
--
-------------------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
			in_size : in std_logic_vector((8-1) downto 0);
			in_data : in std_logic_vector((16-1) downto 0);
			out_avg  : out std_logic_vector((16-1) downto 0)
		);
	end component;

	--  Specifies which entity is bound with the component.
	for DSP_0: DSP use entity work.DSP;

	signal idata : std_logic_vector((16-1) downto 0) := x"0000";
	signal size  : std_logic_vector((8-1) downto 0)  := x"08";
	signal avg   : std_logic_vector((16-1) downto 0) := x"0000";

	signal clk : std_logic := '0';
	signal Finish : std_logic := '0';
begin

	clk <= not clk after Tperiod/2 when Finish /= '1' else '0';

	--  Component instantiation.
	DSP_0: DSP port map (
		in_clk => clk,
		in_data => idata,
	 	in_size => size,
		out_avg => avg
	);

----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	wait for Tperiod/4;
	size <= x"08";
	idata <= x"0008";
	wait for 8*Tperiod;
	testcase := 1;
	wait for 5*Tperiod;
	testcase := 0;
    idata <= x"0100";
	size <= x"0F";
	wait for Tperiod;
	testcase := 0;
	wait for Tperiod*20;
	testcase :=2;
	wait for Tperiod;
	testcase :=0;
	idata <= x"0000";
	wait for Tperiod*100;
	idata <= x"0001";
	wait for Tperiod;
	idata <= x"0002";

	wait for Tperiod;
	idata <= x"0003";

	wait for Tperiod;
	idata <= x"0004";
	size <= x"02";
	testcase := 3;
	wait for Tperiod;
	idata <= x"0005";
	wait for Tperiod;
	idata <= x"0006";
	wait for Tperiod;
	idata <= x"0008";
	wait for Tperiod;
	testcase := 4;
	idata <= x"0009";
	wait for Tperiod;
	testcase := 0;
	size <= x"03";
	idata <= x"000A";
	wait for Tperiod;
	testcase := 5;
	idata <= x"000B";
	wait for Tperiod;
	testcase := 0;
	idata <= x"000C";
	wait for Tperiod;
	

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
