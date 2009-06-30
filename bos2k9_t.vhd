-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the top level entity.
-----------------------------------------------------------------------

use work.bos2k9_globals.all;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.txt_util.all;

-----------------------------------------------------------------------

entity bos2k9_t is
  generic(
    clock_interval : time   := clock_interval_c;
    spi_filename   : string := "bos2k9_t.dat");
end bos2k9_t;

-----------------------------------------------------------------------

architecture test of bos2k9_t is

  component bos2k9 is
    port(
      CLOCK_50 : in std_logic;
    
      KEY  : in  std_logic_vector(3 downto 0);
      SW   : in  std_logic_vector(17 downto 0);
      LEDR : out std_logic_vector(17 downto 0);
      LEDG : out std_logic_vector(8 downto 0);
    
      SD_DAT  : in  std_logic;
      SD_DAT3 : out std_logic;
      SD_CMD  : out std_logic;
      SD_CLK  : out std_logic);
  end component;

  file   spi_file : text open read_mode is spi_filename;
  signal test_s   : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal KEY_s      : std_logic_vector(3 downto 0);
  signal SW_s       : std_logic_vector(17 downto 0);
  signal LEDR_s     : std_logic_vector(17 downto 0);
  signal LEDG_s     : std_logic_vector(8 downto 0);
  signal SD_DAT_s   : std_logic;
  signal SD_DAT3_s  : std_logic;
  signal SD_CMD_s   : std_logic;
  signal SD_CLK_s   : std_logic;
  
  signal start_s : std_logic;
  signal txd_s   : std_logic_byte_t;
  signal rxd_s   : std_logic_byte_t;
  signal spi_s   : spi_bus_t;
  
  signal addr_sw_s : std_logic_byte_t;
  signal byte_sw_s : std_logic_byte_t;
  signal byte_dw_s : std_logic_byte_t;
begin
  dut : bos2k9 port map(clock_s,
    KEY_s,
    SW_s,
    LEDR_s,
    LEDG_s,
    SD_DAT_s,
    SD_DAT3_s,
    SD_CMD_s,
    SD_CLK_s);
  SD_DAT_s   <= spi_s.miso;
  spi_s.mosi <= SD_CMD_s;
  spi_s.sck  <= SD_CLK_s;
  spi_s.cs   <= SD_DAT3_s;
  
  byte_dw_s         <= LEDR_s(7 downto 0);
  SW_s(7 downto 0)  <= addr_sw_s;
  SW_s(15 downto 8) <= byte_sw_s;
  SW_s(16)          <= '0';
  SW_s(17)          <= not reset_s;
  KEY_s(0)          <= not start_s;
  KEY_s(3 downto 1) <= (others => '1');
  
  addr_sw_s <= (others => '0');
  byte_sw_s <= (others => '0');
  
  stimulus : process
  begin
    start_s <= '0';
  
    
    wait;
  end process;
  
  slave : process
    procedure read_txd_and_rxd is
      variable line_v  : line;
      variable input_v : string(1 to 17);
      variable byte_v  : std_logic_byte_t;
    begin
      readline(spi_file, line_v);
      read(line_v, input_v);
      txd_s <= to_std_logic_vector(input_v(1 to 8));
      rxd_s <= to_std_logic_vector(input_v(10 to 17));
    end read_txd_and_rxd;
    variable count_v : integer;
    variable index_v : integer;
    variable txd_v   : std_logic_byte_t;
  begin
    rxd_s <= (others => 'Z');
    txd_v := (others => 'U');
    test_s <= 0;
    
    wait until falling_edge(spi_s.cs);
    while spi_s.cs = '0' loop
      index_v := 7;
      count_v := 0;
      read_txd_and_rxd;
      spi_s.miso <= rxd_s(index_v);
      while index_v > -1 loop
        wait until spi_s.sck'event or spi_s.cs'event;
        if not (index_v = -1) then
          count_v := count_v + 1;
          -- Latch on odd edges, shift on even
          if (count_v mod 2) = 1 then
            txd_v(0)   := spi_s.mosi;
            index_v    := index_v - 1;
          else
            txd_v      := txd_v(6 downto 0) & 'U';
            spi_s.miso <= rxd_s(index_v);
          end if;
        end if;
      end loop;
      assert txd_v = txd_s report "unexpected spi data. got: " & str(txd_v) & " expected: " & str(txd_s);
    end loop;
    wait until falling_edge(clock_s);
  end process;
  
  reset : process
  begin
    reset_s <= '1';
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    reset_s <= '0';
    wait;
  end process;
  
  clock : process
  begin
    clock_s <= '0';
    wait for clock_interval / 2;
    clock_s <= '1';
    wait for clock_interval / 2;
  end process;
  
end test;
