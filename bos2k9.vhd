library ieee;
use ieee.std_logic_1164.all;

library fhw_spi;
use fhw_spi.all;

library fhw_tools;
use fhw_tools.all;

use work.bos2k9_globals.all;

-----------------------------------------------------------------------

entity bos2k9 is
  port(
    clk : in  std_logic; --PIN_N2
    rst : in  std_logic; --PIN_G25
    
    start_btn : in  std_logic;
    busy_led  : out std_logic;
    
    byte_swc : in  std_logic_byte_t;
    byte_led : out std_logic_byte_t;
    
    spi_miso : in  std_logic;  --PIN_AD24
    spi_mosi : out std_logic;  --PIN_Y21
    spi_sck  : out std_logic;  --PIN_AD25
    spi_cs   : out std_logic); --PIN_AC23
end bos2k9;

-----------------------------------------------------------------------

architecture board of bos2k9 is

  component spi_master 
    generic(
      clk_div    : positive := clock_div_c;
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
  
  component button
    port(
      input  : in  std_ulogic;
      output : out std_ulogic);
  end component;

  signal start_s : std_logic;
  signal busy_s  : std_logic;
  
  signal ibuf_s  : std_logic_byte_t;
  signal obuf_s  : std_logic_byte_t;
  
begin
  spi_cs <= not busy_s;
  busy_led <= busy_s;
  
  obuf_s <= byte_swc;
  byte_led <= ibuf_s;
  
  spi_io : spi_master port map(
    clk => clk,
    rst => rst,
    
    start => start_s,
    busy  => busy_s,
    
    txd   => obuf_s,
    rxd   => ibuf_s,
    
    miso  => spi_miso,
    mosi  => spi_mosi,
    sck   => spi_sck);
  
  start_button : button port map(
    input  => start_btn,
    output => start_s);
end board;
