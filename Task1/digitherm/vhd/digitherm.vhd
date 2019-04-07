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
entity digitherm is
	generic (
		clockfreq : integer := 50_000_000;
		Samples   : integer := 1
	);
	port (
		inout_sda : inout std_logic;
		inout_scl : inout std_logic;
		in_clk    : in std_logic;
		in_rst    : in std_logic;
		in_size   : in std_logic_vector((3-1) downto 0);
		out_seg		: out std_logic_vector((8-1) downto 0);
		out_an		: out std_logic_vector((8-1) downto 0);
		in_dbg_sw1 : in std_logic;
		in_dbg_sw2 : in std_logic;
		in_dbg_sw3 : in std_logic;
		out_led_adt : out std_logic;
		dbg_ld_dsp2 : out std_logic;
		dbg_size	: out std_logic_vector(7 downto 0);
		dbg_ptr 	: out std_logic_vector(5 downto 0)
	);
end digitherm;

--------------------------------------------------------------------------------
-- behavior
--------------------------------------------------------------------------------
architecture behaviour of digitherm is
-- component declarations
	-- Sampler
	component ADT7420 is
		generic (
			CLOCKFREQ : integer := 50;
			Samples   : integer := 1
		);
		port (
			inout_sda : inout std_logic;
			inout_scl : inout std_logic;
	
			in_clk  : in std_logic;
			in_srst : in std_logic;
	
			out_tmp : out std_logic_vector((16-1) downto 0);
			out_rdy : out std_logic;
			out_err : out std_logic;
			out_led : out std_logic
		);
	end component; -- ADT7420

	-- DSP
	component DSP
  		port (
		in_clk  : in std_logic;
		in_rst  : in std_logic;
		in_drdy : in std_logic;
		in_err  : in std_logic;
		in_size : in std_logic_vector((3-1) downto 0);
		in_data : in std_logic_vector((16-1) downto 0);
		out_vld : out std_logic;
		out_avg : out std_logic_vector((16-1) downto 0);
		in_dbg_sw3 : in std_logic;
		dbg_size: out std_logic_vector(7 downto 0);
		dbg_ld2 : out std_logic;
		dbg_ptr : out std_logic_vector(5 downto 0)
		);
	end component; -- DSP

	-- BCD
	component sevenseg 
		generic (
			clockfreq : integer := 50_000_000
		);
  		port (
			in_clk			: in  std_logic;
			in_rst			: in  std_logic;
			in_vld			: in  std_logic;
			in_tmp			: in  std_logic_vector((16-1) downto 0);
			out_seg		: out std_logic_vector((8-1) downto 0);
			out_an		: out std_logic_vector((8-1) downto 0)
		);
	end component; -- BCD

	-- make sure everything uses the right library
	for BCD_0: sevenseg use entity work.sevenseg;
	for DSP_0: DSP use entity work.DSP;
	for ADT_0: ADT7420 use entity work.ADT7420;


	-- signals to connect the things together
	signal ADT_to_DSP_tmp : std_logic_vector((16-1) downto 0);
	signal ADT_to_DSP_rdy : std_logic;
	signal ADT_to_DSP_err : std_logic;

	signal DSP_to_BCD_tmp : std_logic_vector((16-1) downto 0);
	signal DSP_to_BCD_vld : std_logic;

	-- ADT design uses active high reset standard
	signal nrst : std_logic;
begin

	nrst <= not in_rst;

	ADT_0: ADT7420 generic map
	(
		clockfreq => clockfreq/1_000_000,
		Samples => Samples
	)
	port map (
		inout_sda => inout_sda,
		inout_scl => inout_scl,
		in_clk  => in_clk,
		in_srst => nrst,
		out_tmp => ADT_to_DSP_tmp,
		out_rdy => ADT_to_DSP_rdy,
		out_err => ADT_to_DSP_err,
		out_led => out_led_adt 
	);

	DSP_0: DSP port map (
		in_clk  => in_clk,
		in_rst  => in_rst,
		in_drdy => ADT_to_DSP_rdy,
		in_err  => ADT_to_DSP_err,
		in_size => in_size,
		in_data => ADT_to_DSP_tmp,
		out_vld => DSP_to_BCD_vld,
		out_avg	=> DSP_to_BCD_tmp,
		in_dbg_sw3 => in_dbg_sw3,
		dbg_ld2 => dbg_ld_dsp2,
		dbg_size => dbg_size,
		dbg_ptr => dbg_ptr
	);
	
	BCD_0 : sevenseg generic map
	(
		clockfreq => clockfreq
	) 
	port map ( 
		in_clk   => in_clk,
		in_rst   => in_rst,
		in_vld   => DSP_to_BCD_vld,
		in_tmp   => DSP_to_BCD_tmp, 
		out_seg  => out_seg,
		out_an   => out_an
	);

end behaviour;
