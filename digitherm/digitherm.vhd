library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digitherm is
	generic (
		clockfreq : integer := 50_000_000;
		bus_clk   : integer := 400_000;
		samplet   : integer := 1
	);
	port (
		inout_sda : inout std_logic;
		inout_scl : inout std_logic;

		in_clk    : in std_logic;
		in_srst   : in std_logic;
		in_size   : in std_logic_vector((8-1) downto 0);
		
		out_seg		: out std_logic_vector((8-1) downto 0);
		out_an		: out std_logic_vector((8-1) downto 0);
	);
end digitherm;


architecture behaviour of digitherm is
	-- component declarations

	-- Sampler
	
	component ADT7420 is
		generic (
			CLOCKFREQ : natural := 50_000_000;
			bus_clk   : integer := 400_000;
			samplet   : integer := 1
		);
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

	-- DSP

	component DSP
  		port (
			in_clk  : in std_logic;
			in_size : in std_logic_vector((8-1) downto 0);
			in_data : in std_logic_vector((16-1) downto 0);
			out_avg  : out std_logic_vector((16-1) downto 0)
		);
	end component;

	-- Output to BCD

	component sevenseg 
		generic (
			clockf : integer := 50_000_000
		);
  		port (
			in_clk			: in  std_logic;
			in_vld			: in  std_logic;
			in_tmp			: in  std_logic_vector((16-1) downto 0);
			in_rst			: in  std_logic;
			
			out_seg		: out std_logic_vector((8-1) downto 0);
			out_an		: out std_logic_vector((8-1) downto 0)
		);
	end component;

	for BCD_0: sevenseg use entity work.sevenseg;
	for DSP_0: DSP use entity work.DSP;
	for ADT_0: ADT7420 use entity work.ADT7420;

	signal ADT_to_DSP_tmp : std_logic_vector((16-1) downto 0);
	signal ADT_to_DSP_rdy : std_logic;
	signal ADT_to_DSP_err : std_logic;

	signal DSP_to_BCD_tmp : std_logic_vector((16-1) downto 0);

begin

	ADT_0: ADT7420 generic map
	(
		CLOCKFREQ => clockfreq,
		bus_clk => bus_clk,
		samplet => samplet 
	)
	port map (
		inout_sda => inout_sda,
		inout_scl => inout_scl,

		in_clk  => in_clk,
		in_srst => in_srst,

		out_tmp => ADT_to_DSP_tmp,
		out_rdy => ADT_to_DSP_rdy,
		out_err => ADT_to_DSP_err
	);
	DSP_0: DSP port map (
		in_clk => in_clk,
		in_data => ADT_to_DSP_tmp,
	 	in_size => in_size,
		out_avg => DSP_to_BCD_tmp
	);
	
	BCD_0 : sevenseg generic map
	(
		clockfreq => clockfreq
	) 
	port map ( 
		in_clk   => in_clk,
		in_rst   => in_srst,
		in_vld   => '1',
		in_tmp   => DSP_to_BCD_tmp,
		out_seg  => out_seg,
		out_an   => out_an
	);

end behaviour;
