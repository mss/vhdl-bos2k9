-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity which manages the busy line, wired to the
-- output `status`. It will go high once `start` was seen high and
-- stay like this until `stop` occurs. The latter overrides the line.
--
-- It is driven by `clock` on the rising edge and `reset` is active
-- high.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;

library ieee;
use ieee.std_logic_1164.all;

entity sd_starter_e is
  port(
    clock   : in  std_logic;
    reset   : in  std_logic;
    
    start   : in  std_logic;
    stop    : in  std_logic;
    
    status  : out std_logic);
end sd_starter_e;

-----------------------------------------------------------------------

architecture rtl of sd_starter_e is
  signal running_s  : std_logic;
begin
  status <= running_s;
  
  runner : process(clock, reset, stop)
  begin
    if reset = '1' then
      running_s <= '0';
    elsif rising_edge(clock) then
      -- Enable line of the status FF.
      if (start or stop) = '1' then
        -- Input of the status FF.
        running_s <= start and not stop;
      end if;
    end if;
  end process;

end rtl;
