library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- The Nexys 4 DDR has an ADT7420 via I2C. The slave address
-- is 0x4B. The THIGH (0x04:0x05) and the TLOW (0x06:0x07)
-- are the registers with the temp.
-- a conversion takes typically 240ms

--use work.TWIUtils.ALL;

-- max SCL: 400 kHz
-----------------
-- entity
-----------------
entity ADT7420 is
	Generic (
		CLOCKFREQ : integer := 50_000_000;
		bus_clk   : integer := 400_000;
		samplet   : integer := 1		-- alle 1 sek ein wert
	);
	port (
		inout_sda : inout std_logic;
		inout_scl : inout std_logic;

		in_clk  : in std_logic;
		in_srst : in std_logic;

		out_tmp : out std_logic_vector((16-1) downto 0);
		out_rdy : out std_logic;
		out_err : out std_logic;
		dbg_1	: out std_logic
	);
end ADT7420;

-----------------
-- behaviour
-----------------
architecture behaviour of ADT7420 is
	component i2c_master
	generic  
	( 
		input_clk : INTEGER := 50_000_000;
		bus_clk   : INTEGER := 400_000
	); 
	port ( 
    	clk       : IN     STD_LOGIC;                    --system clock
    	reset_n   : IN     STD_LOGIC;                    --active low reset
    	ena       : IN     STD_LOGIC;                    --latch in command
    	addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    	rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    	data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    	busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    	data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    	ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    	sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    	scl       : INOUT  STD_LOGIC                   --serial clock output of i2c bus
	); 
	end component;

--	constant cntmax  : integer := samplet*CLOCKFREQ;
	constant cntmax : integer := 40000;
	signal counter : integer := cntmax-1;

    signal clk       : STD_LOGIC;                    --system clock
    signal reset_n   : STD_LOGIC;                    --active low reset
    signal i2c_ena       : STD_LOGIC;                    --latch in command
    signal i2c_addr      : STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    signal i2c_rw        : STD_LOGIC;                    --'0' is write, '1' is read
    signal i2c_data_wr   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    signal i2c_busy      : STD_LOGIC;                    --indicates transaction in progress
    signal i2c_data_rd   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    signal i2c_ack_error : STD_LOGIC;                    --flag if improper acknowledge from slave
    signal sda       : STD_LOGIC;                    --serial data output of i2c bus
    signal scl       : STD_LOGIC;                   --serial clock output of i2c bus


	TYPE states IS(init, idle,  query); --needed states
	SIGNAL state : states := init;                        --state machine

	signal tempreg : std_logic_vector(15 downto 0);
	signal valid : boolean := false;
	signal busy_prev : std_logic; 
	signal start_i2c : std_logic := '0';

	constant IRD : std_logic := '1'; -- init read
	constant IWR : std_logic := '0'; -- init write
	-- Slave Address
	constant ADT7420_ADDR : std_logic_vector(7 downto 1)   := "1001011"; 
	-- ID Address for ADT7420
	constant ADT7420_RID : std_logic_vector(7 downto 0)    := x"0B"; 
	-- Software Reset Register
	constant ADT7420_RRESET : std_logic_vector(7 downto 0) := x"2F"; 
	-- Temperature Read MSB Address
	constant ADT7420_RTEMP : std_logic_vector(7 downto 0)  := x"00"; 
	-- ADT7420 Manufacturer ID
	constant ADT7420_ID : std_logic_vector(7 downto 0)     := x"CB"; 
	


	constant NO_OF_INIT_VECTORS : natural := 3; -- number of init vectors in TempSensInitMap
	constant DATA_WIDTH : integer := 1 + 8 + 8; -- RD/WR bit + 1 byte register address + 1 byte data
	constant ADDR_WIDTH : natural := natural(ceil(log(real(NO_OF_INIT_VECTORS), 2.0)));
	
	type TempSensInitMap_type is array (0 to NO_OF_INIT_VECTORS-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
	signal TempSensInitMap: TempSensInitMap_type := (
		IRD & x"0B" & x"CB", -- Read ID R[0x0B]=0xCB
		IWR & x"2F" & x"00", -- Reset R[0x2F]=don't care
		IRD & x"0B" & x"CB" -- Read ID R[0x0B]=0xCB
--		IWR & x"03" & x"80"  -- configure it for 16bit
	);

	-- 0x03 is the adress for the init
	-- the value for 16 bit is 0x80
begin


	I2C: i2c_master
	generic map 
	( 
		input_clk =>  CLOCKFREQ,
		bus_clk   =>  bus_clk
	) 
	port map 
	( 
    	clk       =>  in_clk,
    	reset_n   =>  in_srst,
    	ena       =>  i2c_ena,
    	addr      =>  i2c_addr,
    	rw        =>  i2c_rw,
    	data_wr   =>  i2c_data_wr,
    	busy      =>  i2c_busy,
    	data_rd   =>  i2c_data_rd,
    	ack_error =>  i2c_ack_error,
    	sda       =>  inout_sda,
    	scl       =>  inout_scl
	); 

----------------------------------------------------------------------------------
-- Outputs
----------------------------------------------------------------------------------
dbg_1 <= start_i2c;
out_tmp <= tempReg(15 downto 0);
out_err <= '0';
out_rdy <= '1' when valid else
			'0';
--out_err <= '1' when state = stError else
--			'0';

GETVAL:process (in_clk)

begin
	
	if rising_edge(in_clk) then
		counter <= counter +1;
	end if;
	if counter >= cntmax then
		counter <= 0;
		start_i2c <= '1';
		--state <= query;
	else
		start_i2c <= '0';
--		state <= idle;
	end if;
end process GETVAL;

FSM:process (in_clk, state, start_i2c)
	
	variable  busy_cnt : integer := 0;
begin
	if start_i2c = '1' then
		state <= query;
	end if;

case state is
	WHEN init =>

		-- in the init state i set the resoultion to 16 bit
		busy_prev <= i2c_busy;                       --capture the value of the previous i2c busy signal
		IF(busy_prev = '0' AND i2c_busy = '1') THEN  --i2c busy just went high
			busy_cnt := busy_cnt + 1;         --counts the times busy has gone from low to high during transaction
		END IF;
	
		CASE busy_cnt IS                             --busy_cnt keeps track of which command we are on
			WHEN 0 =>                                  --no command latched in yet
				i2c_ena <= '1';                            --initiate the transaction
				i2c_addr <= ADT7420_ADDR;                    --set the address of the slave
				i2c_rw <= '0';                             --command 1 is a write
				i2c_data_wr <= x"03";             --data to be written
			WHEN 1 =>                                  --1st busy high: command 1 latched, okay to issue command 2
				i2c_data_wr <= x"80";				--data to be written
				i2c_rw <= '0';                             --command 2 is a read (addr stays the same)
			WHEN 2 =>                                  --2nd busy high: command 2 latched, okay to issue command 3
				i2c_ena <= '0';
				IF(i2c_busy ='0') THEN
					--data(7 DOWNTO 0) <= i2c_data_rd;          --retrieve data from command 2
					--tempReg(7 downto 0) <= i2c_data_rd;
					--tempReg <= data;
					state <= idle;
					busy_cnt := 0;
				END IF;
			WHEN others => null;
		end case;

	WHEN query =>                               --state for captureing temperature
		busy_prev <= i2c_busy;                       --capture the value of the previous i2c busy signal
		IF(busy_prev = '0' AND i2c_busy = '1') THEN  --i2c busy just went high
			busy_cnt := busy_cnt + 1;                    --counts the times busy has gone from low to high during transaction
		END IF;
	
		CASE busy_cnt IS                             --busy_cnt keeps track of which command we are on
			WHEN 0 =>                                  --no command latched in yet
				i2c_ena <= '1';                            --initiate the transaction
				i2c_addr <= ADT7420_ADDR;                    --set the address of the slave
				i2c_rw <= '0';                             --command 1 is a write
				i2c_data_wr <= ADT7420_RTEMP;              --data to be written
			WHEN 1 =>                                  --1st busy high: command 1 latched, okay to issue command 2
				i2c_rw <= '1';                             --command 2 is a read (addr stays the same)
			WHEN 2 =>                                  --2nd busy high: command 2 latched, okay to issue command 3
				i2c_rw <= '1';                             --command 3 is a write
		--		i2c_data_wr <= new_data_to_write;          --data to be written
				IF(i2c_busy = '0') THEN                    --indicates data read in command 2 is ready
					tempReg(15 DOWNTO 8) <= i2c_data_rd;          --retrieve data from command 2
				END IF;
			WHEN 3 =>                                  --3rd busy high: command 3 latched, okay to issue command 4
				i2c_rw <= '1';                             --command 4 is read (addr stays the same)
				i2c_ena <= '0';
				IF(i2c_busy ='0') THEN
					tempReg(7 DOWNTO 0) <= i2c_data_rd;          --retrieve data from command 2
--					tempReg <= data;
					state <= idle;
					busy_cnt := 0;
					valid <= true;
				END IF;
		
		--	WHEN 4 =>                                  --4th busy high: command 4 latched, ready to stop
		--		i2c_ena <= '0';                            --deassert enable to stop transaction after command 4
		--		IF(i2c_busy = '0') THEN                    --indicates data read in command 4 is ready
		--			data(7 DOWNTO 0) <= i2c_data_rd;           --retrieve data from command 4
		--			busy_cnt := 0;                             --reset busy_cnt for next transaction
		--			state <= home;                             --transaction complete, go to next state in design
		--		END IF;
			WHEN OTHERS => NULL;
		END CASE;

	WHEN idle =>
		valid <= false;

	WHEN others => null;
END CASE;
end process FSM;

end behaviour;
