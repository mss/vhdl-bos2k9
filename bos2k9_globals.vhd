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

  -- The DE2 board runs with 50 MHz.
  constant clock_interval_c : time   := 20 ns;
  -- The maximum initial rate for the SD card is 400 kHz, which would
  -- result in a clock divider of 125.  To be on the safe side, we'll
  -- run at 390.625 kHz.
  constant sd_clock_div_c : positive := 128; 
  
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
