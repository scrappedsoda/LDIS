library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; -- Imports the standard textio package.
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
		in_size : in std_logic_vector((8-1) downto 0);

		-- from somewhere else
		in_data : in std_logic_vector((16-1) downto 0);

		-- the output
		out_vld : out std_logic;
		out_avg : out std_logic_vector((16-1) downto 0)
	);
end DSP;

-----------------
-- behaviour
-----------------
architecture behaviour of DSP is
	type FIFO is array(0 to 1023) of std_logic_vector((16-1) downto 0);
	shared variable FIFO_Data : FIFO := (others =>(others => '0'));

	shared variable ptr : integer range 0 to 1023 := 0;
	shared variable size: integer range 0 to 1023 := 0;

	-- a detector to get only the rising edge of the adt
	signal detector : std_logic_vector((2-1) downto 0) := "00";
begin

-- a process to get the rising edge in the detector
SYNC_PROC: process(in_clk)
	begin
		if rising_edge(in_clk) then
			detector(0) <= in_drdy;
			detector(1) <= detector(0);
		end if;
	end process SYNC_PROC;



-- the main process
DO: process(in_clk)
variable t_mean : integer := 0;
variable l : line;
begin

	t_mean := 0;

	if rising_edge(in_clk) then
		if detector(0) = '0' and detector(1) = '1' then
			size := to_integer(unsigned(in_size));
			if size=0 then
				size:=1;
			end if;
	
			if ptr=size then
				-- case ptr is equal to size
				-- inserting the data in the right place
				FIFO_Data(0 to 1022) := FIFO_Data(1 to 1023);
				FIFO_Data(ptr) := in_data;
				
			elsif ptr < size then 
				-- is the pointer smaller than the size we dont do the 
				-- shifting
				FIFO_Data(ptr) := in_data;
				ptr := ptr +1;
			elsif ptr > size then 
				-- if the pointer is bigger than the size we shift
				-- everything back instead
				FIFO_Data(0 to size) := FIFO_Data(ptr-size to ptr);
			end if; -- ptr 
	
			-- since the conversion can be done completely without 
			-- after comma values i will do it.
			-- ADC_code(in decimal) /128 for positive
			-- (ADC_code(in decimal) - 65535) / 128 for negative values

			-- calculating the floating mean
			for i in 0 to size loop
--				if FIFO_Data(i)(16) = '1' then
--						t_mean := t_mean+to_integer(signed
				t_mean := t_mean+to_integer(signed(FIFO_Data(i)));
				write(l, String'("the vals which get added up: " & integer'image(t_mean)));
				writeline(output, l);
			end loop;
			t_mean := t_mean/size;
			write(l, String'("Mean after division:" & integer'image(t_mean)));
			writeline(output, l);
	
			out_avg <= std_logic_vector(to_signed(t_mean ,out_avg'length));
		end if; -- detector
	end if; -- clk
end process DO;



end behaviour;


