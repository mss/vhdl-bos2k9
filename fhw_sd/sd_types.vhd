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

package sd_types is

  subtype  block_address_width_t is integer range 1 to 12;

  subtype  std_logic_cmd_t is std_logic_vector(5 downto 0);
  subtype  std_logic_arg_t is std_logic_vector(31 downto 0);
  subtype  std_logic_rsp_t is std_logic_vector(6 downto 0);

end sd_types;
