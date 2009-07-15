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
use ieee.numeric_std.all;

package rs232_globals_p is
  
  function get_parity(
    word : std_logic_vector;
    even : std_logic) return std_logic;
  
end rs232_globals_p;

package body rs232_globals_p is

  function get_parity(
    word : std_logic_vector;
    even : std_logic) return std_logic is
    variable par_v : std_logic;
  begin
    par_v := not even;
    for i in word'high downto word'low loop
      par_v := par_v xor word(i);
    end loop;
    return par_v;
  end get_parity;
  
end rs232_globals_p;
