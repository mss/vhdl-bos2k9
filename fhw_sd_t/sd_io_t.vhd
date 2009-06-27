-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the sd_io.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd_t
library fhw_sd_t;
library fhw_sd;
use fhw_sd.all;
use fhw_sd.sd_globals_p.all;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------

entity sd_io_t is
  generic(
    clock_interval : time := 20 us);
end sd_io_t;

-----------------------------------------------------------------------

architecture test of sd_io_t is
  component sd_io_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      frame  : in  std_logic_frame_t;
      start  : in  std_logic;
      busy   : out std_logic;
      data   : out std_logic_byte_t;
      shift  : out std_logic;
    
      cnt_tick : out std_logic;
      cnt_done : in  std_logic;
    
      spi_start : out std_logic;
      spi_busy  : in  std_logic;
      spi_txd   : out std_logic_byte_t;
      spi_rxd   : in  std_logic_byte_t);
  end component;
  component sd_counter_e is
    generic(
      max : positive := 31);
    port(
      clock  : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;
    
      top  : in  integer range 1 to 31;
      done : out std_logic);
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal frame_i_s     : std_logic_frame_t;
  signal start_i_s     : std_logic;
  signal busy_o_s      : std_logic;
  signal data_o_s      : std_logic_byte_t;
  signal shift_o_s     : std_logic;
  signal cnt_tick_o_s  : std_logic;
  signal cnt_done_i_s  : std_logic;
  signal spi_start_o_s : std_logic;
  signal spi_busy_i_s  : std_logic;
  signal spi_txd_o_s   : std_logic_byte_t;
  signal spi_rxd_i_s   : std_logic_byte_t;
  
  signal cnt_top_s : positive;
  
  signal txd_s : std_logic_byte_t;
  signal rxd_s : std_logic_byte_t;
begin
  dut : sd_io_e port map(clock_s, reset_s,
    frame_i_s,
    start_i_s,
    busy_o_s,
    data_o_s,
    shift_o_s,
    cnt_tick_o_s,
    cnt_done_i_s,
    spi_start_o_s,
    spi_busy_i_s,
    spi_txd_o_s,
    spi_rxd_i_s);
  cnt : sd_counter_e port map(clock_s, reset_s,
    cnt_tick_o_s,
    cnt_top_s,
    cnt_done_i_s);
  
  stimulus : process
  begin
    wait for clock_interval / 4;
    
    frame_i_s <= (others => 'U');
    start_i_s <= '0';
    cnt_top_s <= 6 + (8 - 6) + 1 - 1;
    wait until falling_edge(reset_s);
    
    while true loop
      wait until rising_edge(clock_s);
      frame_i_s <= "10110101"
                 & "00000000"
                 & "11111111"
                 & "01001010"
                 & "11111111"
                 & "00000000";
      start_i_s <= '1';
      wait until rising_edge(clock_s);
      start_i_s <= '0';
      wait until falling_edge(busy_o_s);
    end loop;
  end process;
  
  rxd : process
  begin
    rxd_s <= "00000001";
    while true loop
      wait until rising_edge(spi_busy_i_s);
      rxd_s <= std_logic_vector(unsigned(rxd_s) + 1);
    end loop;
  end process;
  
  spi : process
  begin
    txd_s <= spi_txd_o_s;
    wait until rising_edge(spi_start_o_s);
    spi_rxd_i_s  <= (others => 'U');
    spi_busy_i_s <= '1';
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    spi_rxd_i_s  <= rxd_s;
    wait until rising_edge(clock_s);
    spi_busy_i_s <= '0';
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
