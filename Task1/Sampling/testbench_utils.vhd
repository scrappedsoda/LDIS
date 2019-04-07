library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

package testbench_utils is
    constant freq_mhz : integer := 100;
    constant FSCL : integer := 400_000;
    constant TSCL_CYCLES : natural := natural(ceil(real(freq_mhz*1_000_000/FSCL)));
    
    constant clk_period: time := 1 ms;

    procedure assert_byte(byte : std_logic_vector(8-1 downto 0);
        signal sda : in std_logic);
    procedure simulate_byte(byte : std_logic_vector(8-1 downto 0);
        signal sda : out std_logic);
    procedure simulate_ack(signal sda : out std_logic);
    procedure assert_ack(signal sda : in std_logic);

    type temperature_test_pattern is record
        msb, lsb: std_logic_vector(8-1 downto 0);
        temp: std_logic_vector(16-1 downto 0);
    end record;
    type temperature_test_patterns is array (natural range <>) of temperature_test_pattern;
    constant temp_patterns : temperature_test_patterns :=
        (
            (x"AB", x"CD", x"ABCD"),
            (x"DE", x"0F", x"DE0F")
        );
end package testbench_utils;

package body testbench_utils  is
    procedure assert_byte(byte : std_logic_vector(8-1 downto 0);
        signal sda : in std_logic) is
        variable matching:boolean;
        begin
            --report "begin assert byte";
            wait for (1+ TSCL_CYCLES/4) *clk_period;
            for i in byte'range loop
                matching := false;
                if (byte(i) = '1') then
                    matching := sda = 'H' or sda = '1';
                else
                    matching := sda = '0';
                end if;         
                assert matching
                    report "sda mismatch expected" & std_logic'image(byte(i)) & 
                    " actual " & std_logic'image(sda) severity error;
                if (matching = true) then
                    --report "sda match " & std_logic'image(byte(i));
                end if;
                if (i /= 0) then
                    wait for (4+TSCL_CYCLES) * clk_period;
                end if;
            end loop;
            wait for (4+3*TSCL_CYCLES/4) *clk_period;
    end assert_byte;

    procedure simulate_byte(byte : std_logic_vector(8-1 downto 0);
        signal sda : out std_logic) is 
        begin
            for i in byte'range loop
                sda <= byte(i);
                    wait for (4+TSCL_CYCLES) * clk_period;
            end loop;
            sda <= 'H';
    end simulate_byte;

    procedure simulate_ack(signal sda : out std_logic) is
        begin
            --report "begin ack";
            sda <= '0';
            wait for (4+TSCL_CYCLES) *clk_period;
            sda <= 'H';
            --report "end ack";
    end simulate_ack;

    procedure assert_ack(signal sda : in std_logic) is
        begin
            wait for (1+ TSCL_CYCLES/4) *clk_period;
            assert sda = '0'
                report "ack expected but sda was " & std_logic'image(sda) severity error;
            wait for (4+3*TSCL_CYCLES/4) *clk_period;
    end assert_ack;
end package body;