library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entity AMBACtl is
generic (
	num_slaves : natural := 4;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000;
	samples	   : natural := 4
	);
port (
	in_PCLK		: in  std_logic;	-- system clk
	in_PRESETn	: in  std_logic;	-- system rst
	out_PADDR	: out std_logic;	-- APB Bridge
	out_PENABLE	: out std_logic;	-- APB Bridge
	out_PWRITE  : out std_logic;	-- APB Bridge
	out_PWDATA  : out std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	out_PSELx	: out std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	in_PREADY	: in  std_logic;	-- slave interface 
	in_PRDATA	: in  std_logic_vector((bus_size*num_slaves)-1 downto 0);	-- slave interface 
	in_PSLVERR	: in  std_logic 	-- slave interface 
);
end AMBACtl;

architecture Behaviour of AMBACtl is
		constant SAMPLECNT : NATURAL := natural(ceil(real(clockfreq/samples)))*2;
		signal waitSample : natural range 0 to SAMPLECNT := 0;

		-- state type definition
		type state_type_AMBA is (sta_idle, sta_setup, sta_access);
		signal state, nstate : state_type_AMBA;

		type state_type_Master is (stm_idle, stm_adt, stm_dsp_read, stm_dsp_write, stm_out);
		signal state_m, nstate_m : state_type_Master;

		subtype slave_num is std_logic_vector(num_slaves-1 downto 0);
		constant ADT7420 : 	    slave_num := "0001";--std_logic_vector(0);
		constant DSP :		    slave_num := "0010";--std_logic_vector(1);
		constant OUTPUT_LED :   slave_num := "0100";--std_logic_vector(2); --to_unsigned(2, slave_num'len));   
		constant INPUT_SWITCH : slave_num := "1000";--std_logic_vector(3); --to_unsigned(3, slave_num'len));

		signal int_rec_data : std_logic_vector ((bus_size*num_slaves)-1 downto 0);

		alias ADT7420_RREG: 		std_logic_vector(15 downto 0) is int_rec_data(15 downto  0);
		alias DSP_RREG: 			std_logic_vector(15 downto 0) is int_rec_data(31 downto 16);
		alias OUTPUT_LED_RREG: 		std_logic_vector(15 downto 0) is int_rec_data(47 downto 32);
		alias INPUT_SWITCH_RREG: 	std_logic_vector( 2 downto 0) is int_rec_data(50 downto 48);

		signal sig_read_adt : std_logic := '0';
		signal int_want_transfer : std_logic := '0';
		signal int_data : std_logic_vector(bus_size-1 downto 0) := (others=>'0');
		signal int_write : std_logic := '0';
		signal int_slave_select : std_logic_vector(num_slaves-1 downto 0);
		signal int_addr_select : std_logic := '0';

--		signal sig_addr : std_logic_vector(integer(floor(log2(real(num_slaves)))) downto 0);
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
	if state = sta_idle then 		-- inidle
		out_PSELx <= (others => '0');
		out_PENABLE <= '0';

	elsif state = sta_setup then	-- in setup 
		out_PSELx   <= int_slave_select;
		out_PENABLE <= '0';
		out_PADDR   <= int_addr_select;
		out_PWDATA  <= int_data;
		out_PWRITE  <= int_write;
	elsif state = sta_access then		-- in access
		out_PSELx   <= int_slave_select;
		out_PENABLE <= '1';
		out_PADDR   <= int_addr_select;
		out_PWDATA  <= int_data;
		out_PWRITE  <= int_write;
		if int_write = '0' then
			if in_PREADY = '1' then
				int_rec_data <= in_PRDATA;
			end if;	-- in_pready
		end if;	-- int_write
	end if;
		
end process OUTPUT_DECODE;

NEXT_STATE_DECODE: process (state, int_want_transfer,in_PREADY)
begin
	nstate <= state;	-- default stay in current

	case (state) is
		when sta_idle =>
			if int_want_transfer = '1' then
				nstate <= sta_setup;
			end if;

		when sta_setup =>
			nstate <= sta_access;

		when sta_access =>
			if in_PREADY = '0' then
				nstate <= state;
			elsif in_PREADY = '1' and int_want_transfer ='1' then
				nstate <= sta_setup;
			else 
				nstate <= sta_idle;
			end if;

	end case;	-- state case
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

STATE_M_DECODE: process 
begin
	case state_m is
		when stm_idle =>
			null;

		when stm_adt =>
			int_want_transfer <= '1';
			int_slave_select <= ADT7420;
			int_addr_select <= '0';
			int_write <= '1';
			int_data <= (others => '0');
			-- deactivate the want_transfer when 
    		if state = sta_setup then
				int_want_transfer <= '0';
			end if;

		when stm_dsp_write =>
			int_want_transfer <= '1';
			int_slave_select <= DSP;
			int_addr_select <= '0';
			int_write <= '1';
			int_data <= ADT7420_RREG;
			-- deactivate the want_transfer when 
    		if state = sta_setup then
				int_want_transfer <= '0';
			end if;

		when stm_dsp_read =>
			int_want_transfer <= '1';
			int_slave_select <= DSP;
			int_addr_select <= '0';
			int_write <= '0';
			int_data <= (others => '0');
			-- deactivate the want_transfer when 
    		if state = sta_setup then
				int_want_transfer <= '0';
			end if;

		when stm_out =>
			int_want_transfer <= '1';
			int_slave_select <= OUTPUT_LED;
			int_addr_select <= '0';
			int_write <= '1';
			int_data <= DSP_RREG;
			-- deactivate the want_transfer when 
    		if state = sta_setup then
				int_want_transfer <= '0';
			end if;

		when others => null;
	-- state_m_next howto check if transac ended?
	end case;	-- state_m

end process STATE_M_DECODE;

STATE_M_NEXT: process

begin
	nstate_m <= state_m;	-- stay in current state
	case state_m is
		when stm_idle =>
			if waitSample = SAMPLECNT then
				nstate_m <= stm_adt;
			end if;	-- waitSample

		when stm_adt =>
			if state = sta_access and in_PREADY = '1' then
				nstate_m <= stm_dsp_write;
			end if;

		when stm_dsp_write =>
			if state = sta_access and in_PREADY = '1' then
				nstate_m <= stm_dsp_read;
			end if;

		when stm_dsp_read =>
			if state = sta_access and in_PREADY = '1' then
				nstate_m <= stm_dsp_read;
			end if;

		when stm_out =>
			if state = sta_access and in_PREADY = '1' then
				nstate_m <= stm_idle;
			end if;
		when others => 
			nstate_m <= stm_idle;
	end case;	-- state_m
end process STATE_M_NEXT;

-- process which counts to aliasing time
SAMPLEWAIT : process(in_PCLK)
begin
	if rising_edge(in_PCLK) then
		if state_m = stm_idle then
			if waitSample = SAMPLECNT then
				-- place for debug signals
			else
				waitSample <= waitSample+1;
			end if;
		else
			waitSample <= 0;
		end if;
	end if;
end process;

end Behaviour;
