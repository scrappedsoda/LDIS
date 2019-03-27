-------------------------------------------------------------------------------
--
-- DSP testbench
--
-------------------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sevseg_tb is
end sevseg_tb;

--
-------------------------------------------------------------------------------
--
architecture behav of sevseg_tb is

	constant Tperiod : time := 10 ns;

	--  Declaration of the component that will be instantiated.
	component sevenseg 
  		port (
in_clk			: in  std_logic;
in_vld			: in  std_logic;
in_tmp			: in  std_logic_vector((16-1) downto 0);

out_seg0		: out std_logic_vector((8-1) downto 0);
out_seg1		: out std_logic_vector((8-1) downto 0);
out_seg2		: out std_logic_vector((8-1) downto 0);
out_seg3		: out std_logic_vector((8-1) downto 0);
out_seg4		: out std_logic_vector((8-1) downto 0);
out_seg5		: out std_logic_vector((8-1) downto 0);
out_seg6		: out std_logic_vector((8-1) downto 0);
out_seg7		: out std_logic_vector((8-1) downto 0)
);
end component;

signal in_clk: std_logic := '0';
signal in_vld: std_logic;
signal in_tmp: std_logic_vector((16-1) downto 0) := x"0000";
signal dbg_seg0: std_logic_vector((8-1) downto 0);
signal dbg_seg1: std_logic_vector((8-1) downto 0);
signal dbg_seg2: std_logic_vector((8-1) downto 0);
signal dbg_seg3: std_logic_vector((8-1) downto 0);
signal dbg_seg4: std_logic_vector((8-1) downto 0);
signal dbg_seg5: std_logic_vector((8-1) downto 0);
signal dbg_seg6: std_logic_vector((8-1) downto 0);
signal dbg_seg7: std_logic_vector((8-1) downto 0);


	--  Specifies which entity is bound with the component.
	for uut: sevenseg use entity work.sevenseg;

	signal Finish : std_logic := '0';
begin

	in_clk <= not in_clk after Tperiod/2 when Finish /= '1' else '0';

uut: sevenseg port map ( in_clk   => in_clk,
in_vld   => in_vld,
in_tmp   => in_tmp,
out_seg0 => dbg_seg0,
out_seg1 => dbg_seg1,
out_seg2 => dbg_seg2,
out_seg3 => dbg_seg3,
out_seg4 => dbg_seg4,
out_seg5 => dbg_seg5,
out_seg6 => dbg_seg6,
out_seg7 => dbg_seg7
);

----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	wait for Tperiod;
	in_vld <= '1';
	-- F30 = 1111 0011 0000 = 1111 0
	in_tmp <= x"0F30";
	wait for Tperiod;
	in_tmp <= x"7FFF";
	wait for Tperiod;
	in_tmp <= x"0000";
	wait for Tperiod;
	in_tmp <= x"36A9";
	wait for Tperiod;
	in_tmp <= x"8000";
	wait for Tperiod;
	in_tmp <= x"FFFF";
	wait for Tperiod;
	in_tmp <= x"A409";
	wait for Tperiod;
	in_tmp <= x"C004";
	wait for Tperiod;
	in_tmp <= x"D99A";
	Finish <= '1';
	wait;
end process STIMULI;	

-----------------
-- test check
-----------------
CHECK: process(in_clk)
begin
end process CHECK;

end behav;
