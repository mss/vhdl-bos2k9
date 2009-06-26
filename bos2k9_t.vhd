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

-----------------------------------------------------------------------

entity bos2k9_t is
  generic(
    clock_interval : time := clock_interval_c;
    clock_divider  : positive := 6;
    txd_pattern : std_logic_byte_t := "10010110";
    rxd_pattern : std_logic_byte_t := "LHLHLHLH";
    repeat : natural := 1);
end bos2k9_t;

-----------------------------------------------------------------------

architecture test of bos2k9_t is

  component bos2k9 is
    port(
      clk : in  std_logic;
      rst : in  std_logic;
    
      start_btn : in  std_logic;
      busy_led  : out std_logic;
    
      byte_swc : in  std_logic_byte_t;
      byte_led : out std_logic_byte_t;
    
      spi_miso : in  std_logic;
      spi_mosi : out std_logic;
      spi_sck  : out std_logic;
      spi_cs   : out std_logic);
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal start_n : std_logic;
  signal busy_s  : std_logic;
  signal txd_s   : std_logic_byte_t;
  signal rxd_s   : std_logic_byte_t;
  signal miso_s  : std_logic;
  signal mosi_s  : std_logic;
  signal sck_s   : std_logic;
  signal cs_s    : std_logic;
  
  signal ss_n    : std_logic;
  
  signal simo_s  : std_logic_byte_t;
begin
  dut : bos2k9 port map(
    clk => clock_s,
    rst => reset_s,
    start_btn => start_n,
    busy_led => busy_s,
    byte_swc => txd_s,
    byte_led => rxd_s,
    spi_miso => miso_s,
    spi_mosi => mosi_s,
    spi_sck  => sck_s,
    spi_cs   => cs_s);
  
  stimulus : process
    variable repeat_v : natural;
  begin
    wait for clock_interval / 4;
  
    repeat_v := repeat;
    test_s <= -3;
    start_n <= '1';
    txd_s   <= (others => 'U');
    wait until falling_edge(reset_s); test_s <= test_s + 1;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    txd_s  <= txd_pattern;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    start_n <= '0';
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    txd_s  <= (others => 'U');
    
    while repeat_v > 0 loop
      repeat_v := repeat_v - 1;
    
      wait until rising_edge(clock_s); test_s <= test_s + 1;
      txd_s  <= (others => '1');
    
      wait until rising_edge(clock_s); test_s <= test_s + 1;
      txd_s  <= txd_s xor txd_pattern;
      
      wait until falling_edge(busy_s); test_s <= test_s + 1;
    
      -- while busy_s = '1' loop
        -- wait until rising_edge(clock_s);
      -- end loop;
      -- test_s <= test_s + 1;
      -- start_n <= '0';
    
      wait until rising_edge(clock_s); test_s <= test_s + 1;
      start_n <= '1';
    
      wait until rising_edge(clock_s); test_s <= test_s + 1;
      txd_s  <= (others => 'U');
    end loop;
    
    start_n <= '1';
    wait;
  end process;
  
  ss_n <= cs_s;
  
  slave : process
    variable count_v : integer;
    variable index_v : integer;
    variable data_v  : std_logic_byte_t;
  begin
    wait for clock_interval / 4;
  
    simo_s  <= (others => 'U');
    miso_s  <= 'Z';
    index_v := 7;
    count_v := 0;
    wait until falling_edge(ss_n);
    data_v := txd_s;
    
    miso_s  <= rxd_pattern(index_v);
    
    while ss_n = '0' loop
      wait until sck_s'event or ss_n'event;
      if not (index_v = -1) then
        count_v := count_v + 1;
        -- Latch on odd edges, shift on even
        if (count_v mod 2) = 1 then
          simo_s(0) <= mosi_s;
          index_v := index_v - 1;
        else
          simo_s  <= simo_s(6 downto 0) & simo_s(7);
          miso_s  <= rxd_pattern(index_v);
        end if;
      end if;
    end loop;
    
    assert simo_s = data_v      report "neq:txd";
    assert rxd_s  = rxd_pattern report "neq:rxd";
    wait until falling_edge(clock_s);
  end process;
  
  reset : process
  begin
    reset_s <= '1';
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
