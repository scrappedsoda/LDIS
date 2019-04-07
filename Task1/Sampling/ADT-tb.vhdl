-------------------------------------------------------------------------------
--
-- DSP testbench
--
-------------------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADT_tb is
end ADT_tb;

--
-------------------------------------------------------------------------------
--
architecture behav of ADT_tb is

	constant Tperiod : time := 10 ns;
	constant longTime : time := 1 ms;
	shared variable testcase : integer range 0 to 100 := 0;


component ADT7420 is
	Generic (CLOCKFREQ : natural := 100);
	port (
		inout_sda : inout std_logic;
		inout_scl : inout std_logic;

		in_clk  : in std_logic;
		in_srst : in std_logic;

		out_tmp : out std_logic_vector((16-1) downto 0);
		out_rdy : out std_logic;
		out_err : out std_logic
	);
end component;

for ADT_0: ADT7420 use entity work.ADT7420;

	--  Declaration of the component that will be instantiated.
	signal inout_sda : std_logic;
	signal inout_scl : std_logic;

	signal out_tmp : std_logic_vector((16-1) downto 0);
	signal out_rdy : std_logic;
	signal out_err : std_logic;

	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	signal Finish : std_logic := '0';
begin

	clk <= not clk after Tperiod/2 when Finish /= '1' else '0';

	--  Component instantiation.
	ADT_0: ADT7420 port map (
		inout_sda => inout_sda,
		inout_scl => inout_scl,

		in_clk  => clk,
		in_srst => rst,

		out_tmp => out_tmp,
		out_rdy => out_rdy,
		out_err => out_err
	);

----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	rst <= '1';
	wait for 10000*Tperiod;
	rst <= '0';
	wait for 100*longTime;

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
		when others => null;
	end case;
end if;
end process CHECK;

end behav;
