library ieee;
use ieee.std_logic_1164.all;

package bos2k9_globals is

  constant clock_interval_c : time   := 20 us;
  constant sd_clock_div_c : positive := 128; -- 390.625 kHz (max 400 kHz); exakt: 125
  constant sd_init_wait_c : positive := 
  
  constant sd_block_address_width_c : positive := 2;
  subtype  std_logic_block_address_t is std_logic_vector(sd_block_address_width_c - 1 downto 0);
  
  subtype  std_logic_byte_address_t is std_logic_vector(8 downto 0);

end bos2k9_globals;
