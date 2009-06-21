library ieee;
use ieee.std_logic_1164.all;

package bos2k9_globals is

  constant clock_interval_c : time := 20 ns;
  constant clock_div_c : positive  :=  8; -- TODO?

  subtype std_logic_byte_t is std_logic_vector(7 downto 0);

end bos2k9_globals;
