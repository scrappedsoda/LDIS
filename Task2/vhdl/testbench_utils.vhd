library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

package testbench_utils is
    
    constant clk_period: time := 10 ns;
    constant num_slaves : natural := 4;
    constant bus_size   : natural := 16;
    constant clockfreq  : natural := 1000000;
    constant samples	: natural := 4;
	procedure put_data(byte : std_logic_vector((16-1) downto 0);
						signal data : out std_logic_vector((16-1) downto 0);
						signal size : in std_logic_vector((3-1) downto 0);
						signal drdy : out std_logic);


	procedure put_data_slave(
						signal CLK : in std_logic;
						signal PENABLE : in std_logic;
						signal PWRITE : in std_logic;
						signal PWDATA : in std_logic_vector(bus_size-1 downto 0);
						signal PSELx : in std_logic_vector(num_slaves -1 downto 0);
						signal PREADY : out std_logic;
						signal PRDATA : out std_logic_vector((bus_size*num_slaves)-1 downto 0));

end package testbench_utils;

package body testbench_utils  is
	procedure put_data_slave(
						signal CLK : in std_logic;
						signal PENABLE : in std_logic;
						signal PWRITE : in std_logic;
						signal PWDATA : in std_logic_vector(bus_size-1 downto 0);
						signal PSELx : in std_logic_vector(num_slaves -1 downto 0);
						signal PREADY : out std_logic;
						signal PRDATA : out std_logic_vector((bus_size*num_slaves)-1 downto 0)) is
	begin
		wait until rising_edge(PENABLE);
		if PENABLE = '1' then
			if (PWRITE = '0') then	-- in case of read send data back
				PRDATA <= (others=>'1');
			end if;
			PREADY <= '1';
		end if;
		wait until rising_edge(CLK); --Tperiod;
		PREADY <= '0';
  		PRDATA <= (others => '0');		

	end put_data_slave;

	procedure put_data(byte : std_logic_vector((16-1) downto 0);
						signal data : out std_logic_vector((16-1) downto 0);
						signal size : in std_logic_vector((3-1) downto 0);
						signal drdy : out std_logic) is
	begin
		data <= byte;
		drdy <= '1';
		wait for clk_period;
		data <= x"0000";
		drdy <= '0';
		wait for (4+2**to_integer(unsigned(size)))*clk_period;
	end put_data;

end package body;
