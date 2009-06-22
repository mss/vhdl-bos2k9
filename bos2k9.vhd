library ieee;
use ieee.std_logic_1164.all;

library fhw_sd;
use fhw_sd.sd_host;

library fhw_tools;
use fhw_tools.all;
use fhw_tools.types.all;

use work.bos2k9_globals.all;

-----------------------------------------------------------------------

entity bos2k9 is
  port(
    clk : in  std_logic; --PIN_N2
    rst : in  std_logic; --PIN_G25
    
    start_btn : in  std_logic;
    busy_led  : out std_logic;
    
    byte_sw1 : in  std_logic_byte_t;
    byte_sw2 : in  std_logic_byte_t;
    byte_led : out std_logic_byte_t;
    
    spi_miso : in  std_logic;  --PIN_AD24
    spi_mosi : out std_logic;  --PIN_Y21
    spi_sck  : out std_logic;  --PIN_AD25
    spi_cs   : out std_logic); --PIN_AC23
end bos2k9;

-----------------------------------------------------------------------

architecture board of bos2k9 is

  component sd_host is
    generic(
      clock_interval      : time     := clock_interval_c;
      clock_divider       : positive := sd_clock_div_c;
      block_address_width : positive := sd_block_address_width_c);
    port(
      clk : in  std_logic;
      rst : in  std_logic;

      ready : out std_logic;
      busy  : out std_logic;
      
      address : std_logic_block_address_t;
      start   : in  std_logic;
      rxd     : out std_logic_byte_t;
      shd     : out std_logic;
      
      miso  : in  std_logic;
      mosi  : out std_logic;
      sck   : out std_logic;
      cs    : out std_logic);
  end component;
  
  component bos2k9_mmu is
    port(
      clock : in  std_logic;
      reset : in  std_logic;
    
      write_next : in  std_logic;
      write_addr : out std_logic_byte_address_t;
      write_data : in  std_logic_byte_t;
    
      read_addr : in  std_logic_byte_address_t;
      read_data : out std_logic_byte_t);
  end component;
  
  component button
    port(
      input  : in  std_ulogic;
      output : out std_ulogic);
  end component;

  signal sd_ready_s   : std_logic;
  signal sd_busy_s    : std_logic;
  signal sd_address_s : std_logic_block_address_t;
  signal sd_start_s   : std_logic;
  signal sd_data_s    : std_logic_byte_t;
  signal sd_latch_s   : std_logic;
  signal sd_shift_s   : std_logic;
  
  signal bl_address_s : std_logic_byte_address_t;
  
  
begin
  busy_led <= sd_busy_s;
  
  sd_address_s <= byte_sw1(sd_block_address_width_c - 1 downto 0);
  bl_address_s <= '0' & byte_sw2;
  
  sd_io : sd_host port map(
    clk => clk,
    rst => rst,
    
    ready   => sd_ready_s,
    busy    => sd_busy_s,
    address => sd_address_s,
    start   => sd_start_s,
    rxd     => sd_data_s,
    shd     => sd_latch_s,
    
    miso  => spi_miso,
    mosi  => spi_mosi,
    sck   => spi_sck,
    cs    => spi_cs);
  mmu : bos2k9_mmu port map(
    clock => clk,
    reset => rst,
    write_next => sd_latch_s,
    write_addr => open,
    write_data => sd_data_s,
    read_addr  => bl_address_s,
    read_data  => byte_led);
  
  start_button : button port map(
    input  => start_btn,
    output => sd_start_s);
end board;
