-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the spi_master in all four possible modes!
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi_t
library fhw_spi_t;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------

entity spi_master_all_t is
end spi_master_all_t;

-----------------------------------------------------------------------

architecture test of spi_master_all_t is
  component spi_master_t
    generic(
      spi_mode : natural;
      repeat   : natural);
  end component;
  constant repeat_c : natural := 1;
begin
  mode0 : spi_master_t generic map(0, repeat_c);
  mode1 : spi_master_t generic map(1, repeat_c);
  mode2 : spi_master_t generic map(2, repeat_c);
  mode3 : spi_master_t generic map(3, repeat_c);
end test;
