-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232
library fhw_rs232;

library ieee;
use ieee.std_logic_1164.all;

entity sd_host is
  generic(
    clock_interval : time;
    clock_divider  : positive); -- TODO: calculate this based on clock_interval
  port(
    clk : in  std_logic;
    rst : in  std_logic);
 end sd_host;
 
-----------------------------------------------------------------------

architecture rtl of sd_host is
begin
  
end rtl;
