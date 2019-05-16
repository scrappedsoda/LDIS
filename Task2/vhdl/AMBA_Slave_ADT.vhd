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
begin
	out_PREADY <= '1' when int_PREADY = '1' else 'Z';
	out_intpr <= int_PREADY;
--	out_intpr   : out std_logic;
	nrst <= not in_PRESETn;
--	TODO RST abhandlung in internen zuständn

--	-- FRO DEBUG
--	int_data(15 downto 0) <= x"4567";

	ASYNC: process (in_PENABLE, in_PCLK, in_PRESETn, adt_rdy, int_PREADY, state)
	begin
		if in_PRESETn = '0' then
			int_data <= (others =>'0');
			int_PREADY <= '0';
			state <= sts_idle;

		else
			case state is
				when sts_idle =>
					int_PREADY <= '0';
					if rising_edge(in_PENABLE) then
						state <= sts_eval;
					end if;
	
				when sts_eval =>
					if in_PSELx = '1' then
						if in_PWRITE = '1' then
							state <= sts_write;
						else
							state <= sts_read;
						end if;
					else
						state <= sts_idle;
					end if;
	
				when sts_write =>
					state <= sts_idle;
	
				when sts_read => 
					if in_PADDR = '0' then
						out_PRDATA <= int_data;
						int_PREADY <= '1';
					end if;
			end case;

			if rising_edge(adt_rdy) then
				int_data <= (others => '0');
				int_data(15 downto 0) <= adt_tmp;
			end if;
	
			if rising_edge(in_PCLK) then
				if int_PREADY = '1' then --state = sts_read or state = sts_write then
					state <= sts_idle;
				end if;

--				if in_PRESETn = '0' then
--					state <= sts_idle;
--				end if;
			end if;
		end if;


	end process ASYNC;

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



