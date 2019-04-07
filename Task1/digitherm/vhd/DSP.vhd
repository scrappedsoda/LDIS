-------------------------------------------------------------------------------
-- DSP which utilises a moving average filter
-- Author: Glinserer Andreas
-- MatrNr: 1525864
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- entity
--------------------------------------------------------------------------------
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
		in_size : in std_logic_vector((3-1) downto 0);
		-- the output
		out_vld : out std_logic;
		out_avg : out std_logic_vector((16-1) downto 0);
		in_dbg_sw3 : in std_logic;
		dbg_ld2  : out std_logic;
		dbg_size : out std_logic_vector(7 downto 0);
		dbg_ptr: out std_logic_vector(5 downto 0)
	);
end DSP;

--------------------------------------------------------------------------------
-- behavioral
--------------------------------------------------------------------------------
architecture behaviour of DSP is
	-- 3 bit for size determining -> 2**3 -1 values
	type FIFO is array(0 to 2**(2**3-1)) of std_logic_vector((16-1) downto 0);

	-- state machine declaration
	type states is (st_idle, st_add, st_div, st_read);
	signal state : states;

begin

-- process in which everything happens
STM : process (in_clk)
variable FIFO_Data : FIFO := (others =>(others => '0'));
variable step : integer := 0;
variable t_mean : integer := 0;
variable size: integer range 0 to 2**3-1:= 0;

begin

if rising_edge(in_clk) then
	dbg_size <= std_logic_vector(to_unsigned(size,8));

	if in_rst='0' then -- the reset is valid

		state <= st_idle;
		out_vld <= '1';
		out_avg <= x"0000";

	else -- the reset is not pressed

		if size /= to_integer(unsigned(in_size)) then -- size has changed
			size := to_integer(unsigned(in_size));

			FIFO_Data := (others => x"0000");			-- reset all the data
			state <= st_idle;							-- reset the state

		else -- the size sayed the same
	
			-- here begins the state machine
			case state is
				when st_idle =>
					if in_drdy /='1' then
						state <= st_read;
					end if;
					t_mean := 0;
					out_vld <= '1';
	
				when st_read =>
					if in_drdy ='1' then		-- wait for valid data
						-- shift and readin
						FIFO_Data(1 to FIFO_Data'length-1) := 
							FIFO_Data(0 to FIFO_Data'length-2);
						FIFO_Data(0) := in_data; 
						state <= st_add;
					end if;
	
				when st_add =>
					t_mean := t_mean + to_integer(unsigned(FIFO_Data(step)));

					if step >= 2**(size)-1 then -- only add until size
						state <= st_div;
					end if;
					step := step+1;
					dbg_ptr <= std_logic_vector(to_unsigned(step,6));
	
				when st_div =>
					out_vld <= '1';		-- data is now valid
					-- divison by shifting
					out_avg <= std_logic_vector(shift_right(to_unsigned(t_mean, out_avg'length),size));
					step := 0;			-- reset step for the next addition
					state <= st_idle;	-- go to idle state
			end case;
		end if; -- size
	end if; -- rst
end if; --clock

end process STM;
end behaviour;


