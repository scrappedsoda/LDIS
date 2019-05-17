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
	out_intpr   : out std_logic;
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

	signal helper : std_logic := '0';

	signal enable_write : std_logic;
	signal enable_read  : std_logic;
	signal int_data_vld : std_logic;

	signal int_data_read  : std_logic_vector(bus_size-1 downto 0);
	signal int_data_write : std_logic_vector(bus_size-1 downto 0);
	signal int_data_write2 : std_logic_vector(bus_size-1 downto 0);
begin

	out_PREADY <= '1' when int_PREADY = '1' else 'Z';
	out_intpr <= helper;


enable_write <= in_PENABLE and in_PWRITE and in_PSELx;
enable_read  <= not in_PWRITE and in_PSELx and int_data_vld;	-- data is read everytime to be ready on the first cycle

WRITE: process(in_PRESETn, enable_write)
begin
	if in_PRESETn ='0' then
		int_data_write <= x"0000";
		int_data_write2 <= x"0000";
	elsif rising_edge(enable_write) then
		case in_PADDR is
			when '0' =>
				int_data_write <= in_PWDATA;
			when '1' =>
				int_data_write2 <= in_PWDATA;
			when others => 
				null;
		end case;
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
			dsp_in_size <= int_data_write2(2 downto 0);
			dsp_in_data <= int_data_write;
			dsp_in_drdy <= '1';
			
			if dsp_out_vld = '1' then
				int_data_read <= dsp_out_avg;
				int_data_vld  <= '1';
			else
				int_data_read <= int_data_read;
				int_data_vld  <= '0';
			end if; -- dsp vld

			if enable_write = '0' then
			end if;

			if enable_write = '1' and in_PADDR = '0' then
				dsp_in_drdy <= '0';
			end if;

		end if; -- rst
	end if; -- rising clock

--		if enable_write or enable_read then
--			int_pready <= '1';
--		else 
--			int_pready <= '0';
--		end if; -- enable read or write

		-- here some logic to compare the data ins with the other registers and update them
		
end process SFORWARD;



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



