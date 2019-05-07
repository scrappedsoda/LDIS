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
    constant clockfreq  : natural := 1000000;
    constant samples	: natural := 4;


	component AMBACtl
	generic (
		num_slaves : natural := 4;
		bus_size   : natural := 16;
		clockfreq  : natural := 1000000;
		samples	   : natural := 4
    );
	port (
		dbg_waitsmpl:inout natural;
		dbg_nstatm : out std_logic;
		in_PCLK	: in  std_logic;	-- system clk
		in_PRESETn	: in  std_logic;	-- system rst
		out_PADDR	: out std_logic;	-- APB Bridge
		out_PENABLE	: out std_logic;	-- APB Bridge
		out_PWRITE  : out std_logic;	-- APB Bridge
		out_PWDATA  : out std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		out_PSELx	: out std_logic_vector (num_slaves-1 downto 0);	-- APB Bridge
		in_PREADY  : in  std_logic;	-- slave interface 
		in_PRDATA  : in  std_logic_vector((bus_size*num_slaves)-1 downto 0);	-- slave interface 
		in_PSLVERR : in  std_logic 	-- slave interface 
	);
	end component;

	--  Specifies which entity is bound with the component.
	for AMBA_M0: AMBACtl use entity work.AMBACtl;

	signal dbg_waitsmpl : natural;
	signal dbg_nstatm : std_logic;

	signal clk		:std_logic := '0';	-- system clk
	signal PRESETn	:std_logic := '1';	-- system rst
	signal PADDR	:std_logic;	-- APB Bridge
	signal PENABLE	:std_logic;	-- APB Bridge
	signal PWRITE   :std_logic;	-- APB Bridge
	signal PWDATA   :std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	signal PSELx	:std_logic_vector (num_slaves-1 downto 0);	-- APB Bridge
	signal PREADY   :std_logic;	-- slave interface 
	signal PRDATA   :std_logic_vector((bus_size*num_slaves)-1 downto 0);	-- slave interface 
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
		dbg_waitsmpl => dbg_waitsmpl,
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
	put_data_slave(clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	wait for Tperiod;
	put_data_slave(clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	put_data_slave(clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	put_data_slave(clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	wait for 30*Tperiod;
	Finish <= '1';
	wait;
end process STIMULI;	


end behav;

