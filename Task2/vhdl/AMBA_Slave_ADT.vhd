library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entity Amba_Slave_ADT is
generic (
	slave_num : natural := 1;
--	num_slaves: natural := 4;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000
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
	in_PSELx	: in std_logic; -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
--	in_PSELx	: in std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	out_PREADY	: out  std_logic;	-- slave interface 
	out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
	out_PSLVERR	: out  std_logic; 	-- slave interface 
	out_adt_led : out std_logic
);
end Amba_Slave_ADT;


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

	type state_type_slave is (sts_idle, sts_read, sts_eval, sts_write);
	signal state : state_type_slave;

	signal int_data : std_logic_vector(bus_size-1 downto 0);
	signal int_PREADY : std_logic;
	signal nrst : std_logic;

	constant slave_select_check : std_logic_vector(3 downto 0) := "0001"; --(slave_num=>'1', others=>'0');

	signal adt_tmp : std_logic_vector(15 downto 0);
	signal adt_rdy : std_logic;
	signal adt_err : std_logic;
	signal adt_led : std_logic;


	signal enable_write : std_logic;
	signal enable_read  : std_logic;

	signal int_data_read  : std_logic_vector(bus_size-1 downto 0);
	signal int_data_write : std_logic_vector(bus_size-1 downto 0);

begin
	out_PREADY <= '1' when int_PREADY = '1' else 'Z';
	out_intpr <= int_PREADY;
--	out_intpr   : out std_logic;
	nrst <= not in_PRESETn;
--	TODO RST abhandlung in internen zuständn

--	-- FRO DEBUG
--	adt_tmp(15 downto 0) <= x"4567";
--	adt_rdy <= '1';


enable_write <= in_PENABLE and in_PWRITE and in_PSELx;
enable_read  <= not in_PWRITE and in_PSELx;	-- data is read everytime to be ready on the first cycle


-- register with the enable sigs as clock
WRITE: process(in_PRESETn, enable_write)
begin
	if in_PRESETn ='0' then
		int_data_write <= x"0000";
	elsif rising_edge(enable_write) then
		int_data_write <= in_PWDATA;
	end if;
end process WRITE;

-- register with the enable sigs as clock
READ: process(in_PRESETn, enable_read)
begin
	if in_PRESETn ='0' then
		out_PRDATA <= x"0000";

	elsif rising_edge(enable_read) then
		out_PRDATA <= int_data_read;

	end if;
end process READ;

PREADYP: process(enable_write, enable_read)
begin
	if enable_write='1' or enable_read='1' then
		int_PREADY <= '1';
	else
		int_PREADY <= '0';
	end if;
end process PREADYP;

-- process to forward the data to whatever module or to write into the read register
SFORWARD: process(in_PRESETn, in_PCLK)
begin

	if rising_edge(in_PCLK) then
		if in_PRESETn = '0' then
			int_data_read <= x"0000";
		else
			if adt_rdy = '1' then
				int_data_read <= adt_tmp;
			else
				int_data_read <= int_data_read;
			end if; -- adt rdy
		end if; -- rst
	end if; -- rising clock

--		if enable_write or enable_read then
--			int_pready <= '1';
--		else 
--			int_pready <= '0';
--		end if; -- enable read or write

		-- here some logic to compare the data ins with the other registers and update them
		
end process SFORWARD;



--	ASYNC: process (in_PENABLE, in_PCLK, in_PRESETn, adt_rdy, int_PREADY, state, in_PSELx, in_PWRITE, in_PADDR, int_data)
--	begin
--		if in_PRESETn = '0' then
--			int_data <= (others =>'0');
--			int_PREADY <= '0';
--			state <= sts_idle;
--
--		else
--			case state is
--				when sts_idle =>
--					int_PREADY <= '0';
--					if rising_edge(in_PENABLE) then
--						state <= sts_eval;
--					end if;
--	
--				when sts_eval =>
--					if in_PSELx = '1' then
--						if in_PWRITE = '1' then
--							state <= sts_write;
--						else
--							state <= sts_read;
--						end if;
--					else
--						state <= sts_idle;
--					end if;
--	
--				when sts_write =>
--					state <= sts_idle;
--	
--				when sts_read => 
--					if in_PADDR = '0' then
--						out_PRDATA <= int_data;
--						int_PREADY <= '1';
--					end if;
--			end case;
--
--			if rising_edge(adt_rdy) then
--				int_data <= (others => '0');
--				int_data(15 downto 0) <= adt_tmp;
--			end if;
--	
--			if rising_edge(in_PCLK) then
--				if int_PREADY = '1' then --state = sts_read or state = sts_write then
--					state <= sts_idle;
--				end if;
--
----				if in_PRESETn = '0' then
----					state <= sts_idle;
----				end if;
--			end if;
--		end if;
--
--
--	end process ASYNC;

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



