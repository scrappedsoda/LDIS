-------------------------------------------------------------------------------
--
-- 7-segment display
-- Source: http://vhdlguru.blogspot.co.at/2010/03/vhdl-code-for-bcd-to-7-segment-display.html
--
-------------------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
use std.textio.all; -- Imports the standard textio package.
-------------------------------------------------------------------------------
--
entity sevenseg is

	generic (
		clockfreq : integer := 50_000_000
	);
	port (
		-- everywhere
		in_clk			: in  std_logic;
		in_rst			: in  std_logic;

		-- from the DSP
		in_vld			: in  std_logic;
		in_tmp			: in  std_logic_vector((16-1) downto 0);

		-- to the bcd
		out_seg			: out std_logic_vector((8-1) downto 0);
		out_an			: out std_logic_vector((8-1) downto 0);

		dbg_seg0 : out std_logic_vector((8-1) downto 0);
		dbg_seg1 : out std_logic_vector((8-1) downto 0);
		dbg_seg2 : out std_logic_vector((8-1) downto 0);
		dbg_seg3 : out std_logic_vector((8-1) downto 0); -- this one has the comma point
		dbg_seg4 : out std_logic_vector((8-1) downto 0);
		dbg_seg5 : out std_logic_vector((8-1) downto 0);
		dbg_seg6 : out std_logic_vector((8-1) downto 0);
		dbg_seg7 : out std_logic_vector((8-1) downto 0)
	);

end sevenseg;
--
-------------------------------------------------------------------------------
--
architecture behavioral of sevenseg is
	-- to get a refresh rate of 100 hz for every bcd i divide clockfreq by 800
	-- the cntmax is full after 1.25ms (1/800hz)

	constant cntmax : integer := clockfreq/800;
	type T_DATA is array (0 to 10) of std_logic_vector((7-1) downto 0);

	type codout is array (0 to 7) of std_logic_vector((4-1) downto 0);
	signal cout : codout := (others => (others => '0'));

	constant VALUES : T_DATA := (	
									"0000001", -- 0
									"1001111", -- 1
									"0010010", -- 2
									"0000110", -- 3
									"1001100", -- 4
									"0100100", -- 5
									"0100000", -- 6
									"0001111", -- 7
									"0000000", -- 8
									"0000100", -- 9
									"1111110"  -- '-'
								);
begin

	parser: process (in_clk)
		variable whole_bin : std_logic_vector((8-1) downto 0);	-- whole binary value
		variable whole_tar : std_logic_vector((12-1) downto 0);	-- the target vector

		-- frac_bin needs to be bigger because of the transformation
		-- to get the values right. It needs to be so big to fit 
		-- 10000 in it. 10000 because of the calculation 
		-- frac_bin_max(dec) *10000/127 . The biggest number for
		-- frac_bin to reach is 127. 
		variable frac_bin  : std_logic_vector((16-1) downto 0); -- fractional binary
		variable frac_tar  : std_logic_vector((16-1) downto 0); -- fract target vect

		-- the decoded output
--		variable cout : codout := (others => (others => '0'));
		-- to debug
		variable l : line;

	begin

		whole_bin := (others => '0');
		whole_tar := (others => '0');
		frac_bin  := (others => '0');
		frac_tar  := (others => '0');

		if rising_edge(in_clk) then

			if in_rst='0' then
				cout(0) <= "0000"; 	
				cout(1) <= "0000"; 
				cout(2) <= "0000";
				cout(3) <= "0000";
				cout(4) <= "0000";
				cout(5) <= "0000";
				cout(6) <= "0000";
				cout(7) <= "0000";
			else
	
		
				if in_tmp(15) = '0' then
	
					whole_bin := in_tmp(14 downto 7);
					frac_bin(6 downto 0)  := in_tmp(6 downto 0);
				else
					-- basically i need to transform the negative number according to the 
					-- rules of two-complement. Thats why i need to add +1 to the part after
					-- the comma but not to the part before the comma
					whole_bin := not in_tmp(14 downto 7); --std_logic_vector(unsigned(not whole_bin));
					frac_bin(6 downto 0)  := std_logic_vector(unsigned(not in_tmp(6 downto 0))+1);
				end if;
	
				-- calculating the part before the comma using double dabble
				for I in 0 to whole_bin'length-1 loop 
					whole_tar := whole_tar(whole_tar'left-1 downto 0) & whole_bin(whole_bin'left);
					whole_bin := whole_bin(whole_bin'left-1 downto 0) & '0';
					
					if I /= whole_bin'length-1 then -- I dont want to add on the last iteration
						-- now check the target if there are any nibbles greater than 4
						if unsigned(whole_tar(11 downto 8)) > 4 then
							whole_tar(11 downto 8) := std_logic_vector(unsigned(whole_tar(11 downto 8))+3);
						end if;
						if unsigned(whole_tar(7 downto 4)) > 4 then
							whole_tar(7 downto 4) := std_logic_vector(unsigned(whole_tar(7 downto 4))+3);
						end if;
						if unsigned(whole_tar(3 downto 0)) > 4 then
							whole_tar(3 downto 0) := std_logic_vector(unsigned(whole_tar(3 downto 0))+3);
						end if;
					end if;
				end loop;
	
				-- calculating the part after the comma using double dabble
				-- but first i need to adjust the value by multiplicating 10000 and dividing 128
				frac_bin := std_logic_vector(to_unsigned(
					to_integer(unsigned(frac_bin))*10000/128,frac_bin'length));
	
				for I in 0 to frac_bin'length-1 loop 
					frac_tar:= frac_tar(frac_tar'left-1 downto 0) & frac_bin(frac_bin'left);
					frac_bin:= frac_bin(frac_bin'left-1 downto 0) & '0';
					
					if I /= frac_bin'length-1 then
						-- now check the target if there are any nibbles greater than 4
						if unsigned(frac_tar(15 downto 12)) > 4 then
							frac_tar(11 downto 8) := std_logic_vector(unsigned(frac_tar(11 downto 8))+3);
						end if;
						if unsigned(frac_tar(11 downto 8)) > 4 then
							frac_tar(11 downto 8) := std_logic_vector(unsigned(frac_tar(11 downto 8))+3);
						end if;
						if unsigned(frac_tar(7 downto 4)) > 4 then
							frac_tar(7 downto 4) := std_logic_vector(unsigned(frac_tar(7 downto 4))+3);
						end if;
						if unsigned(frac_tar(3 downto 0)) > 4 then
							frac_tar(3 downto 0) := std_logic_vector(unsigned(frac_tar(3 downto 0))+3);
						end if;
					end if;
				end loop;
	
	
				-- TODO add ifs for the left side to truncate leading zeros and give them a '-' if negative instead
				-- the outputs i have now are wrong .. they are good for debugging but i need vector(7 downto 0) for
				-- the real bcd -> map this with a const arr and indices from the calculated values
	
				if in_tmp(15) = '1' then
					cout(0) <= "1010";
				else
					cout(0) <= "0000";
				end if;
	
				cout(1) <= whole_tar(11 downto 8);
				cout(2) <= whole_tar(7 downto 4);
				cout(3) <= whole_tar(3 downto 0);
				cout(4) <= frac_tar(15 downto 12);
				cout(5) <= frac_tar(11 downto 8);
				cout(6) <= frac_tar(7 downto 4);
				cout(7) <= frac_tar(3 downto 0);
	
				
				dbg_seg0 <= "0000"&cout(0); --VALUES(to_integer(unsigned(cout(0)))) & '1';
				dbg_seg1 <= "0000"&cout(1); --VALUES(to_integer(unsigned(cout(1)))) & '1';
				dbg_seg2 <= "0000"&cout(2); --VALUES(to_integer(unsigned(cout(2)))) & '1';
				dbg_seg3 <= "0000"&cout(3); --VALUES(to_integer(unsigned(cout(3)))) & '0'; -- this one has the comma point
				dbg_seg4 <= "0000"&cout(4); --VALUES(to_integer(unsigned(cout(4)))) & '1';
				dbg_seg5 <= "0000"&cout(5); --VALUES(to_integer(unsigned(cout(5)))) & '1';
				dbg_seg6 <= "0000"&cout(6); --VALUES(to_integer(unsigned(cout(6)))) & '1';
				dbg_seg7 <= "0000"&cout(7); --VALUES(to_integer(unsigned(cout(7)))) & '1';
	
			end if;
		end if;

--		write(l, String'("test2"));
--		writeline(output,l);
	end process parser;

	-- this process does counting and outputting
	Outing : process (in_clk)
		variable counter : natural range 0 to cntmax := 0;
		variable ptr : natural range 0 to 7 := 0;

		variable l : line;
	begin


		if rising_edge(in_clk) then
			counter := counter + 1;
		end if;

		if counter = cntmax then
			counter := 0;	
			if ptr = 3 then
				out_seg <= VALUES(to_integer(unsigned(cout(ptr)))) & '0'; -- the one with the comma
			else
				out_seg <= VALUES(to_integer(unsigned(cout(ptr)))) & '1'; -- the one with the comma
			end if;
			out_an <= (others => '0');
			out_an(ptr) <= '1';

			-- ptr wird erhöht for next segment
			if ptr = 7 then
				ptr := 0;
			else
				ptr := ptr +1;
			end if;
		end if;

	end process Outing;

end behavioral;
--
-------------------------------------------------------------------------------
