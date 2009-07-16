-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity implementing a counter. It is driven by
-- `clock` on the rising edge. `reset` is active high.
--
-- While `enable` is high, it counts the number of ticks given via the
-- generic `count`. When reached, `done` is high for exactly one
-- `clock` (even if `enable` goes low).
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity bos2k9_counter_e is
  generic(
    count : positive);
  port(
    clock  : in  std_logic;
    reset  : in  std_logic;
    enable : in  std_logic;
    
    done : out std_logic);
end bos2k9_counter_e;

-----------------------------------------------------------------------

architecture rtl of bos2k9_counter_e is
  -- Use a subtype to please ModelSim's interpretation of attributes.
  subtype count_t is natural range 0 to count - 1;
  signal count_s : count_t;
begin
  counter : process(clock, reset, enable)
  begin
    if reset = '1' then
      count_s <= 0;
      done    <= '0';
    elsif rising_edge(clock) then
      -- `done` must be high for a single `clock` only, even if
      -- `enable` is low.
      done <= '0';
      -- This could become an Enable line for one of the FFs.
      if enable = '1' then
        if count_s = count_t'high then
          count_s <= count_t'low;
          done <= '1';
        else
          count_s <= count_s + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
