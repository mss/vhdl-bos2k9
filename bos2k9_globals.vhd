library ieee;
use ieee.std_logic_1164.all;

package bos2k9_globals is

  constant clock_interval_c : time   := 20 us;
  constant sd_clock_div_c : positive := 128; -- 390.625 kHz (max 400 kHz)
  
  constant sd_max_blocks_c : positive := 2;
  subtype sd_address_t is integer range 0 to sd_max_blocks_c - 1;

end bos2k9_globals;
