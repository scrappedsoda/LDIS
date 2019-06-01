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
--use work.testbench_utils.all;

entity amba_digitherm_tb is
end amba_digitherm_tb;

--
-------------------------------------------------------------------------------
--
architecture behav of amba_digitherm_tb is

	constant Tperiod : time := 10 ns;

	--  Declaration of the component that will be instantiated.
    constant num_slaves : natural := 4;
    constant bus_size   : natural := 16;
    constant clockfreq  : natural := 10_000;
    constant samples	: natural := 4;


	component AMBACtl
	generic (
		num_slaves : natural := 4;
		bus_size   : natural := 16;
		clockfreq  : natural := 1000000;
		samples	   : natural := 4
    );
	port (
		dbg_wait   : out std_logic;
		dbg_wait2: out std_logic;
		dbg_ledsize:out std_logic_vector(2 downto 0);
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

	component AMBADSPSlave
	generic (
		slave_num : natural := 2;
		bus_size   : natural := 16;
		clockfreq  : natural := 1000000
		);
	port (
		in_PCLK		: in std_logic;	-- system clk
		in_PRESETn	: in std_logic;	-- system rst
	
		in_PADDR	: in std_logic;	-- APB Bridge
		in_PENABLE	: in std_logic;	-- APB Bridge
		in_PWRITE   : in std_logic;	-- APB Bridge
		in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		in_PSELx	: in std_logic;
		out_PREADY	: out  std_logic;	-- slave interface 
		out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
		out_PSLVERR	: out  std_logic 	-- slave interface 
	);
	end component;

	component AMBABCDSlave
	generic (
		slave_num : natural := 3;
		bus_size   : natural := 16;
		clockfreq  : natural := 1000000
		);
	port (
		in_PCLK		: in std_logic;	-- system clk
		in_PRESETn	: in std_logic;	-- system rst
	
		in_PADDR	: in std_logic;	-- APB Bridge
		in_PENABLE	: in std_logic;	-- APB Bridge
		in_PWRITE   : in std_logic;	-- APB Bridge
		in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		in_PSELx	: in std_logic;
		out_PREADY	: out  std_logic;	-- slave interface 
		out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
		out_PSLVERR	: out  std_logic; 	-- slave interface 
		out_seg 	: out std_logic_vector(7 downto 0);
		out_an  	: out std_logic_vector(7 downto 0)
	);
	end component;

	component AMBASwitchSlave is
	generic (
		slave_num : natural := 4;
		bus_size   : natural := 16;
		clockfreq  : natural := 1000000
		);
	port (
		in_PCLK		: in  std_logic;	-- system clk
		in_PRESETn	: in  std_logic;	-- system rst
	
		in_size 	: in std_logic_vector(2 downto 0);
	
		in_PADDR	: in std_logic;	-- APB Bridge
		in_PENABLE	: in std_logic;	-- APB Bridge
		in_PWRITE   : in std_logic;	-- APB Bridge
		in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		in_PSELx	: in std_logic; -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	--	in_PSELx	: in std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
		out_PREADY	: out  std_logic;	-- slave interface 
		out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
		out_PSLVERR	: out  std_logic 	-- slave interface 
	);
	end component;



	--  Specifies which entity is bound with the component.
	for AMBA_M0: AMBACtl use entity work.AMBACtl;
	for AMBA_S1: AMBAADTSlave use entity work.Amba_Slave_ADT_stub;
	for AMBA_S2: AMBADSPSlave use entity work.Amba_Slave_DSP;
	for AMBA_S3: AMBABCDSlave use entity work.Amba_Slave_Output;
	for AMBA_S4: AMBASwitchSlave use entity work.Amba_Slave_Switch;

	signal dbg_wait :std_logic;
	signal dbg_wait2 :std_logic;
	signal dbg_ledsize : std_logic_vector(2 downto 0);

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

	signal SLV1 : std_logic;
	signal SLV2 : std_logic;
	signal SLV3 : std_logic;
	signal SLV4 : std_logic;
	signal DSLV1 : std_logic_vector(15 downto 0):= (others=>'0');
	signal DSLV2 : std_logic_vector(15 downto 0):= (others=>'0');
	signal DSLV3 : std_logic_vector(15 downto 0):= (others=>'0');
	signal DSLV4 : std_logic_vector(15 downto 0):= (others=>'0');

	signal Finish : std_logic := '0';

	signal inout_scl : std_logic;
	signal inout_sda : std_logic;

	signal out_seg : std_logic_vector(7 downto 0);
	signal out_an : std_logic_vector(7 downto 0);

	signal in_size : std_logic_vector(2 downto 0) := "100";

begin

	clk <= not clk after Tperiod/2 when Finish /= '1' else '0';
--	(SLV1, SLV2,SLV3,SLV4) <= PSELx;
	SLV1 <= PSELx(0);
	SLV2 <= PSELx(1);
	SLV3 <= PSELx(2);
	SLV4 <= PSELx(3);

	PRDATA(15 downto 0) <= DSLV1;
	PRDATA(31 downto 16) <= DSLV2;
	PRDATA(47 downto 32) <= DSLV3;
	PRDATA(63 downto 48) <= DSLV4;
--	DSLV1 <= PRDATA(15 downto 0);
--	DSLV2 <= PRDATA(31 downto 16);
--	DSLV3 <= PRDATA(47 downto 32);
--	DSLV4 <= PRDATA(63 downto 48);

	--  Component instantiation.
	AMBA_M0: AMBACtl
	generic map (
		num_slaves => num_slaves,
		bus_size   => bus_size,
		clockfreq  => clockfreq,
		samples	   => samples	   
    )
	port map (
		dbg_wait => dbg_wait,
		dbg_wait2 => dbg_wait2,
		dbg_ledsize => dbg_ledsize,
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
	in_PSELx			=> SLV1, 
	out_PREADY			=> PREADY,
	out_PRDATA			=> DSLV1,
	out_PSLVERR			=> PSLVERR
	);

	AMBA_S2: AMBADSPSlave
	generic map (
		slave_num 	=> 2,
		bus_size  	=>  bus_size,
		clockfreq 	=>  clockfreq
		)
	port map (
		in_PCLK		=> clk,
		in_PRESETn	=> PRESETn,
	
		in_PADDR			=> PADDR,
		in_PENABLE			=> PENABLE,
		in_PWRITE   		=> PWRITE,
		in_PWDATA   		=> PWDATA,
		in_PSELx			=> SLV2, 
		out_PREADY			=> PREADY,
		out_PRDATA			=> DSLV2,
		out_PSLVERR			=> PSLVERR
	);

	AMBA_S3: AMBABCDSlave
	generic map (
		slave_num  => 3,
		bus_size   => bus_size,
		clockfreq  => clockfreq
		)
	port map (
		in_PCLK		=> clk,
		in_PRESETn	=> PRESETn,
	
		in_PADDR			=> PADDR,
		in_PENABLE			=> PENABLE,
		in_PWRITE   		=> PWRITE,
		in_PWDATA   		=> PWDATA,
		in_PSELx			=> SLV3, 
		out_PREADY			=> PREADY,
		out_PRDATA			=> DSLV3,
		out_PSLVERR			=> PSLVERR,
	-- the outputs to the bcd
		out_seg		=> out_seg,
		out_an 		=> out_an
	);

	AMBA_S4: AMBASwitchSlave 
	generic map (
		slave_num  => 4,
		bus_size   => bus_size,
		clockfreq  => clockfreq
		)
	port map (
		in_PCLK		=> clk,
		in_PRESETn	=> PRESETn,
	                                   
		in_size 	=> in_size,	
	                		
		in_PADDR			=> PADDR,
		in_PENABLE			=> PENABLE,
		in_PWRITE   		=> PWRITE,
		in_PWDATA   		=> PWDATA,
		in_PSELx			=> SLV4, 
		out_PREADY	        => PREADY,
		out_PRDATA	        => DSLV4,
		out_PSLVERR	        => PSLVERR
	);



----------------------
-- stimuli generator
----------------------
STIMULI: process
begin
	PRESETn <= '0';
--	PENABLE <= '0';
	wait for 3*Tperiod;
	PRESETn <= '1';
    wait for 5*Tperiod;

--	put_data_master(x"D555", '1',"0100", '0', clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA, PADDR);
--	put_data_master(x"D555", '1',"0100", '0', clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA, PADDR);
--	put_data_master(x"D555", '1',"0100", '0', clk, PENABLE, PWRITE, PWDATA, PSELx, PREADY, PRDATA, PADDR);

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
	wait for 30000*Tperiod;
	Finish <= '1';
	wait;
end process STIMULI;	


end behav;

