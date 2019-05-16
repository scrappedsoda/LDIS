library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entity Amba_Slave_Output is
generic (
	slave_num : natural := 2;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000
	);
port (
	out_intpr   : out std_logic;
	in_PCLK		: in std_logic;	-- system clk
	in_PRESETn	: in std_logic;	-- system rst

	in_PADDR	: in std_logic;	-- APB Bridge
	in_PENABLE	: in std_logic;	-- APB Bridge
	in_PWRITE   : in std_logic;	-- APB Bridge
	in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	in_PSELx	: in std_logic;
	out_PREADY	: out  std_logic;	-- slave interface 
	out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
	out_PSLVERR	: out  std_logic; 	-- slave interface 
-- the outputs to the bcd
	out_seg		: out std_logic_vector((8-1) downto 0); 
	out_an 		: out std_logic_vector((8-1) downto 0)
);
end Amba_Slave_Output;


architecture Behaviour of Amba_Slave_Output is
	-- BCD
	component sevenseg 
		generic (
			clockfreq : integer := 50_000_000
		);
  		port (
			in_clk			: in  std_logic;
			in_rst			: in  std_logic;
			in_vld			: in  std_logic;
			in_tmp			: in  std_logic_vector((16-1) downto 0);
			out_seg		: out std_logic_vector((8-1) downto 0);
			out_an		: out std_logic_vector((8-1) downto 0)
		);
	end component; -- BCD

	type state_type_slave is (sts_idle, sts_eval, sts_read, sts_write);
	signal state : state_type_slave;

	signal int_data : std_logic_vector(bus_size-1 downto 0);
	signal int_new_data : std_logic;
	signal int_rec_data : std_logic_vector(bus_size-1 downto 0);
	signal int_PREADY : std_logic;

	signal bcd_in_clk  : std_logic;
	signal bcd_in_rst  : std_logic;
	signal bcd_in_vld  : std_logic;
	signal bcd_in_tmp  : std_logic_vector(15 downto 0);
	signal bcd_out_seg : std_logic_vector(7 downto 0);
	signal bcd_out_an  : std_logic_vector(7 downto 0);
begin

	out_PREADY <= '1' when int_PREADY = '1' else 'Z';
	out_intpr <= int_PREADY;
	out_seg <= bcd_out_seg;
	out_an <= bcd_out_an;


	ASYNC: process (state, in_PENABLE, in_PCLK, in_PRESETn, int_new_data,
		in_PSELx, in_PWRITE, in_PADDR, in_PWDATA)
	begin
		if in_PRESETn = '0' then
			int_data <= (others =>'0');
			int_new_data <= '0';
			int_rec_data <= (others=>'0');
			int_PREADY <= '0';
			state <= sts_idle;

		else
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
					if in_PADDR = '0' then
						-- new data delivery
						int_rec_data <= in_PWDATA;
						int_new_data <= '1';
						out_PRDATA <= (others=>'0');
	
						int_PREADY   <= '1';
					else -- in_PADDR ='1'
						-- shouldn't happen
						null;
					end if;
	
				when sts_read =>
--						int_PREADY <= '1';
						null;
			end case;


--			if rising_edge (in_PENABLE) then	-- rising_edge penable
--				if in_PSELx = '1' then
--					case in_PADDR is
--						when '0' =>	-- dsp data
--							if in_PWRITE = '1' then	-- here to deliver me new data
--								-- do i even need int_rec_data?
--								int_rec_data <= in_PWDATA;
--								bcd_in_tmp <= in_PWDATA(15 downto 0);
--								bcd_in_vld <= '1';
--								int_new_data <= '1';	-- to show if the data is new
--								int_PREADY <= '1';
--	--							out_PREADY <= '1';
--								out_PRDATA <= (others=>'0');
--							else	-- wants to read the new data word
--								-- never happens
--								null;
--							end if;
--	
--						when '1' =>	 
--							-- never happens
--							null;
--	
--						when others =>
--							null;
--	
--					end case; -- in_PADDR
--				end if;	-- in_PSELx
--			end if;	-- rising_edge(in_PENABLE)
			
			if rising_edge(in_PCLK) then
				if bcd_in_vld = '1' then
					bcd_in_vld <= '0';
				end if;
	
				if int_PREADY = '1' then
					state <= sts_idle;
					bcd_in_tmp <= int_rec_data;
					bcd_in_vld <= '1';

					int_PREADY <= '0';
	--				out_PREADY <= 'Z';
				end if;
			end if;	-- in_PCLK
		end if;


	end process ASYNC;

	BCD_0 : sevenseg generic map
	(
		clockfreq => clockfreq
	) 
	port map ( 
		in_clk   => in_PCLK,
		in_rst   => in_PRESETn,
		in_vld   => bcd_in_vld,
		in_tmp   => bcd_in_tmp, 
		out_seg  => bcd_out_seg,
		out_an   => bcd_out_an
	);

end behaviour;



