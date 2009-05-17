-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi_t
library fhw_spi_t;
library fhw_spi;
use fhw_spi.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------

entity spi_master_t is
  generic(
    clock_interval : time := 20 us;
    clock_divider  : positive := 6;
    spi_mode : natural := 0;
    data_width : positive := 8;
    txd_pattern : std_logic_vector(8 - 1 downto 0) := "10010110";
    rxd_pattern : std_logic_vector(8 - 1 downto 0) := "LHLHLHLH";
    repeat : natural := 1);
end spi_master_t;

-----------------------------------------------------------------------

architecture test of spi_master_t is
  constant spi_mode_c : unsigned(1 downto 0) := to_unsigned(spi_mode, 2);
  constant spi_cpol_c : std_logic := spi_mode_c(1);
  constant spi_cpha_c : std_logic := spi_mode_c(0);

  component spi_master is
    generic(
      clk_div    : positive := clock_divider;
      data_width : positive := data_width;
      spi_mode   : integer range 0 to 3 := spi_mode);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
    
      start : in  std_logic;
      busy  : out std_logic;
    
      txd   : in  std_logic_vector(data_width - 1 downto 0);
      rxd   : out std_logic_vector(data_width - 1 downto 0);
    
      miso  : in  std_logic;
      mosi  : out std_logic;
      sck   : out std_logic);
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal start_s : std_logic;
  signal busy_s  : std_logic;
  signal txd_s   : std_logic_vector(data_width - 1 downto 0);
  signal rxd_s   : std_logic_vector(data_width - 1 downto 0);
  signal miso_s  : std_logic;
  signal mosi_s  : std_logic;
  signal sck_s   : std_logic;
  
  signal ss_n    : std_logic;
  
  signal simo_s  : std_logic_vector(data_width - 1 downto 0);
begin
  dut : spi_master port map(clock_s, reset_s, start_s, busy_s, txd_s, rxd_s, miso_s, mosi_s, sck_s);
  
  stimulus : process
    variable repeat_v : natural;
  begin
    repeat_v := repeat;
    test_s <= -3;
    start_s <= '0';
    txd_s   <= (others => 'U');
    wait until falling_edge(reset_s); test_s <= test_s + 1;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    txd_s  <= txd_pattern;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    start_s <= '1';
    
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
      -- start_s <= '1';
    
      wait until rising_edge(clock_s); test_s <= test_s + 1;
      start_s <= '0';
    
      wait until rising_edge(clock_s); test_s <= test_s + 1;
      txd_s  <= (others => 'U');
    end loop;
    
    start_s <= '0';
    wait;
  end process;
  
  
  ss_n <= not busy_s;
  
  slave : process
    variable count_v : integer;
    variable index_v : integer;
    variable data_v  : std_logic_vector(data_width - 1 downto 0);
  begin
    simo_s  <= (others => 'U');
    miso_s  <= 'Z';
    index_v := data_width - 1;
    count_v := 0;
    wait until falling_edge(ss_n);
    data_v := txd_s;
    
    miso_s  <= rxd_pattern(index_v);
    if spi_cpha_c = '1' then
      wait until sck_s'event;
    end if;
    
    while ss_n = '0' loop
      wait until sck_s'event or ss_n'event;
      if not (index_v = -1) then
        count_v := count_v + 1;
        -- Latch on odd edges, shift on even
        if (count_v mod 2) = 1 then
          simo_s(0) <= mosi_s;
          index_v := index_v - 1;
        else
          simo_s  <= simo_s(data_width - 2 downto 0) & simo_s(data_width - 1);
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
    wait for clock_interval;
    clock_s <= '1';
    wait for clock_interval;
  end process;
  
end test;
