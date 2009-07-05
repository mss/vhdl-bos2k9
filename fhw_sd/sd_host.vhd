-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This SD host is capable of reading blocks a 512 Byte from first
-- generation standard Secure Digital (SD) cards (version 1 of the 
-- standard, up to 4 GiB).  The later extensions SDHC and SDXC are not 
-- supported.
--
-- It depends on (and uses) the SPI bus implemented in `fhw_sd`.  The 
-- SPI signals `miso`, `mosi`, `sck`, and `cs` must be connected to
-- card's pins `DAT`, `CMD`, `CLK`, and `DAT3`, respectively.
--
-- The flash devices can be accessed with to a theoretical speed of
-- 900 kB/s and more but the initialization has to be done at a lower 
-- speed of max 50 kB/s, ie. an SPI clock of 400 kHz.  This master uses
-- a constant clock divider given by the generic `clock_divider`
-- (relative to `clock_interval`) and doesn't increase the speed after
-- initialization is done.
-- 
-- The entity is diven by the clock `clk` and the reset `rst` is high 
-- active.
--
-- After reset, the SD card can be inserted and initialized by driving
-- `init` high.  Once the card is successfully initialized (which can
-- take a while), `ready` goes high.  If an error occurs, `error` is
-- high and the SD error can be read from `rxd`.
--
-- The block address has to be applied to `address` and once the cards
-- is `ready`, the addressed block can be read by driving `start` high.
-- `address has to be stable for six clocks, then the next address can
-- be set.  `start` may stay high.
--
-- Data is shifted out via `rxd`, each byte signaled by `shd`.  `rxd`
-- is stable until the next byte arrives or the next command is sent.
-- Between commands the output is undefined and can change arbitrarly.
--
-- If an error occurs, `error` goes high and the card is reset and has
-- to be reinitialized.
-- 
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

    init  : in  std_logic;
    ready : out std_logic;
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
  
  component sd_flow_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      init    : in  std_logic;
      ready   : out std_logic;
      
      address : in std_logic_block_address_t;
      start   : in std_logic;
    
      command  : out std_logic_cmd_t;
      argument : out std_logic_arg_t;
      trigger  : out std_logic;
      shifting : in  std_logic;
      error    : in  std_logic;
      idled    : in  std_logic;
      resetted : out std_logic);
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
  
  -- These signals connect the two helper entities to each other.
  signal sd_command_s  : std_logic_cmd_t;
  signal sd_argument_s : std_logic_arg_t;
  signal sd_trigger_s  : std_logic;
  signal sd_shifting_s : std_logic;
  signal sd_error_s    : std_logic;
  signal sd_idled_s    : std_logic;
  
  -- These signals are the SPI bus management.
  signal spi_start_s : std_logic;
  signal spi_busy_s  : std_logic;
  signal spi_txd_s   : std_logic_byte_t;
  signal spi_rxd_s   : std_logic_byte_t;
  signal spi_cs_s    : std_logic;
  
begin
  -- Direct output.
  rxd <= spi_rxd_s;
  -- Error is branched out as well.
  error <= sd_error_s;
  
  -- The command flow state machine.
  driver : sd_flow_e port map(
    clock => clk,
    reset => rst,
    
    init    => init,
    ready   => ready,
    
    address => address,
    start   => start,
    
    command  => sd_command_s,
    argument => sd_argument_s,
    trigger  => sd_trigger_s,
    shifting => sd_shifting_s,
    error    => sd_error_s,
    idled    => sd_idled_s,
    resetted => spi_cs_s);
  
  -- The command parser and data shifter.
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
    
    spi_start => spi_start_s,
    spi_busy  => spi_busy_s,
    spi_txd   => spi_txd_s,
    spi_rxd   => spi_rxd_s);
  
  -- The SPI master.
  cs <= spi_cs_s;
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
