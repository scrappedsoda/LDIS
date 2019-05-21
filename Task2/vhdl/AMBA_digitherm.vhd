-------------------------------------------------------------------------------
-- digital thermometer top level design
-- Author: Glinserer Andreas
-- MatrNr: 1525864
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- entity
--------------------------------------------------------------------------------
entity amba_digitherm is
	generic (
	--	clockfreq : integer := 50_000_000;
	--	Samples   : integer := 1
    	num_slaves : natural := 4;
    	bus_size   : natural := 16;
    	clockfreq  : natural := 100_000_000;	-- 100 MHz
    	samples	: natural := 2
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
		dbg_ledsize 	: out std_logic_vector(2 downto 0)
	);
end amba_digitherm;

--------------------------------------------------------------------------------
-- behavior
--------------------------------------------------------------------------------
architecture behaviour of amba_digitherm is
-- component declarations
--    constant num_slaves : natural := 4;
--    constant bus_size   : natural := 16;
--    constant clockfreq  : natural := 50_000_000;
--    constant samples	: natural := 4;


	component AMBACtl
	generic (
		num_slaves : natural := 4;
		bus_size   : natural := 16;
		clockfreq  : natural := 50_000_000;
		samples	   : natural := 4
    );
	port (
		dbg_wait	: out std_logic;
		dbg_wait2 : out std_logic;
		dbg_ledsize: out std_logic_vector(2 downto 0);
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
		clockfreq  : natural := 50_000_000
		);
	port (
		out_intpr   : out std_logic;
		in_PCLK		: in  std_logic;	-- system clk
		in_PRESETn	: in  std_logic;	-- system rst
	
		inout_scl : inout std_logic;
		inout_sda : inout std_logic;
	
		in_PADDR	: in std_logic;	-- APB Bridge
		in_PENABLE	: in std_logic;	-- APB Bridge
		in_PWRITE   : in std_logic;	-- APB Bridge
		in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		in_PSELx	: in std_logic; 
		out_PREADY	: out  std_logic;	-- slave interface 
		out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
		out_PSLVERR	: out  std_logic; 	-- slave interface 
		out_adt_led 	: out std_logic
	);
	end component;

	component AMBADSPSlave
	generic (
		slave_num : natural := 2;
		bus_size   : natural := 16;
		clockfreq  : natural := 50_000_000
		);
	port (
		out_intpr   : out std_logic;
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
		out_size_check 	: out std_logic_vector(2 downto 0); 
		out_size		: out std_logic_vector(7 downto 0)
	);
	end component;

	component AMBABCDSlave
	generic (
		slave_num : natural := 2;
		bus_size   : natural := 16;
		clockfreq  : natural := 50_000_000
		);
	port (
		out_intpr   : out std_logic;
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
		clockfreq  : natural := 50_000_000
		);
	port (
		out_intpr   : out std_logic;
		in_PCLK		: in  std_logic;	-- system clk
		in_PRESETn	: in  std_logic;	-- system rst
	
		in_size 	: in std_logic_vector(2 downto 0);
	
		in_PADDR	: in std_logic;	-- APB Bridge
		in_PENABLE	: in std_logic;	-- APB Bridge
		in_PWRITE   : in std_logic;	-- APB Bridge
		in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
		in_PSELx	: in std_logic; -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
		out_PREADY	: out  std_logic;	-- slave interface 
		out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
		out_PSLVERR	: out  std_logic 	-- slave interface 
	);
	end component;

	signal out_PADDR	: std_logic;
	signal out_PENABLE	: std_logic;
	signal out_PWRITE   : std_logic;
	signal out_PWDATA   : std_logic_vector(bus_size-1 downto 0);
	signal out_PSELx	: std_logic_vector(num_slaves-1 downto 0);
	signal in_PREADY    : std_logic;
	signal in_PRDATA    : std_logic_vector((bus_size*num_slaves)-1 downto 0);
	signal in_PSLVERR   : std_logic;

	signal SLV1 : std_logic;
	signal SLV2 : std_logic;
	signal SLV3 : std_logic;
	signal SLV4 : std_logic;
	signal DSLV1 : std_logic_vector(15 downto 0):= (others=>'0');
	signal DSLV2 : std_logic_vector(15 downto 0):= (others=>'0');
	signal DSLV3 : std_logic_vector(15 downto 0):= (others=>'0');
	signal DSLV4 : std_logic_vector(15 downto 0):= (others=>'0');

	signal dbg_ledsize_temp: std_logic_vector(2 downto 0);
	signal out_intpr1 : std_logic;
	signal out_intpr2 : std_logic;
	signal out_intpr3 : std_logic;
	signal out_intpr4 : std_logic;

	--  Specifies which entity is bound with the component.
	for AMBA_M0: AMBACtl use entity work.AMBACtl;
	for AMBA_S1: AMBAADTSlave use entity work.Amba_Slave_ADT;
	for AMBA_S2: AMBADSPSlave use entity work.Amba_Slave_DSP;
	for AMBA_S3: AMBABCDSlave use entity work.Amba_Slave_Output;
	for AMBA_S4: AMBASwitchSlave use entity work.Amba_Slave_Switch;


begin

--	out_size(3) <= out_intpr4;
--	out_size(2) <= out_intpr3;
--	out_size(1) <= out_intpr2;
--	out_size(0) <= out_intpr1;

--	out_size(3 downto 0) <= out_PSELx;
--	out_size(5) <= out_PENABLE;

	SLV1 <= out_PSELx(0);
	SLV2 <= out_PSELx(1);
	SLV3 <= out_PSELx(2);
	SLV4 <= out_PSELx(3);

	in_PRDATA(15 downto 0) <= DSLV1;
	in_PRDATA(31 downto 16) <= DSLV2;
	in_PRDATA(47 downto 32) <= DSLV3;
	in_PRDATA(63 downto 48) <= DSLV4;

	dbg_ledsize <= dbg_ledsize_temp(2 downto 0);

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
		dbg_wait2 => open,
		dbg_ledsize => dbg_ledsize_temp,
		in_PCLK		=> in_clk,
		in_PRESETn	=> in_rst,
		out_PADDR	=> out_PADDR,
		out_PENABLE	=> out_PENABLE,
		out_PWRITE  => out_PWRITE,
		out_PWDATA  => out_PWDATA,
		out_PSELx	=> out_PSELx,
		in_PREADY   => in_PREADY,
		in_PRDATA   => in_PRDATA,
		in_PSLVERR  => in_PSLVERR
	);

	AMBA_S1: AMBAADTSlave
	generic map (
		slave_num => 1,
		bus_size  => bus_size,
		clockfreq => clockfreq
	)
	port map (
		out_intpr  		=> out_intpr1, 
		in_PCLK 		=> in_clk,
		in_PRESETn		=> in_rst,
	
		inout_scl  		=> inout_scl,
		inout_sda  		=> inout_sda,
	
		in_PADDR			=> out_PADDR,
		in_PENABLE			=> out_PENABLE,
		in_PWRITE   		=> out_PWRITE,
		in_PWDATA   		=> out_PWDATA,
		in_PSELx			=> SLV1, 
		out_PREADY			=> in_PREADY,
		out_PRDATA			=> DSLV1,
		out_PSLVERR			=> in_PSLVERR,
		out_adt_led 			=> out_adt_led
	);

	AMBA_S2: AMBADSPSlave
	generic map (
		slave_num 	=> 2,
		bus_size  	=>  bus_size,
		clockfreq 	=>  clockfreq
		)
	port map (
		out_intpr  		=> out_intpr2, 
		in_PCLK		=> in_clk,
		in_PRESETn	=> in_rst,
	
		in_PADDR			=> out_PADDR,
		in_PENABLE			=> out_PENABLE,
		in_PWRITE   		=> out_PWRITE,
		in_PWDATA   		=> out_PWDATA,
		in_PSELx			=> SLV2, 
		out_PREADY			=> in_PREADY,
		out_PRDATA			=> DSLV2,
		out_PSLVERR			=> in_PSLVERR,
		out_size_check 		=> out_size_check, 
		out_size			=> out_size
	);

	AMBA_S3: AMBABCDSlave
	generic map (
		slave_num  => 3,
		bus_size   => bus_size,
		clockfreq  => clockfreq
		)
	port map (
		out_intpr  		=> out_intpr3, 
		in_PCLK		=> in_clk,
		in_PRESETn	=> in_rst,
	
		in_PADDR			=> out_PADDR,
		in_PENABLE			=> out_PENABLE,
		in_PWRITE   		=> out_PWRITE,
		in_PWDATA   		=> out_PWDATA,
		in_PSELx			=> SLV3, 
		out_PREADY			=> in_PREADY,
		out_PRDATA			=> DSLV3,
		out_PSLVERR			=> in_PSLVERR,
		-- the outputs to the bcd
		out_seg		=> out_seg,
		out_an 		=> out_an
	);
	AMBA_S4: AMBASwitchSlave
	generic map (
		slave_num  => 3,
		bus_size   => bus_size,
		clockfreq  => clockfreq
		)
	port map (
		out_intpr  		=> out_intpr4, 
		in_PCLK		=> in_clk,
		in_PRESETn	=> in_rst,
		in_size 	=> in_size,
	
		in_PADDR			=> out_PADDR,
		in_PENABLE			=> out_PENABLE,
		in_PWRITE   		=> out_PWRITE,
		in_PWDATA   		=> out_PWDATA,
		in_PSELx			=> SLV4, 
		out_PREADY			=> in_PREADY,
		out_PRDATA			=> DSLV4,
		out_PSLVERR			=> in_PSLVERR
	);




end behaviour;
