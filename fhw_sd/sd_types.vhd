-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Some SD related types.

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sd_types is

  subtype  block_address_width_t is integer range 1 to 12;

  subtype  std_logic_cmd_t is std_logic_vector(5 downto 0);
  subtype  std_logic_arg_t is std_logic_vector(31 downto 0);
  subtype  std_logic_rsp_t is std_logic_vector(7 downto 0);
  
  function to_cmd(
    number : integer range 0 to 63) return std_logic_cmd_t;
  function to_arg(
    number : integer range 0 to 65535) return std_logic_arg_t;

end sd_types;

package body sd_types is

  function to_cmd(
    number : integer range 0 to 63) return std_logic_cmd_t is
  begin
    return std_logic_vector(to_unsigned(number, std_logic_cmd_t'length));
  end to_cmd;
  function to_arg(
    number : integer range 0 to 65535) return std_logic_arg_t is
  begin
    return std_logic_vector(to_unsigned(number, 32));
  end to_arg;

end sd_types;
