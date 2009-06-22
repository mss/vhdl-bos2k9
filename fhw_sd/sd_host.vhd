-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description
-- NOTE: No SDHC (max. 2 GiB)

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_host is
  generic(
    clock_interval      : time;
    clock_divider       : positive; -- TODO: calculate this based on clock_interval
    block_address_width : integer range 1 to 12 := 12); -- No SDHC, so max is 4096 blocks a 512 byte
  port(
    clk : in  std_logic;
    rst : in  std_logic;

    ready : out std_logic;
    busy  : out std_logic;
    
    address : std_logic_vector(block_address_width - 1 downto 0);
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

  signal spi_start_s : std_logic;
  signal spi_busy_s  : std_logic;
  signal spi_txd_s : std_logic_byte_t;
  signal spi_rxd_s : std_logic_byte_t;
  
begin
  
  
  spi_io : spi_master port map(
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
