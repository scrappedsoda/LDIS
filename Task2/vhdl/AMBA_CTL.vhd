library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entitiy AMBACtl is

generic (
	num_slaves : natural := 1;
	bus_size   : natural := 16;
port (
	in_PCLK	: in  std_logic;	-- system clk
	in_PRESETn	: in  std_logic;	-- system rst
	out_PADDR	: out std_logic;	-- APB Bridge
	out_PENABLE	: out std_logic;	-- APB Bridge
	out_PWRITE  : out std_logic;	-- APB Bridge
	out_PWDATA  : out std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	out_PSELx	: out std_logic_vector (integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	in_PREADY  : in  std_logic;	-- slave interface 
	in_PRDATA  : in  std_logic_vector(bus_size-1 downto 0);	-- slave interface 
	in_PSLVERR : in  std_logic 	-- slave interface 
);
end AMBACtl;

architecture Behaviour AMBACtl is

		-- state type definition
		type state_type_AMBA is (sta_idle, sta_setup, sta_access);
		signal state, nstate : state_type_AMBA;

		type state_type_Master is (stm_idle, stm_adt, stm_dsp, stm_out);
		signal state_m : state_type_Master;

		signal sig_read_adt : std_logic := '0';
		signal sig_read_adt : std_logic := '0';

		signal sig_addr : std_logic_vector(integer(floor(log2(real(num_slaves)))) downto 0);
begin

SYNC_PROC: process (in_PCLK)
begin
	if rising_edge(in_PCLK) then 	-- synchron
		if (in_PRESETn = '1') then	-- reset
			state <= sta_idle;

		else						-- no reset
			state <= nstate;
		end if;	-- reset if
	end if; -- clock if
end process SYNC_PROC;


OUTPUT_DECODE: process(state)
begin
end process OUTPUT_DECODE;

NEXT_STATE_DECODE: process (state)
begin
	nstate <= state;	-- default stay in current

	case (state) is
		when 
		-- THINK ABOUT THE STATE CHANGES AND TASK CHANGES AND HOW THEY OVERLAP
		-- (Same state changes in amba for different tasks)
end process NEXT_STATE_DECODE;


--state_change: process(in_PCLK)
--
--begin
--
--if rising_edge(in_PCLK) then
--	if in_PRESETn = '1' then
--		state <= st_idle;	
--	else	-- reset is not pressed
--		case state is		-- state diagram
--			when sta_idle =>	-- standard state
--				out_PSELX <= (others => '0');
--				out_PENABLE <= '0';
--				if wantWrite = '1' then
--					state <= sta_setup;
--				end if;
--
--			when sta_setup => -- here it asserts the appropiate select signals
--				out_PSELX <= sig_addr;
--				out_PENABLE <= '0';
--					
--			when sta_access => 
--				out_PSELX <= sig_addr;
--				out_PENABLE <= '1';
--				if 	
--							-- PENABLE is asserted here
--							-- address, write, select and write data
--							-- exit from access is contorlled by pready from slave
--							-- if pready is hold low bus remains in access state
--							-- if pready is high  by the slave access is exited and bus
--							-- returns to idle if no more transfers are required or
--							-- moves directly to setup if another transfer is wanted
--			when others =>
--				state <= st_idle;
--		end case;
--	end if;
--end if;
--
--end process state_change;

work_process: process(in_PCLK) then

begin

end process work_process;

end Behaviour;
