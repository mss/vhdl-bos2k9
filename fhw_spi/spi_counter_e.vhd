-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity implementing a counter. It is driven by
-- `clock` on the edge specified by the generic `edge` (low means
-- falling edge, high means rising). `reset` is active high.
--
-- While `enable` is high, it counts the number of ticks given via the
-- generic `count`. When reached, `done` is high for exactly one
-- `clock` (even if `enable` goes low).
--
-- It is possible to override and reset the counter by driving
-- `override` high; `done` is high while `override` is high.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi
library fhw_spi;

library ieee;
use ieee.std_logic_1164.all;

entity spi_counter_e is
  generic(
    count : positive;
    edge  : std_logic := '1');
  port(
    clock  : in  std_logic;
    reset  : in  std_logic;
    enable : in  std_logic;
    
    override : in std_logic;
    
    done : out std_logic);
end spi_counter_e;

-----------------------------------------------------------------------

architecture rtl of spi_counter_e is
  -- Use a subtype to please ModelSim's interpretation of attributes.
  subtype count_t is natural range 0 to count - 1;
  signal count_s : count_t;
begin
  counter : process(clock, reset, enable, override)
  begin
    if reset = '1' then
      count_s <= 0;
      done    <= '0';
    elsif clock'event and clock = edge then
      -- `done` must be high for a single `clock` only, even if
      -- `enable` is low.
      done <= '0';
      -- This could become an Enable line for one of the FFs.
      if (enable or override) = '1' then
        if (count_s = count_t'high) or (override = '1') then
          count_s <= count_t'low;
          done <= '1';
        else
          count_s <= count_s + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
