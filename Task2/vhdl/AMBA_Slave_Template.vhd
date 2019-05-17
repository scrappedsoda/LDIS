library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entity Amba_Slave is
generic (
	slave_num : natural := 4;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000;
	);
port (
	in_PCLK		: in  std_logic;	-- system clk
	in_PRESETn	: in  std_logic;	-- system rst

	in_PADDR	: in std_logic;	-- APB Bridge
	in_PENABLE	: in std_logic;	-- APB Bridge
	in_PWRITE   : in std_logic;	-- APB Bridge
	in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	in_PSELx	: in std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	out_PREADY	: out  std_logic;	-- slave interface 
	out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
	out_PSLVERR	: out  std_logic 	-- slave interface 
);
end Amba_Slave;


architecture Behaviour of Amba_Slave is

	type state_type_slave is (sts_idle, sts_read, sts_write);
	signal state : state_type_slave;

	signal int_data : std_logic_vector(bus_size-1 downto 0);
	signal enable_write	: std_logic;
	signal enable_read	: std_logic;
begin

enable_write <= in_PENABLE and in_PWRITE and in_PSELx;
enable_read  <= not in_PWRITE and in_PSELx;	-- data is read everytime to be ready on the first cycle

out_PREADY <= int_pready; --int_pready_read or int_pready_write;

-- register with the enable sigs as clock
WRITE: process(in_PRESETn, enable_write)
begin
	if in_PRESETn ='1' then
		int_data <= x"0000";

	elsif rising_edge(enable_write) then
		int_data <= in_PWDATA;
	end if;
end process WRITE;

-- register with the enable sigs as clock
READ: process(in_PRESETn, enable_read)
begin
	if in_PRESETn ='1' then
		int_data <= x"0000";

	elsif rising_edge(enable_read) then
		out_PRDATA <= int_data;

	end if;
end process WRITE;

-- process to forward the data to whatever module or to write into the read register
SFORWARD: process(in_PRESETn, in_PCLK)
begin

	if rising_edge(in_PCLK) then
		if enable_write or enable_read then
			int_pready <= '1';
		else 
			int_pready <= '0';
		end if; -- enable read or write

		-- here some logic to compare the data ins with the other registers and update them
	end if;
		
end process SFORWARD;





--ASYNC: process (in_PENABLE, in_PCLK, in_PRESETn)
--begin
--	if rising_edge (in_PENABLE) then	-- rising_edge penable
--		case in_PADDR is
--			when '0' =>
--				if in_PWDATA = '1' then
--					signal
--				else
--
--				end if;
--			when '1' =>
--				if in_PWDATA = '1' then
--					signal
--				else
--
--				end if;
--		end case; -- in_PADDR
--	end if;	
--	
--end process ASYNC;
end behaviour;



