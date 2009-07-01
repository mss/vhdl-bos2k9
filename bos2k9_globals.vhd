library ieee;
use ieee.std_logic_1164.all;

library fhw_sd;
use fhw_sd.sd_globals_p.all;

package bos2k9_globals is

  constant clock_interval_c : time   := 20 ns;
  constant sd_clock_div_c : positive := 128; -- 390.625 kHz (max 400 kHz); exakt: 125
  
  subtype  std_logic_block_address_t is std_logic_block_address_t;
  constant zero_block_address_c : std_logic_block_address_t := (others => '0');
  
  constant byte_address_width_c : positive := 9; -- 512 bytes per block
  subtype  std_logic_byte_address_t is std_logic_vector(byte_address_width_c - 1 downto 0);
  constant zero_byte_address_c : std_logic_byte_address_t := (others => '0');

end bos2k9_globals;
