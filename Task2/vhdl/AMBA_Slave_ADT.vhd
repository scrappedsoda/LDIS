-------------------------------------------------------------------------------
-- AMBA Slave Interface for the ADT
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
entity Amba_Slave_ADT is
generic (
	slave_num  : natural := 1;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000
	);
port (
	in_PCLK		: in  std_logic;	-- system clk
	in_PRESETn	: in  std_logic;	-- system rst
	-- debug signals
	out_intpr   : out std_logic;
	out_adt_led : out std_logic;
	-- needed for the i2c
	inout_scl : inout std_logic;
	inout_sda : inout std_logic;

	-- the amba apb interface
	in_PADDR	: in std_logic;	-- APB Bridge
	in_PENABLE	: in std_logic;	-- APB Bridge
	in_PWRITE   : in std_logic;	-- APB Bridge
	in_PSELx	: in std_logic; 
	in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	out_PREADY	: out  std_logic;	-- slave interface 
	out_PSLVERR	: out  std_logic; 	-- slave interface 
	out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0)	-- slave interface 

);
end Amba_Slave_ADT;


--------------------------------------------------------------------------------
-- behavioral
--------------------------------------------------------------------------------
architecture Behaviour of Amba_Slave_ADT is
	-- ADT instance
	component ADT7420 is
		generic (
			CLOCKFREQ : integer := clockfreq/1_000_000;
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

	signal int_PREADY 		: std_logic;
	signal int_data_read  	: std_logic_vector(bus_size-1 downto 0);
	signal int_data_write 	: std_logic_vector(bus_size-1 downto 0);

	-- signals for the adt instance
	signal adt_rdy : std_logic;
	signal adt_err : std_logic;
	signal adt_led : std_logic;
	signal adt_tmp : std_logic_vector(15 downto 0);
	signal nrst    : std_logic;

	-- signals to enable write and read to the apb registers
	signal enable_write : std_logic;
	signal enable_read  : std_logic;


begin

--------------------------------------------------------------------------------
-- the output signals
--------------------------------------------------------------------------------
out_PREADY <= '1' when int_PREADY = '1' else 'Z';
out_intpr <= int_PREADY;
nrst <= not in_PRESETn;

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
			if adt_rdy = '1' then
				-- if new data is there from the adt get it and save it into the
				-- read register
				int_data_read <= adt_tmp;
			else
				int_data_read <= int_data_read;
			end if; -- adt rdy
		end if; -- rst
	end if; -- rising clock

end process SFORWARD;

--------------------------------------------------------------------------------
-- ADT instantation
--------------------------------------------------------------------------------
ADT_0: ADT7420 generic map
(
	clockfreq => clockfreq/1_000_000,
	Samples => 1
)
port map (
	inout_sda => inout_sda,
	inout_scl => inout_scl,
	in_clk  => in_PCLK,
	in_srst => nrst,
	out_tmp => adt_tmp,
	out_rdy => adt_rdy,
	out_err => adt_err,
	out_led => out_adt_led 
);

end behaviour;



