-- not tested

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use std.textio.all; -- Imports the standard textio package.
-----------------
-- entity
-----------------
entity DSP is
	port (
		-- everywhere
		in_clk  : in std_logic;
		in_rst  : in std_logic;
		-- from the ADT
		in_drdy : in std_logic;
		in_err  : in std_logic;
		in_data : in std_logic_vector((16-1) downto 0);
		-- from somewhere else
		in_size : in std_logic_vector((8-1) downto 0);
		-- the output
		out_vld : out std_logic;
		out_avg : out std_logic_vector((16-1) downto 0);
		in_dbg_sw3 : in std_logic;
		dbg_ld2  : out std_logic;
		dbg_size : out std_logic_vector(7 downto 0);
		dbg_ptr: out std_logic_vector(5 downto 0)
	);
end DSP;

-----------------
-- behaviour
-----------------
architecture behaviour of DSP is
	type FIFO is array(0 to 1023) of std_logic_vector((16-1) downto 0);
	shared variable FIFO_Data : FIFO := (others =>(others => '0'));

	signal ptr : integer := 0;
	shared variable size: integer range 0 to 1023 := 0;

	-- a detector to get only the rising edge of the adt
	signal detector : std_logic_vector((2-1) downto 0) := "00";
	signal data_tmp : std_logic_vector((16-1) downto 0) := x"0000";
	signal data_tmp2: std_logic_vector((16-1) downto 0) := x"0000";
	signal dbg_hlp : std_logic := '0';


	type states is (st_idle, st_add, st_div, st_read);
	signal state : states;
begin



STM : process (in_clk, in_drdy, in_size)
variable step : integer := 0;
variable t_mean : integer := 0;
begin


if rising_edge(in_drdy) then
	FIFO_Data(1 to 1023) := FIFO_Data(0 to 1022);
	FIFO_Data(0) := in_data;
	calc <= '1';	
	out_vld <= '0';
end if;


if rising_edge(in_clk) then
	dbg_size <= std_logic_vector(to_unsigned(size,8));
	dbg_ptr <= FIFO_Data(0)(5 downto 0);

	if in_rst ='0' then
		FIFO_Data := (others => (others => '0'));
	else
		if calc ='1' then
			calc <= '0';
			t_mean := 0;
			for I in 0 to size -1 loop
				t_mean := FIFO_Data(I) + t_mean;
			end loop;
			
			out_avg <= std_logic_vector(unsigned(t_mean/size));
			out_vld <= '1';
		end if; -- calc

	end if; -- rst
end if; -- clk



if size /= to_integer(unsigned(in_size)) then -- size has changed
	-- change the size accordingly
	if to_integer(unsigned(in_size)) = 0 then -- special case if size is zero
		size := 1;
	else
		size := to_integer(unsigned(in_size));
	end if;

	FIFO_Data := (others => x"0000"); -- reset all the data

end if; -- size

end process STM;

end behaviour;


