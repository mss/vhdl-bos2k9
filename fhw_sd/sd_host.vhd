-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description
-- NOTE: No SDHC (max. 2 GiB)

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
      error : out std_logic;
    
      command  : out std_logic_cmd_t;
      argument : out std_logic_arg_t;
      trigger  : out std_logic;
      response : in  std_logic_rsp_t;
      shifting : in  std_logic);
  end component;
  
  component sd_io_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      command  : in  std_logic_cmd_t;
      argument : in  std_logic_arg_t;
      trigger  : in  std_logic;
      response : out std_logic_rsp_t;
      shifting : out std_logic;
      
      data  : out std_logic_byte_t;
      shift : out std_logic;
      
      spi_start : out std_logic;
      spi_busy  : in  std_logic;
      spi_txd   : out std_logic_byte_t;
      spi_rxd   : in  std_logic_byte_t);
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
  signal sd_response_s : std_logic_rsp_t;
  signal sd_shifting_s : std_logic;
  
  signal spi_start_s : std_logic;
  signal spi_busy_s  : std_logic;
  signal spi_txd_s   : std_logic_byte_t;
  signal spi_rxd_s   : std_logic_byte_t;
  signal spi_cs_n    : std_logic;
  
begin
  
  driver : sd_manager_e port map(
    clock => clk,
    reset => rst,
    
    address => address,
    start   => start,
    
    ready => ready,
    busy  => busy,
    error => error,
    
    command  => sd_command_s,
    argument => sd_argument_s,
    trigger  => sd_trigger_s,
    response => sd_response_s,
    shifting => sd_shifting_s);
  
  io : sd_io_e port map(
    clock => clk,
    reset => rst,
    
    command  => sd_command_s,
    argument => sd_argument_s,
    trigger  => sd_trigger_s,
    response => sd_response_s,
    shifting => sd_shifting_s,
    
    data  => rxd,
    shift => shd,
  
    spi_start => spi_start_s,
    spi_busy  => spi_busy_s,
    spi_txd   => spi_txd_s,
    spi_rxd   => spi_rxd_s);
  
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
  cs <= spi_cs_n;
end rtl;
