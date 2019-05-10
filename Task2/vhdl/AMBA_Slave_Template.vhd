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
begin

ASYNC: process (in_PENABLE, in_PCLK, in_PRESETn)
begin
	if rising_edge (in_PENABLE) then	-- rising_edge penable
		case in_PADDR is
			when '0' =>
				if in_PWDATA = '1' then
					signal
				else

				end if;
			when '1' =>
				if in_PWDATA = '1' then
					signal
				else

				end if;
		end case; -- in_PADDR
	end if;	
	
end process ASYNC;
end behaviour;



