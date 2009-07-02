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
    CLOCK_50 : in std_logic;
    
    --GPIO_0 : inout std_logic_vector(35 downto 0);
    
    KEY  : in  std_logic_vector(3 downto 0);
    SW   : in  std_logic_vector(17 downto 0);
    LEDR : out std_logic_vector(17 downto 0);
    LEDG : out std_logic_vector(8 downto 0);
    
    SD_DAT  : in  std_logic;
    SD_DAT3 : out std_logic;
    SD_CMD  : out std_logic;
    SD_CLK  : out std_logic);
end bos2k9;

-----------------------------------------------------------------------

architecture board of bos2k9 is

  component sd_host is
    generic(
      clock_interval : time     := clock_interval_c;
      clock_divider  : positive := sd_clock_div_c);
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
      clk : in std_logic;
      rst : in std_logic;
      
      input  : in  std_ulogic;
      output : out std_ulogic);
  end component;

  signal clock_s : std_logic;
  signal reset_s : std_logic;
  
  signal ready_led_s : std_logic;
  signal error_led_s : std_logic;
  
  signal init_btn_s  : std_logic;
  signal start_btn_s : std_logic;
  
  signal byte_led_s  : std_logic_vector(7 downto 0);
  signal byte_sw1_s  : std_logic_vector(7 downto 0);
  signal byte_sw2_s  : std_logic_vector(7 downto 0);
  
  signal spi_s : spi_bus_t;
  
begin
  clock_s <= CLOCK_50;
  --reset_s <= GPIO_0(15);
  reset_s <= not SW(17);

  --GPIO_0 <= (others => 'Z');
  
  init_button : button port map(clock_s, reset_s,
    input  => KEY(0),
    output => init_btn_s);
  start_button : button port map(clock_s, reset_s,
    input  => KEY(1),
    output => start_btn_s);
  
  spi_s.miso <= SD_DAT;
  SD_CMD     <= spi_s.mosi;
  SD_CLK     <= spi_s.sck;
  SD_DAT3    <= spi_s.cs;
  
  LEDG <= (
    7 => spi_s.miso,
    6 => spi_s.mosi,
    5 => spi_s.sck,
    4 => spi_s.cs,
    1 => ready_led_s,
    0 => error_led_s,
    others => '0');
  LEDR <= (
   17 => not reset_s,
    7 => byte_led_s(7),
    6 => byte_led_s(6),
    5 => byte_led_s(5),
    4 => byte_led_s(4),
    3 => byte_led_s(3),
    2 => byte_led_s(2),
    1 => byte_led_s(1),
    0 => byte_led_s(0),
    others => '0');
  byte_sw1_s <= SW(7 downto 0);
  byte_sw2_s <= SW(15 downto 8);
  
  guts : block
    signal sd_init_s    : std_logic;
    signal sd_ready_s   : std_logic;
    signal sd_error_s   : std_logic;
    signal sd_address_s : std_logic_block_address_t;
    signal sd_start_s   : std_logic;
    signal sd_data_s    : std_logic_byte_t;
    signal sd_latch_s   : std_logic;
    signal sd_shift_s   : std_logic;
  
    signal bl_address_s : std_logic_byte_address_t;
  begin

    ready_led_s <= sd_ready_s;
    error_led_s <= sd_error_s;
    
    sd_init_s  <= init_btn_s;
    sd_start_s <= start_btn_s;
  
    sd_address_s(std_logic_block_address_t'high downto std_logic_byte_t'high + 1) <= (others => '0');
    sd_address_s(std_logic_byte_t'range) <= byte_sw1_s;
    bl_address_s(std_logic_byte_address_t'high downto std_logic_byte_t'high + 1) <= (others => '0');
    bl_address_s(std_logic_byte_t'range) <= byte_sw2_s;
  
    sd_io : sd_host port map(
      clk => clock_s,
      rst => reset_s,
    
      init    => sd_init_s, 
      ready   => sd_ready_s,
      error   => sd_error_s,
      address => sd_address_s,
      start   => sd_start_s,
      rxd     => sd_data_s,
      shd     => sd_latch_s,
    
      miso  => spi_s.miso,
      mosi  => spi_s.mosi,
      sck   => spi_s.sck,
      cs    => spi_s.cs);
    mmu : bos2k9_mmu port map(
      clock => clock_s,
      reset => reset_s,
      write_next => sd_latch_s,
      write_addr => open,
      write_data => sd_data_s,
      read_addr  => bl_address_s,
      read_data  => byte_led_s);
  
  end block;
end board;
