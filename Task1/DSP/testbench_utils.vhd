library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

package testbench_utils is
    
    constant clk_period: time := 10 ns;
	procedure put_data(byte : std_logic_vector((16-1) downto 0);
						signal data : out std_logic_vector((16-1) downto 0);
						signal size : in std_logic_vector((3-1) downto 0);
						signal drdy : out std_logic);


end package testbench_utils;

package body testbench_utils  is
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
