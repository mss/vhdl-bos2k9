-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity implementing a counter. It is driven by
-- `clk` on the rising edge. `rst` is active high.
--
-- While `en` is high, it counts the number of ticks given via the
-- generic `count`. When reached, `done` is high for exactly one
-- `clk` (even if `en` goes low). The counter can be cleared via 
-- `clr`.
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity bos2k9_counter is
  generic(
    cnt  : positive);
  port(
    clk  : in  std_logic;
    rst  : in  std_logic;
    en   : in  std_logic;
    clr  : in  std_logic;
    done : out std_logic);
end bos2k9_counter;

-----------------------------------------------------------------------

architecture rtl of bos2k9_counter is
  -- Use a subtype to please ModelSim's interpretation of attributes.
  subtype count_t is natural range 0 to cnt - 1;
  signal count_s : count_t;
begin
  counter : process(clk, rst, en)
  begin
    if rst = '1' then
      count_s <= 0;
      done    <= '0';
    elsif rising_edge(clk) then
      -- `done` must be high for a single `clk` only, even if
      -- `en` is low.
      done <= '0';
      -- This could become an en line for one of the FFs.
      if (en or clr) = '1' then
        if clr = '1' then
          count_s <= count_t'low;
        elsif count_s = count_t'high then
          count_s <= count_t'low;
          done <= '1';
        else
          count_s <= count_s + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
