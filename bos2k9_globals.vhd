-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Project settings, constants and global helper types.
--
-----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library fhw_sd;
use fhw_sd.sd_globals_p.all;

package bos2k9_globals is

  -- The DE2 board runs at 50 MHz.
  constant clock_interval_c  : time     := 20 ns;
  constant clock_1us_ticks_c : positive := 50;
  constant clock_1ms_ticks_c : positive := clock_1us_ticks_c * 1000;
  
  constant init_ticks_c : positive := clock_1ms_ticks_c;
  
  -- The maximum initial rate for the SD card is 400 kHz, which would
  -- result in a clock divider of 125.  To be on the safe side, we'll
  -- run at 390.625 kHz.
  constant sd_clock_div_c : positive := 128; 
  
  -- 5208.33
  constant ser_9600_c   : positive := 5208;
  -- 2604.166
  constant ser_19200_c  : positive := 2604;
  -- 868.055
  constant ser_57600_c  : positive := 868;
  -- 434.0277
  constant ser_115200_c : positive := 434;
  -- Choose one.
  constant ser_clock_div_c : positive := ser_9600_c;

  constant ser_odd_parity_c  : std_logic := '0';
  constant ser_even_parity_c : std_logic := '1';

  constant ser_parity_enabled_c : std_logic := '1';
  constant ser_parity_type_c    : std_logic := ser_even_parity_c;
  
  type ser_bus_t is record
    rx : std_logic;
	tx : std_logic;
  end record;
  
  -- Pull in this type from fhw_sd.sd_globals_p; it is used to address
  -- a 512 B block on the SD card.
  subtype  std_logic_block_address_t is std_logic_block_address_t;
  -- The first block.
  constant zero_block_address_c : std_logic_block_address_t := (others => '0');
  
  -- There are 512 B per block, so we need a 9-bit address to access
  -- the bytes.
  constant byte_address_width_c : positive := 9;
  subtype  std_logic_byte_address_t is std_logic_vector(byte_address_width_c - 1 downto 0);
  -- The first byte.
  constant zero_byte_address_c : std_logic_byte_address_t := (others => '0');

end bos2k9_globals;
