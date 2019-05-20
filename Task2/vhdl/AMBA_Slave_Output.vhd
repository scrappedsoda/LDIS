-------------------------------------------------------------------------------
-- AMBA Slave Interface for the Output
-- Author: Glinserer Andreas
-- MatrNr: 1525864
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--------------------------------------------------------------------------------
-- entity
--------------------------------------------------------------------------------
entity Amba_Slave_Output is
generic (
	slave_num  : natural := 2;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000
	);
port (
	in_PCLK		: in std_logic;	-- system clk
	in_PRESETn	: in std_logic;	-- system rst
	-- debug signals
	out_intpr   : out std_logic;

	-- the amba apb interface
	in_PADDR	: in std_logic;	-- APB Bridge
	in_PENABLE	: in std_logic;	-- APB Bridge
	in_PWRITE   : in std_logic;	-- APB Bridge
	in_PSELx	: in std_logic;
	in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	out_PREADY	: out std_logic;	-- slave interface 
	out_PSLVERR	: out std_logic; 	-- slave interface 
	out_PRDATA	: out std_logic_vector((bus_size-1) downto 0);	-- slave interface 
	-- the outputs to the bcd
	out_seg		: out std_logic_vector((8-1) downto 0); 
	out_an 		: out std_logic_vector((8-1) downto 0)
);
end Amba_Slave_Output;


--------------------------------------------------------------------------------
-- behavioral
--------------------------------------------------------------------------------
architecture Behaviour of Amba_Slave_Output is
	-- BCD instance
	component sevenseg 
		generic (
			clockfreq : integer := 50_000_000
		);
  		port (
			in_clk		: in  std_logic;
			in_rst		: in  std_logic;
			in_vld		: in  std_logic;
			in_tmp		: in  std_logic_vector((16-1) downto 0);
			out_seg		: out std_logic_vector((8-1) downto 0);
			out_an		: out std_logic_vector((8-1) downto 0)
		);
	end component; -- BCD

	type state_type_slave is (sts_idle, sts_eval, sts_read, sts_write);
	signal state : state_type_slave;

	signal int_data : std_logic_vector(bus_size-1 downto 0);
	signal int_new_data : std_logic;
	signal int_rec_data : std_logic_vector(bus_size-1 downto 0);
	signal int_PREADY : std_logic;

	signal bcd_in_clk  : std_logic;
	signal bcd_in_rst  : std_logic;
	signal bcd_in_vld  : std_logic;
	signal bcd_in_tmp  : std_logic_vector(15 downto 0);
	signal bcd_out_seg : std_logic_vector(7 downto 0);
	signal bcd_out_an  : std_logic_vector(7 downto 0);

	signal enable_write : std_logic;
	signal enable_read  : std_logic;

	signal int_data_read  : std_logic_vector(bus_size-1 downto 0);
	signal int_data_write : std_logic_vector(bus_size-1 downto 0);
begin

--------------------------------------------------------------------------------
-- the output signals
--------------------------------------------------------------------------------
out_PREADY <= '1' when int_PREADY = '1' else 'Z';
out_intpr <= int_PREADY;
out_seg <= bcd_out_seg;
out_an <= bcd_out_an;

--------------------------------------------------------------------------------
-- the signals which control read and write the are exclusively
--------------------------------------------------------------------------------
enable_write <= in_PENABLE and in_PWRITE and in_PSELx;
enable_read  <= not in_PWRITE and in_PSELx;	-- data is read everytime to be ready on the first cycle

--------------------------------------------------------------------------------
-- register with the enable_write sig as clock
--------------------------------------------------------------------------------
WRITE: process(in_PRESETn, enable_write)
begin
	if in_PRESETn ='0' then
		int_data_write <= x"0000";
	elsif rising_edge(enable_write) then
		int_data_write <= in_PWDATA;
	end if;
end process WRITE;

--------------------------------------------------------------------------------
-- register with the enable_read sig as clock
--------------------------------------------------------------------------------
READ: process(in_PRESETn, enable_read)
begin
	if in_PRESETn ='0' then
		out_PRDATA <= x"0000";

	elsif rising_edge(enable_read) then
		out_PRDATA <= int_data_read;

	end if;
end process READ;

--------------------------------------------------------------------------------
-- process which determines the pready signal
--------------------------------------------------------------------------------
PREADYP: process(enable_write, enable_read)
begin
	if enable_write='1' or enable_read='1' then
		int_PREADY <= '1';
	else
		int_PREADY <= '0';
	end if;
end process PREADYP;

--------------------------------------------------------------------------------
-- process which forwards the data form the adt intance to the register
-- and vice versa
--------------------------------------------------------------------------------
SFORWARD: process(in_PRESETn, in_PCLK)
begin

	if rising_edge(in_PCLK) then
		if in_PRESETn = '0' then
			int_data_read <= x"0000";
		else
			if enable_write = '0' then
				bcd_in_vld <= '1';
				bcd_in_tmp <= int_data_write;
			else
				bcd_in_vld <= '0';
				bcd_in_tmp <= bcd_in_tmp;
			end if;
		end if; -- rst
	end if; -- rising clock

		
end process SFORWARD;

--------------------------------------------------------------------------------
-- output instantation
--------------------------------------------------------------------------------
BCD_0 : sevenseg generic map
(
	clockfreq => clockfreq
) 
port map ( 
	in_clk   => in_PCLK,
	in_rst   => in_PRESETn,
	in_vld   => bcd_in_vld,
	in_tmp   => bcd_in_tmp, 
	out_seg  => bcd_out_seg,
	out_an   => bcd_out_an
);

end behaviour;



