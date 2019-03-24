library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- The Nexys 4 DDR has an ADT7420 via I2C. The slave address
-- is 0x4B. The THIGH (0x04:0x05) and the TLOW (0x06:0x07)
-- are the registers with the temp.

-- max SCL: 400 kHz
-----------------
-- entity
-----------------
entity ADT7420 is
	port (
		inout_sdl : inout std_logic;
		ionut_scl : inout std_logic;

		in_clk  : in std_logic;
		in_size : in std_logic_vector((8-1) downto 0);
		in_data : in std_logic_vector((16-1) downto 0);
		out_avg  : out std_logic_vector((16-1) downto 0)
	);
end ADT7420;

-----------------
-- behaviour
-----------------
architecture behaviour of ADT7420 is
constant adt_addr : std_logic_vector := "1001011";
constant adt_regth : std_logic_vector := x"00";

-- from the demo
type state_type is (st_idle, st_read, st_write, st_write_start);
signal state : state_type;

signal tempReg : std_logic_vector(15 downto 0) := (others => '0');
signal tmpValid : boolean := false;

begin

	TEMP_O <= tempReg;
	RDY_O <= '1' when tpmValid else '0';

	writeProc : process (in_clk)
	begin
		if rising_edge(in_clk) then
		TODO: implement fsm to write with scl as clock

	end process;


end behaviour;
