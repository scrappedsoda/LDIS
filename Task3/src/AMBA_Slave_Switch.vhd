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
	out_intpr   : out std_logic;
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
--	shared variable int_PREADY_t1 : std_logic;
--	shared variable int_PREADY_t2 : std_logic;

	signal nrst : std_logic;

	constant slave_select_check : std_logic_vector(3 downto 0) := "0001"; --(slave_num=>'1', others=>'0');

	signal switch_state : std_logic_vector(2 downto 0);

	signal enable_write : std_logic;
	signal enable_read  : std_logic;

	signal int_data_read  : std_logic_vector(bus_size-1 downto 0);
	signal int_data_write : std_logic_vector(bus_size-1 downto 0);

begin
	out_PREADY <= '1' when int_PREADY = '1' else 'Z';
	out_intpr <= int_PREADY;
	
enable_write <= in_PENABLE and in_PWRITE and in_PSELx;
enable_read  <= not in_PWRITE and in_PSELx;	-- data is read everytime to be ready on the first cycle

WRITE: process(in_PRESETn, enable_write)
begin
	if in_PRESETn ='0' then
		int_data_write <= x"0000";
	elsif rising_edge(enable_write) then
		int_data_write <= in_PWDATA;
	end if;
end process WRITE;

-- register with the enable sigs as clock
READ: process(in_PRESETn, enable_read)
begin
	if in_PRESETn ='0' then
		out_PRDATA <= x"0000";

	elsif rising_edge(enable_read) then
		out_PRDATA <= int_data_read;

	end if;
end process READ;

PREADYP: process(enable_write, enable_read)
begin
	if enable_write='1' or enable_read='1' then
		int_PREADY <= '1';
	else
		int_PREADY <= '0';
	end if;
end process PREADYP;

-- process to forward the data to whatever module or to write into the read register
SFORWARD: process(in_PRESETn, in_PCLK, enable_write, in_PADDR)
begin

	if rising_edge(in_PCLK) then
		if in_PRESETn = '0' then
			int_data_read <= x"0000";
		else
			int_data_read <= (others=>'0');
			int_data_read(2 downto 0) <= in_size;
		end if; -- rst
	end if; -- rising clock

end process SFORWARD;


--	int_data <= in_PWDATA;
--    NSTATE_DECODE: process(in_PENABLE, in_PCLK, state, in_PSELx, in_PWRITE, in_PRESETn, in_size)
--    begin
--		if in_PRESETn = '0' then
--			int_data <= (others =>'0');
--			int_PREADY <= '0';
--			state <= sts_idle;
--
--		else
--	        case state is
--	            when sts_idle =>
--	                int_PREADY <= '0';
--	                if rising_edge(in_PENABLE) then
--	                    state <= sts_eval;
--	                end if;
--	        
--	            when sts_eval =>
--	                if in_PSELx = '1' then
--	                    if in_PWRITE = '1' then
--	                        state <= sts_write;
--	                    else
--	                        state <= sts_read;
--	                    end if;
--	                else
--	                    state <= sts_idle;
--	                end if;
--	                
--	            when sts_write =>
--	                null;   -- never happens with the switch
--	            when sts_read =>
--	                int_PREADY <= '1';
--	                out_PRDATA <= (others=>'0');
--	                out_PRDATA(2 downto 0) <= in_size;
--	        end case;   --state
--	        
--	        if rising_edge(in_PCLK) then
--	            if state = sts_read then
--	                state <= sts_idle;
--	            end if;
--	        end if;
--		end if;
--    end process NSTATE_DECODE;
                
end behaviour;



