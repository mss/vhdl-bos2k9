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
    odd  : std_logic) return std_logic;
  
end rs232_globals_p;

package body rs232_globals_p is

  function get_parity(
    word : std_logic_vector;
    odd  : std_logic) return std_logic is
    variable gen_v : std_logic_vector(word'high + 1 downto word'low);
    variable par_v : std_logic;
  begin
    gen_v(word'high + 1) := odd;
    gen_v(word'high downto word'low) := word;
    par_v := '0';
    for i in gen_v'high downto gen_v'low loop
      par_v := par_v xor gen_v(i);
    end loop;
    return par_v;
  end get_parity;
  
end rs232_globals_p;
