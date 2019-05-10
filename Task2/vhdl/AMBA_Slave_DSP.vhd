library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- http://web.eecs.umich.edu/~prabal/teaching/eecs373-f12/readings/ARM_AMBA3_APB.pdf

entity Amba_Slave_DSP is
generic (
	slave_num : natural := 2;
	bus_size   : natural := 16;
	clockfreq  : natural := 1000000
	);
port (
	in_PCLK		: in std_logic;	-- system clk
	in_PRESETn	: in std_logic;	-- system rst

	in_PADDR	: in std_logic;	-- APB Bridge
	in_PENABLE	: in std_logic;	-- APB Bridge
	in_PWRITE   : in std_logic;	-- APB Bridge
	in_PWDATA   : in std_logic_vector(bus_size-1 downto 0);	-- APB Bridge
	in_PSELx	: in std_logic; -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
--	in_PSELx	: in std_logic_vector (num_slaves-1 downto 0); -- integer(floor(log2(real(num_slaves)))) downto 0);	-- APB Bridge
	out_PREADY	: out  std_logic;	-- slave interface 
	out_PRDATA	: out  std_logic_vector((bus_size-1) downto 0);	-- slave interface 
	out_PSLVERR	: out  std_logic; 	-- slave interface 

	out_size_check 	: out std_logic_vector(2 downto 0);
	out_size		: out std_logic_vector(7 downto 0)
);
end Amba_Slave_DSP;


architecture Behaviour of Amba_Slave_DSP is
	-- DSP
	component DSP
  		port (
		in_clk  : in std_logic;
		in_rst  : in std_logic;
		in_drdy : in std_logic;
		in_err  : in std_logic;
		in_size : in std_logic_vector((3-1) downto 0);
		in_data : in std_logic_vector((16-1) downto 0);
		out_vld : out std_logic;
		out_avg : out std_logic_vector((16-1) downto 0);
		out_size_check	: out std_logic_vector(2 downto 0);
		out_size: out std_logic_vector(7 downto 0)
		);
	end component; -- DSP

	type state_type_slave is (sts_idle, sts_eval, sts_read, sts_write);
	signal state : state_type_slave;

	signal int_data : std_logic_vector(bus_size-1 downto 0);
	signal int_new_data : std_logic;
	signal int_rec_data : std_logic_vector(bus_size-1 downto 0);
	signal int_PREADY : std_logic;

	constant slave_select_check : std_logic_vector(3 downto 0) := "0010"; --(slave_num=>'1', others=>'0');

	signal want_read_data : std_logic;
	signal dsp_in_drdy : std_logic;
	signal dsp_in_err  : std_logic;
	signal dsp_in_size : std_logic_vector((3-1) downto 0) := "001";
	signal dsp_in_data : std_logic_vector((16-1) downto 0);
	signal dsp_out_vld : std_logic;
	signal dsp_out_avg : std_logic_vector((16-1) downto 0);

	signal dsp_out_size_check	: std_logic_vector(2 downto 0);
	signal dsp_out_size: std_logic_vector(7 downto 0);

begin

	out_PREADY <= '1' when int_PREADY = '1' else 'Z';

	ASYNC: process (in_PENABLE, in_PCLK, state, in_PRESETn, dsp_out_vld, int_new_data)
	begin
		case state is
			when sts_idle =>
				dsp_in_drdy <= '0';
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
					dsp_in_drdy  <= '1';
					dsp_in_data  <= in_PWDATA(15 downto 0);

					int_PREADY   <= '1';
				else -- in_PADDR ='1'
					int_rec_data <= in_PWDATA;
					dsp_in_size  <= in_PWDATA(2 downto 0);
					int_PREADY   <= '1';
				end if;

			when sts_read =>
				if in_PADDR = '0' then
					if int_new_data = '0' then
						out_PRDATA <= dsp_out_avg; --int_data;	
						int_PREADY <= '1';
						want_read_data <= '0';
					end if;	-- int_new_data
				end if; 
		end case;

		if rising_edge(in_PCLK) then
			if int_PREADY = '1' then --state = sts_read or state = sts_write then
				state <= sts_idle;
			end if;
		end if;
		if rising_edge(dsp_out_vld) then
			int_new_data <= '0';
		end if;	-- dsp_out_vld

--			if want_read_data = '1' then
--				if int_new_data = '0' then
--					out_PRDATA <= dsp_out_avg; --int_data;	
--					int_PREADY <= '1';
----					out_PREADY <= '1';
--					want_read_data <= '0';
--				end if;	-- int_new_data
--			end if; -- want_read_data
				
--		if rising_edge (in_PENABLE) then	-- rising_edge penable
--			if in_PSELx = '1' then
--				case in_PADDR is
--					when '0' =>	-- dsp data
--
--						if in_PWRITE = '1' then	-- here to deliver me new data
--							-- do i even need int_rec_data?
--							int_rec_data <= in_PWDATA;
--
--							int_new_data <= '1';	-- to show if the data is new
--							dsp_in_drdy <= '1';		-- show the dsp new data is here
--							dsp_in_data <= in_PWDATA(15 downto 0); -- put the new data
--							-- set pready to end the transaction
--							int_PREADY <= '1';
----							out_PREADY <= '1';
--						else	-- wants to read the new data word
--							want_read_data <= '1';
--
----							int_got_data <= '1';
--						end if;
--
--					when '1' =>	-- dsp settings (size)
--						if in_PWRITE = '1' then
--							dsp_in_size <= in_PWDATA(2 downto 0);
--							int_PREADY <= '1';
----							out_PREADY <= '1';
--						else
--							null;
----							out_PRDATA <= int_data;	
--						end if;
--
--					when others =>
--							null;
--
--				end case; -- in_PADDR
--			end if;	-- in_PSELx
--		end if;	-- rising_edge(in_PENABLE)
--		
--		if rising_edge(in_PCLK) then
--			if dsp_in_drdy = '1' then
--				dsp_in_drdy <= '0';
--			end if;
--
--			if int_PREADY = '1' then
--				int_PREADY <= '0';
----				out_PREADY <= 'Z';
--			end if;
--			if want_read_data = '1' then
--				if int_new_data = '0' then
--					out_PRDATA <= dsp_out_avg; --int_data;	
--					int_PREADY <= '1';
----					out_PREADY <= '1';
--					want_read_data <= '0';
--				end if;	-- int_new_data
--			end if; -- want_read_data
--		end if;	-- in_PCLK
--
--		-- if the new data is computed signal it
--		if rising_edge(dsp_out_vld) then
--			int_new_data <= '0';
--		end if;	-- dsp_out_vld


	end process ASYNC;

	DSP_0: DSP port map (
		in_clk  => in_PCLK,
		in_rst  => in_PRESETn,
		in_drdy => dsp_in_drdy,
		in_err  => dsp_in_err ,
		in_size => dsp_in_size,
		in_data => dsp_in_data,
		out_vld => dsp_out_vld,
		out_avg	=> dsp_out_avg,
		out_size_check => out_size_check,
		out_size => out_size 
	);

end behaviour;



