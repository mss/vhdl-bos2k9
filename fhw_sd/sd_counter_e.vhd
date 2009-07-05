-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity implementing a counter. It is driven by
-- `clock` and and can only be reset by applying a high signal to
-- `rewind` for at least one `clock`.
--
-- 
-- While `enable` is high, it counts the number of ticks given via 
-- `top`; the maximim is specified by the generic `max`. When that
-- value is reached, `done` is high for exactly one
-- `clock` (even if `enable` goes low).
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;

library ieee;
use ieee.std_logic_1164.all;

entity sd_counter_e is
  generic(
    max : positive);
  port(
    clock  : in  std_logic;
    enable : in  std_logic;
    
    rewind : in  std_logic;
    
    top  : in  natural range 0 to max;
    done : out std_logic);
end sd_counter_e;

-----------------------------------------------------------------------

architecture rtl of sd_counter_e is
  -- Use a subtype to please ModelSim's interpretation of attributes.
  subtype count_t is natural range 0 to max;
  signal  count_s : count_t;
begin
  counter : process(clock)
  begin
    if rising_edge(clock) then
      -- `done` must be high for a single `clock` only, even if
      -- `enable` is low.
      done <= '0';
      if rewind = '1' then
        count_s <= 0;
      elsif enable  = '1' then
        if count_s = top then
          count_s <= 0;
          done    <= '1';
        else
          count_s <= count_s + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
