-------------------------------------------------------------------------------
--
-- DSP testbench
--
-------------------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.testbench_utils.all;

entity amba_tb is
end amba_tb;

--
-------------------------------------------------------------------------------
--
architecture behav of amba_tb is

	constant Tperiod : time := 10 ns;

	--  Declaration of the component that will be instantiated.
    constant num_slaves : natural := 4;
    constant bus_size   : natural := 16;
    constant clockfreq  : natural := 100_000_000;
    constant samples	: natural := 4;


	component AMBATherm
	generic (
	--	clockfreq : integer := 50_000_000;
	--	Samples   : integer := 1
    	num_slaves : natural := 4;
    	bus_size   : natural := 16;
    	clockfreq  : natural := 100_000_000;	-- 100 MHz
    	samples	: natural := 4
	);
	port (
		inout_sda : inout std_logic;
		inout_scl : inout std_logic;
		in_clk    : in std_logic;
		in_rst    : in std_logic;
		in_size   : in std_logic_vector((3-1) downto 0);
		out_seg		: out std_logic_vector((8-1) downto 0);
		out_an		: out std_logic_vector((8-1) downto 0);
		out_size_check 	: out std_logic_vector(2 downto 0);
		out_size		: out std_logic_vector(7 downto 0);
		out_adt_led 	: out std_logic;
		dbg_wait 	: out std_logic;
		dbg_wait2 	: out std_logic;
		dbg_ledsize 	: out std_logic_vector(1 downto 0)
	);
end digitherm;

	--  Specifies which entity is bound with the component.
	for AMBA_DT: digitherm use entity work.digitherm;

	signal dbg_waitsmpl : std_logic;
	signal dbg_nstatm : natural;

	signal clk		:std_logic := '0';	-- system clk
	signal PRESETn	:std_logic := '1';	-- system rst
	signal PADDR	:std_logic;	-- APB Bridge
	signal PENABLE	:std_logic;	-- APB Bridge
	signal PWRITE   :std_logic;	-- APB Bridge
	signal PWDATA   :std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	signal PSELx	:std_logic_vector (num_slaves-1 downto 0);	-- APB Bridge
	signal PREADY   :std_logic;	-- slave interface 
	signal PRDATA   :std_logic_vector((bus_size*num_slaves)-1 downto 0) := (others=>'0');	-- slave interface 
	signal PSLVERR  :std_logic; 	-- slave interface 

	signal Finish : std_logic := '0';

begin

	clk <= not clk after Tperiod/2 when Finish /= '1' else '0';

	--  Component instantiation.
	AMBA_M0: AMBACtl
	generic map (
		num_slaves => num_slaves,
		bus_size   => bus_size,
		clockfreq  => clockfreq,
		samples	   => samples	   
    )
	port map (
		dbg_wait => dbg_waitsmpl,
		dbg_nstatm => dbg_nstatm,
		in_PCLK	=> clk,
		in_PRESETn	=> PRESETn,
		out_PADDR	=> PADDR,
		out_PENABLE	=> PENABLE,
		out_PWRITE  => PWRITE,
		out_PWDATA  => PWDATA,
		out_PSELx	=> PSELx,
		in_PREADY  => PREADY,
		in_PRDATA  => PRDATA,
		in_PSLVERR => PSLVERR
	);

----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	PRESETn <= '0';
	wait for Tperiod;
	PRESETn <= '1';
    wait for 5*Tperiod;
	-- answer from the adt
	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	-- dsp_write
	put_data_slave(0, x"3243", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	-- dsp_read
	put_data_slave(8, x"3243", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	-- output_write
	put_data_slave(1, x"3243", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	wait for 30*Tperiod;
	Finish <= '1';
	wait;
end process STIMULI;	


end behav;

