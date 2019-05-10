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
						delay : natural;
						byte : std_logic_vector((16-1) downto 0);
						signal CLK : in std_logic;
						signal PENABLE : in std_logic;
						signal PWRITE : in std_logic;
						signal PWDATA : in std_logic_vector(bus_size-1 downto 0);
						signal PSELx : in std_logic_vector(num_slaves -1 downto 0);
						signal PREADY : out std_logic;
						signal PRDATA : out std_logic_vector((bus_size*num_slaves)-1 downto 0));

	procedure put_data_master(
						byte : std_logic_vector((16-1) downto 0);
						RW : std_logic;	
						slave: std_logic_vector((4-1) downto 0);
						addr : std_logic;
						signal CLK 		: in std_logic;
						signal PENABLE 	: out std_logic;
						signal PWRITE 	: out std_logic;
						signal PWDATA 	: out std_logic_vector(bus_size-1 downto 0);
						signal PSELx 	: out std_logic_vector(num_slaves -1 downto 0);
						signal PREADY 	: in std_logic;
						signal PRDATA 	: in std_logic_vector((bus_size*num_slaves)-1 downto 0);
						signal PADDR 	: out std_logic);

end package testbench_utils;

package body testbench_utils  is
	procedure put_data_slave(
						delay : natural;
						byte : std_logic_vector((16-1) downto 0);
						signal CLK : in std_logic;
						signal PENABLE : in std_logic;
						signal PWRITE : in std_logic;
						signal PWDATA : in std_logic_vector(bus_size-1 downto 0);
						signal PSELx : in std_logic_vector(num_slaves -1 downto 0);
						signal PREADY : out std_logic;
						signal PRDATA : out std_logic_vector((bus_size*num_slaves)-1 downto 0)) is
	begin
		wait until rising_edge(PENABLE);
		wait for delay*clk_period;
		if PENABLE = '1' then
			if (PWRITE = '0') then	-- in case of read send data back
				case PSELx is
					when "0001" =>
						PRDATA(15 downto 0) <= byte;
					when "0010" =>
						PRDATA(31 downto 16) <= byte;
					when "0100" =>
						PRDATA(47 downto 32) <= byte;
					when "1000" =>
						PRDATA(50 downto 48) <= byte(2 downto 0);
					when others => null;
				end case;
			end if;
			PREADY <= '1';
		end if;
		wait until rising_edge(CLK); --Tperiod;
		PREADY <= '0';
--  		PRDATA <= (others => '0');		

	end put_data_slave;

	procedure put_data_master(
						byte : std_logic_vector((16-1) downto 0);
						RW : std_logic;	
						slave: std_logic_vector((4-1) downto 0);
						addr : std_logic;
						signal CLK 		: in std_logic;
						signal PENABLE 	: out std_logic;
						signal PWRITE 	: out std_logic;
						signal PWDATA 	: out std_logic_vector(bus_size-1 downto 0);
						signal PSELx 	: out std_logic_vector(num_slaves -1 downto 0);
						signal PREADY 	: in std_logic;
						signal PRDATA 	: in std_logic_vector((bus_size*num_slaves)-1 downto 0);
						signal PADDR 	: out std_logic) is

	begin
		PSELx <= slave;
		PWRITE<= RW;
		PWDATA <= byte;
		PADDR <= addr;
		wait until rising_edge(CLK);
		PENABLE <= '1';
--		wait until rising_edge(PREADY);
		wait until PREADY='Z';
--		wait until falling_edge(PREADY);
		PENABLE <= '0';
		PSELx <= "0000";
		

	end put_data_master;

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
