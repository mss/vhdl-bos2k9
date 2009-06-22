-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Some global types.

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_tools
library fhw_tools;

library ieee;
use ieee.std_logic_1164.all;

package types is

  subtype std_logic_byte_t is std_logic_vector(7 downto 0);

end types;
