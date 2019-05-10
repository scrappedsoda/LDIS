library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entity Amba_Slave_Switch is
generic (
	slave_num : natural := 1;
--	num_slaves: natural := 4;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000
	);
port (
	in_PCLK		: in  std_logic;	-- system clk
	in_PRESETn	: in  std_logic;	-- system rst

	in_size 	: in std_logic_vector(2 downto 0);

	in_PADDR	: in std_logic;	-- APB Bridge
	in_PENABLE	: in std_logic;	-- APB Bridge
	in_PWRITE   : in std_logic;	-- APB Bridge
	in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	in_PSELx	: in std_logic; -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
--	in_PSELx	: in std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	out_PREADY	: out  std_logic;	-- slave interface 
	out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
	out_PSLVERR	: out  std_logic 	-- slave interface 
);
end Amba_Slave_Switch;


architecture Behaviour of Amba_Slave_Switch is

	type state_type_slave is (sts_idle, sts_eval, sts_read, sts_write);
	signal state,nstate : state_type_slave;

	signal int_data : std_logic_vector(bus_size-1 downto 0);
	signal int_PREADY : std_logic;
	shared variable int_PREADY_t1 : std_logic;
	shared variable int_PREADY_t2 : std_logic;

	signal nrst : std_logic;

	constant slave_select_check : std_logic_vector(3 downto 0) := "0001"; --(slave_num=>'1', others=>'0');

	signal switch_state : std_logic_vector(2 downto 0);
begin
	out_PREADY <= '1' when int_PREADY = '1' else 'Z';
	
--	int_data <= in_PWDATA;
    NSTATE_DECODE: process(in_PENABLE, in_PCLK, state)
    begin
        case state is
            when sts_idle =>
                int_PREADY <= '0';
                if rising_edge(in_PENABLE) then
                    state <= sts_eval;
                end if;
        
            when sts_eval =>
                if in_PSELx = '1' then
                    if in_PWRITE = '1' then
                        state <= sts_write;
                    else
                        state <= sts_read;
                    end if;
                else
                    state <= sts_idle;
                end if;
                
            when sts_write =>
                null;   -- never happens with the switch
            when sts_read =>
                int_PREADY <= '1';
                out_PRDATA <= (others=>'0');
                out_PRDATA(2 downto 0) <= in_size;
        end case;   --state
        
        if rising_edge(in_PCLK) then
            if state = sts_read then
                state <= sts_idle;
            end if;
        end if;
    end process NSTATE_DECODE;
                
        
--        if rising_edge (in_PENABLE) then
--            if state = sts_idle;
--            state <= sts_eval;
--        end if;
        
        
--    end process NSTATE_DECODE;
    
--	ASYNC: process (in_PENABLE, in_PCLK, in_PRESETn)
--	begin
--		if rising_edge (in_PENABLE) then	-- rising_edge
--			if in_PSELx = '1' then --slave_select_check then
--				case in_PADDR is
--					when '0' =>
--						if in_PWRITE = '1' then
--							null;
--							-- never happens in the switch slave
--						else
--							out_PRDATA <= (others=>'0');
--							out_PRDATA(2 downto 0) <= switch_state;	
----							out_PREADY <= '1';
--							int_PREADY := '1';
--						end if;
--					when others =>
--							null;
--				end case; -- in_PADDR
--			end if;	-- in_PSELx
--		end if;	-- rising_edge(in_PENABLE)
		
--		-- putting this here. would be prettier if it had a 
--		-- process on its own or no process at all

--		if rising_edge(in_PCLK) then
--				if in_PRESETn = '0' then
--					out_PRDATA <= (others=>'0');
--				else 
--					if int_PREADY = '1' then
--						int_PREADY := '0';
--					end if;	-- int_pready
--				end if;
--		end if; -- in_pclk
        
--	end process ASYNC;

end behaviour;



