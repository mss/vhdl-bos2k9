-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description
-- NOTE: No SDHC (max. 4 GiB)

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals_p.all;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_host is
  generic(
    clock_interval : time;
    clock_divider  : positive); -- TODO: calculate this based on clock_interval
  port(
    clk : in  std_logic;
    rst : in  std_logic;

    ready : out std_logic;
    busy  : out std_logic;
    error : out std_logic;
    
    address : in  std_logic_block_address_t;
    start   : in  std_logic;
    rxd     : out std_logic_byte_t;
    shd     : out std_logic;
    
    miso  : in  std_logic;
    mosi  : out std_logic;
    sck   : out std_logic;
    cs    : out std_logic);
 end sd_host;
 
-----------------------------------------------------------------------

architecture rtl of sd_host is
  
  component sd_manager_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      address : in std_logic_block_address_t;
      start   : in std_logic;
      
      ready : out std_logic;
      busy  : out std_logic;
    
      command  : out std_logic_cmd_t;
      argument : out std_logic_arg_t;
      trigger  : out std_logic;
      shifting : in  std_logic;
      error    : in  std_logic;
      idled    : in  std_logic);
  end component;
  
  component sd_parser_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      command  : in  std_logic_cmd_t;
      argument : in  std_logic_arg_t;
      trigger  : in  std_logic;
      shifting : out std_logic;
      error    : out std_logic;
      idled    : out std_logic;
      
      pipe     : out std_logic;
      
      cnt_top  : out counter_top_t;
      cnt_tick : out std_logic;
      cnt_done : in  std_logic;
    
      spi_start : out std_logic;
      spi_busy  : in  std_logic;
      spi_txd   : out std_logic_byte_t;
      spi_rxd   : in  std_logic_byte_t;
      spi_cs    : out std_logic);
  end component;

  component sd_counter_e is
    generic(
      max : positive := counter_max_c);
    port(
      clock  : in  std_logic;
      enable : in  std_logic;
    
      rewind : in  std_logic;
    
      top  : in  counter_top_t;
      done : out std_logic);
  end component;
  
  component spi_master 
    generic(
      clk_div    : positive := clock_divider;
      data_width : positive := std_logic_byte_t'length);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
    
      start : in  std_logic;
      busy  : out std_logic;
    
      txd   : in  std_logic_byte_t;
      rxd   : out std_logic_byte_t;
    
      miso  : in  std_logic;
      mosi  : out std_logic;
      sck   : out std_logic);
  end component;
  
  signal sd_command_s  : std_logic_cmd_t;
  signal sd_argument_s : std_logic_arg_t;
  signal sd_trigger_s  : std_logic;
  signal sd_shifting_s : std_logic;
  signal sd_error_s    : std_logic;
  signal sd_idled_s    : std_logic;
  
  signal cnt_top_s  : counter_top_t;
  signal cnt_tick_s : std_logic;
  signal cnt_done_s : std_logic;
  
  signal spi_start_s : std_logic;
  signal spi_busy_s  : std_logic;
  signal spi_txd_s   : std_logic_byte_t;
  signal spi_rxd_s   : std_logic_byte_t;
  signal spi_cs_s    : std_logic;
  
begin
  rxd <= spi_rxd_s;
  
  error <= sd_error_s;
  
  driver : sd_manager_e port map(
    clock => clk,
    reset => rst,
    
    address => address,
    start   => start,
    
    ready => ready,
    busy  => busy,
    
    command  => sd_command_s,
    argument => sd_argument_s,
    trigger  => sd_trigger_s,
    shifting => sd_shifting_s,
    error    => sd_error_s,
    idled    => sd_idled_s);
  
  parser : sd_parser_e port map(
    clock => clk,
    reset => rst,
    
    command  => sd_command_s,
    argument => sd_argument_s,
    trigger  => sd_trigger_s,
    shifting => sd_shifting_s,
    error    => sd_error_s,
    idled    => sd_idled_s,
    
    pipe => shd,
    
    cnt_top  => cnt_top_s,
    cnt_tick => cnt_tick_s,
    cnt_done => cnt_done_s,
    
    spi_start => spi_start_s,
    spi_busy  => spi_busy_s,
    spi_txd   => spi_txd_s,
    spi_rxd   => spi_rxd_s,
    spi_cs    => spi_cs_s);
  
  counter : sd_counter_e port map(
    clock => clk,
    enable => cnt_tick_s,
    
    rewind => sd_trigger_s,
    
    top  => cnt_top_s,
    done => cnt_done_s);
  
  cs <= not spi_cs_s;
  spi : spi_master port map(
    clk => clk,
    rst => rst,
    
    start => spi_start_s,
    busy  => spi_busy_s,
    txd   => spi_txd_s,
    rxd   => spi_rxd_s,
    
    miso  => miso,
    mosi  => mosi,
    sck   => sck);
end rtl;
