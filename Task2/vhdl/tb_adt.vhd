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

entity amba_adt_tb is
end amba_adt_tb;

--
-------------------------------------------------------------------------------
--
architecture behav of amba_adt_tb is

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
		dbg_nstatm : inout natural;
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

	component AMBAADTSlave
	generic (
		slave_num : natural := 1;
--		num_slaves: natural := 4;
		bus_size   : natural := 16;
		clockfreq  : natural := 1000000
		);
	port (
		in_PCLK		: in  std_logic;	-- system clk
		in_PRESETn	: in  std_logic;	-- system rst
	
		inout_scl : inout std_logic;
		inout_sda : inout std_logic;
	
		in_PADDR	: in std_logic;	-- APB Bridge
		in_PENABLE	: in std_logic;	-- APB Bridge
		in_PWRITE   : in std_logic;	-- APB Bridge
		in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		in_PSELx	: in std_logic; --std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
		out_PREADY	: out  std_logic;	-- slave interface 
		out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
		out_PSLVERR	: out  std_logic 	-- slave interface 
	);
	end component;





	--  Specifies which entity is bound with the component.
--	for AMBA_M0: AMBACtl use entity work.AMBACtl;
	for AMBA_S1: AMBAADTSlave use entity work.Amba_Slave_ADT;
	signal dbg_waitsmpl : natural;
	signal dbg_nstatm : natural;

	signal clk		:std_logic := '0';	-- system clk
	signal PRESETn	:std_logic := '1';	-- system rst
	signal PADDR	:std_logic;	-- APB Bridge
	signal PENABLE	:std_logic;	-- APB Bridge
	signal PWRITE   :std_logic;	-- APB Bridge
	signal PWDATA   :std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	signal PSELx	:std_logic_vector(num_slaves-1 downto 0) := "0000";
	signal PREADY   :std_logic;	-- slave interface 
	signal PRDATA   :std_logic_vector((bus_size*num_slaves)-1 downto 0) := (others=>'0');	-- slave interface 
	signal PSLVERR  :std_logic; 	-- slave interface 

	signal Finish : std_logic := '0';

	signal inout_scl : std_logic;
	signal inout_sda : std_logic;
begin

	clk <= not clk after Tperiod/2 when Finish /= '1' else '0';

	--  Component instantiation.
--	AMBA_M0: AMBACtl
--	generic map (
--		num_slaves => num_slaves,
--		bus_size   => bus_size,
--		clockfreq  => clockfreq,
--		samples	   => samples	   
--    )
--	port map (
--		dbg_waitsmpl => dbg_waitsmpl,
--		dbg_nstatm => dbg_nstatm,
--		in_PCLK	=> clk,
--		in_PRESETn	=> PRESETn,
--		out_PADDR	=> PADDR,
--		out_PENABLE	=> PENABLE,
--		out_PWRITE  => PWRITE,
--		out_PWDATA  => PWDATA,
--		out_PSELx	=> PSELx,
--		in_PREADY  => PREADY,
--		in_PRDATA  => PRDATA,
--		in_PSLVERR => PSLVERR
--	);
	--adt_slave <= PSELx(1);
	AMBA_S1: AMBAADTSlave
	generic map (
		slave_num => 1,
		bus_size  => bus_size,
		clockfreq => clockfreq
	)
	port map (
	in_PCLK 		=> clk,
	in_PRESETn			=> PRESETn,

	inout_scl  		=> inout_scl,
	inout_sda  		=> inout_sda,

	in_PADDR			=> PADDR,
	in_PENABLE			=> PENABLE,
	in_PWRITE   		=> PWRITE,
	in_PWDATA   		=> PWDATA,
	in_PSELx			=> '1', 
	out_PREADY			=> PREADY,
	out_PRDATA			=> PRDATA(15 downto 0),
	out_PSLVERR			=> PSLVERR
	);
----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	PRESETn <= '0';
	PENABLE <= '0';
	wait for Tperiod;
	PRESETn <= '1';
    wait for 5*Tperiod;
	put_data_master(x"AAAA", '0',"0001", '0', clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA, PADDR);
	Finish <= '1';
--	-- answer from the adt
--	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	-- dsp_write
--	put_data_slave(0, x"3243", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	-- dsp_read
--	put_data_slave(8, x"3243", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	-- output_write
--	put_data_slave(1, x"3243", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
--	put_data_slave(0, x"328A", clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA);
	wait for 30*Tperiod;
	Finish <= '1';
	wait;
end process STIMULI;	


end behav;

