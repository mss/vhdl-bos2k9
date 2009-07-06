-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- The project top level entity.
--
-- It implements a simple test setup which can read data from an SD 
-- card.  Blocks are read in 512 Byte blocks, so both block addresses
-- and byte addresses (relative to the block start) can be specified.
-- The system starts up doing nothing, an init button has to be pressed
-- to initialize the card and afterwards the selected block can be read
-- to an internal buffer.
--
-- This is designed around the DE2 evaluation board.  To simplify
-- development, the ports of the entity are named after the file
-- `DE2_Pin_Table.pdf`, which is part of the DE2 documentation.
-- The PDF file was converted to a TCL file and is included in this
-- project as `de2_pins.tcl` and can be copied to the `bos2k9.qsf`
-- project file.  This has the side effect that Quartus will complain
-- that some of these pins are stuck to GND or not used; these 
-- warnings can be ignored.
--
-- The following pins are used:
--  * `CLOCK_50` is the 50 MHz system clock.
--  * `KEY` are the four push button which are low-active.
--  * `SW` are the eighteen on-off switches.
--  * `LEDR` are the eighteen red LEDs above the switches.
--  * `LEDG` are the nine green LEDs; the low eight are located above
--    the push buttons, the ninth is above the row of red LEDs.
--  * `SD_DAT` is the SPI MISO.
--  * `SD_CMD` is the SPI MOSI.
--  * `SD_DAT3` is the SPI CS.
--  * `SD_CLK` is the SPI SCK.
--
-- LEDG(0) should be always on and represents a powered system. The 
-- `reset` is wired to `SW(17)`, so the switch should be off when these
-- system is started.  Once `reset` is off (ie. the switch on), the card
-- can be initialized (and later reset) by pressing `KEY(0)`.  Once
-- LEDG(2) is led, the system is ready to read a block; if an error 
-- occurs, LEDG(1) is switched on instead.
--
-- The low eight bits of the block address can be specified by the
-- first eight `SW`es, ie. SW(0) to SW(7).  Only the first 256 blocks 
-- of 4096 possible ones (on 2 GiB SD cards; SDHC is not supported) can 
-- be read.  `KEY(1)` starts the reading of the selected block.
--
-- The used `button` entity ensures that even with really slow fingers,
-- the button press is only signaled once.  As the buttons on the DE2
-- board tend to break, this cannot be ensured but a longer press 
-- doesn't break anything.
--
-- The currently via SW(8) to SW(15) selected byte is displayed on the
-- LEDs LEDR(0) to LEDR(7) and inverted on LEDR(8) to LEDR(15).
--
-- Because only eight address bits are wired, only half the block can 
-- be displayed.  Both this and the above limitation doesn't matter as 
-- this is a test setup only.
--
-- For debugging purposes, the SPI bus is also wired to the LEDs 
-- LEDG(7) to LEDG(4). 
-----------------------------------------------------------------------

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
    
    KEY  : in  std_logic_vector(3 downto 0);
    SW   : in  std_logic_vector(17 downto 0);
    LEDR : out std_logic_vector(17 downto 0);
    LEDG : out std_logic_vector(8 downto 0);
    
    SD_DAT  : in  std_logic;
    SD_CMD  : out std_logic;
    SD_DAT3 : out std_logic;
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
  reset_s <= not SW(17);

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
   15 => not byte_led_s(7),
   14 => not byte_led_s(6),
   13 => not byte_led_s(5),
   12 => not byte_led_s(4),
   11 => not byte_led_s(3),
   10 => not byte_led_s(2),
    9 => not byte_led_s(1),
    8 => not byte_led_s(0),
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
