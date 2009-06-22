-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_tools
library fhw_tools;

library ieee;
use ieee.std_logic_1164.all;

entity button is
  port(
    input  : in  std_ulogic;
    output : out std_ulogic);
end button;

-----------------------------------------------------------------------

architecture inverted of button is
begin
  output <= not input;
end inverted;
