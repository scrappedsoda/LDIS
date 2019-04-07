library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- The Nexys 4 DDR has an ADT7420 via I2C. The slave address
-- is 0x4B. The THIGH (0x04:0x05) and the TLOW (0x06:0x07)
-- are the registers with the temp.
-- a conversion takes typically 240ms

use work.TWIUtils.ALL;

-- max SCL: 400 kHz
-----------------
-- entity
-----------------
entity ADT7420 is
	Generic (CLOCKFREQ : natural := 100);
	port (
		inout_sda : inout std_logic;
		inout_scl : inout std_logic;

		in_clk  : in std_logic;
		in_srst : in std_logic;

		out_tmp : out std_logic_vector((16-1) downto 0);
		out_rdy : out std_logic;
		out_err : out std_logic
	);
end ADT7420;

-----------------
-- behaviour
-----------------
architecture behaviour of ADT7420 is
	component TWICtl 
	generic  
	( 
		CLOCKFREQ : natural := 50;  -- input CLK frequency in MHz 
		ATTEMPT_SLAVE_UNBLOCK : boolean := false --setting this true will attempt 
		--to drive a few clock pulses for a slave to allow to finish a previous 
		--interrupted read transfer, otherwise the bus might remain locked up        
	); 
	port ( 
		MSG_I : in STD_LOGIC; --new message 
		STB_I : in STD_LOGIC; --strobe 
		A_I : in  STD_LOGIC_VECTOR (7 downto 0); --address input bus 
		D_I : in  STD_LOGIC_VECTOR (7 downto 0); --data input bus 
		D_O : out  STD_LOGIC_VECTOR (7 downto 0); --data output bus 
		DONE_O : out  STD_LOGIC; --done status signal 
		ERR_O : out  STD_LOGIC; --error status 
		ERRTYPE_O : out error_type; --error type 
		CLK : in std_logic; 
		SRST : in std_logic; 
		----------------------------------------------------------------------------- 
--		TWI bus signals 
		----------------------------------------------------------------------------- 
		SDA : inout std_logic; --TWI SDA 
		SCL : inout std_logic --TWI SCL 
	); 
	end component;

----------------------------------------------------------------------------------
-- Definitions for the I2C initialization vector
-- All copied from the original demo
----------------------------------------------------------------------------------

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
	
	constant DELAY : NATURAL := 1; --ms
	constant DELAY_CYCLES : NATURAL := natural(ceil(real(DELAY*1000*CLOCKFREQ)));
	constant RETRY_COUNT : NATURAL := 10;


	-- State Machine states definition
	type state_type is (
		stIdle, -- Idle State
		stInitReg,  -- Send register address from the init vector
		stInitData, -- Send data byte from the init vector
		stRetry,    -- Retry state reached when there is a bus error, will retry RETRY_COUNT times
		stReadTempR,  -- Send temperature register address
		stReadTempD1, -- Read temperature MSB
		stReadTempD2, -- Read temperature LSB
		stError -- Error state when reached when there is a bus error after a successful init; stays here until reset
	);
	signal state, nstate : state_type;


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
	
	signal initWord: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal initA : natural range 0 to NO_OF_INIT_VECTORS := 0; --init vector index
	signal initEn : std_logic;
	
	--Two-Wire Controller signals
	signal twiMsg, twiStb, twiDone, twiErr : std_logic;
	signal twiDi, twiDo, twiAddr : std_logic_vector(7 downto 0);
	
	--Wait counter used between retry attempts
	signal waitCnt : natural range 0 to DELAY_CYCLES := DELAY_CYCLES;
	signal waitCntEn : std_logic;


	--Retry counter to count down attempts to get rid of a bus error
	signal retryCnt : natural range 0 to RETRY_COUNT := RETRY_COUNT;
	signal retryCntEn : std_logic;
	-- Temporary register to store received data
	signal tempReg : std_logic_vector(15 downto 0) := (others => '0');
	-- Flag indicating that a new temperature data is available
	signal fReady : boolean := false;

begin

----------------------------------------------------------------------------------
-- Outputs
----------------------------------------------------------------------------------
out_tmp <= tempReg(15 downto 0);

out_rdy <= '1' when fReady else
			'0';
out_err <= '1' when state = stError else
			'0';

----------------------------------------------------------------------------------
-- I2C Master Controller
----------------------------------------------------------------------------------
Inst_TWICtl : TWICtl
	generic map (
		ATTEMPT_SLAVE_UNBLOCK => true,
		CLOCKFREQ => 100
	)
	port map (
		MSG_I => twiMsg,
		STB_I => twiStb,
		A_I => twiAddr,
		D_I => twiDi,
		D_O => twiDo,
		DONE_O => twiDone,
		ERR_O => twiErr,
		ERRTYPE_O => open,
		CLK => in_clk,
		SRST => in_srst,
		SDA => inout_sda, --TMP_SDA,
		SCL => inout_scl --TMP_SCL
	);

----------------------------------------------------------------------------------
-- Initialiation Map RAM
----------------------------------------------------------------------------------
	initWord <= TempSensInitMap(initA);

	InitA_CNT: process (in_clk) 
	begin
		if Rising_Edge(in_clk) then
			if (state = stIdle or initA = NO_OF_INIT_VECTORS) then
				initA <= 0;
			elsif (initEn = '1') then
				initA <= initA + 1;
			end if;
		end if;
	end process;
	
----------------------------------------------------------------------------------
-- Delay and Retry Counters
----------------------------------------------------------------------------------	
	Wait_CNT: process (in_clk) 
	begin
		if Rising_Edge(in_clk) then
			if (waitCntEn = '0') then
				waitCnt <= DELAY_CYCLES;
			else
				waitCnt <= waitCnt - 1;
			end if;
		end if;
	end process;
	
	Retry_CNT: process (in_clk) 
	begin
		if Rising_Edge(in_clk) then
			if (state = stIdle) then
				retryCnt <= RETRY_COUNT;
			elsif (retryCntEn = '1') then
				retryCnt <= retryCnt - 1;
			end if;
		end if;
	end process;

----------------------------------------------------------------------------------
-- Temperature Registers
----------------------------------------------------------------------------------	
	TemperatureReg: process (in_clk) 
	variable temp : std_logic_vector(7 downto 0);
	begin
		if Rising_Edge(in_clk) then
			--MSB
			if (state = stReadTempD1 and twiDone = '1' and twiErr = '0') then
				temp := twiDo;
			end if;
			--LSB
			if (state = stReadTempD2 and twiDone = '1' and twiErr = '0') then
				tempReg <= temp & twiDo;
			end if;
		end if;
	end process;
	
----------------------------------------------------------------------------------
-- Ready Flag
----------------------------------------------------------------------------------	
	ReadyFlag: process (in_clk) 
	begin
		if Rising_Edge(in_clk) then
			if (state = stIdle or state = stError) then
				fReady <= false;
			elsif (state = stReadTempD2 and twiDone = '1' and twiErr = '0') then
				fReady <= true;
			end if;
		end if;
	end process;	
	
----------------------------------------------------------------------------------
-- Initialization FSM & Continuous temperature read
----------------------------------------------------------------------------------	
	SYNC_PROC: process (in_clk)
	begin
		if (in_clk'event and in_clk = '1') then
			if (in_srst = '1') then
				state <= stIdle;
			else
				state <= nstate;
			end if;        
		end if;
	end process;
 
	OUTPUT_DECODE: process (state, initWord, twiDone, twiErr, twiDo, retryCnt, waitCnt, initA)
	begin
		twiStb <= '0'; --byte send/receive strobe
		twiMsg <= '0'; --new transfer request (repeated start)
		waitCntEn <= '0'; --wait countdown enable
		twiDi <= "--------"; --byte to send
		twiAddr <= ADT7420_ADDR & '0'; --I2C device address with R/W bit
		initEn <= '0'; --increase init map address
		retryCntEn <= '0'; --retry countdown enable
		
		case (state) is
			when stIdle =>
			
			when stInitReg => --this state sends the register address from the current init vector
				twiStb <= '1';
				twiMsg <= '1';
				twiAddr(0) <= IWR; --Register address is a write
				twiDi <= initWord(15 downto 8);
			when stInitData => --this state sends the data byte from the current init vector
				twiStb <= '1';
				twiAddr(0) <= initWord(initWord'high); --could be read or write
				twiDi <= initWord(7 downto 0);
				if (twiDone = '1' and
					(twiErr = '0' or (initWord(16) = IWR and initWord(15 downto 8) = ADT7420_RRESET)) and
					(initWord(initWord'high) = IWR or twiDo = initWord(7 downto 0))) then
					initEn <= '1';
				end if;
			when stRetry=> --in case of an I2C error during initialization this state will be reached
				if (retryCnt /= 0) then				
					waitCntEn <= '1';
					if (waitCnt = 0) then
						retryCntEn <= '1';
					end if;
				end if;
			
			when stReadTempR => --this state sends the temperature register address
				twiStb <= '1';
				twiMsg <= '1';
				twiDi <= ADT7420_RTEMP;
				twiAddr(0) <= IWR; --Register address is a write				
			when stReadTempD1 => --this state reads the temperature MSB
				twiStb <= '1';
				twiAddr(0) <= IRD;
			when stReadTempD2 => --this state reads the temperature LSB
				twiStb <= '1';
				twiAddr(0) <= IRD;
				
			when stError => --in case of an I2C error during temperature poll
				null; --stay here
		end case;
			
	end process;
 
	NEXT_STATE_DECODE: process (state, twiDone, twiErr, initWord, twiDo, retryCnt, waitCnt)
	begin
	--declare default state for nstate to avoid latches
	nstate <= state;  --default is to stay in current state

	case (state) is
		when stIdle =>
			nstate <= stInitReg;

		when stInitReg =>
			if (twiDone = '1') then
				if (twiErr = '1') then
					nstate <= stRetry;
				else
					nstate <= stInitData;
				end if;
			end if;

		when stInitData =>
			if (twiDone = '1') then
				if (twiErr = '1') then
					nstate <= stRetry;
				else
					if (initWord(initWord'high) = IRD and twiDo /= initWord(7 downto 0)) then
						nstate <= stRetry;
					elsif (initA = NO_OF_INIT_VECTORS-1) then
						nstate <= stReadTempR;
					else
						nstate <= stInitReg;
					end if;
				end if;
			end if;				
		when stRetry =>
			if (retryCnt = 0) then
				nstate <= stError;
			elsif (waitCnt = 0) then
				nstate <= stInitReg; --new retry attempt
			end if;

		when stReadTempR =>
			if (twiDone = '1') then
				if (twiErr = '1') then
					nstate <= stError;
				else
					nstate <= stReadTempD1;
				end if;
			end if;
		when stReadTempD1 =>
			if (twiDone = '1') then
				if (twiErr = '1') then
					nstate <= stError;
				else
					nstate <= stReadTempD2;
				end if;
			end if;
		when stReadTempD2 =>
			if (twiDone = '1') then
				if (twiErr = '1') then
					nstate <= stError;
				else
					nstate <= stReadTempR;
				end if;
			end if;

		when stError =>
			null; --stay

		when others =>
			nstate <= stIdle;
	end case;      
	end process;

end behaviour;
