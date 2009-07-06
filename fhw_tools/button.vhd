-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Synchronized, inverting and sticky finger resistant button.
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_tools
library fhw_tools;

library ieee;
use ieee.std_logic_1164.all;

entity button is
  port(
    clk : in std_logic;
    rst : in std_logic;
  
    input  : in  std_ulogic;
    output : out std_ulogic);
end button;

-----------------------------------------------------------------------

architecture inverted of button is
  signal input_s  : std_logic;
  signal buffer_s : std_logic;
  signal output_s : std_logic;
begin
  bufr : process(clk, rst)
  begin
    if rst = '1' then
      input_s <= '0';
    elsif rising_edge(clk) then
      -- Buffer input against hazards.
      input_s <= input;
    end if;
  end process;
  togl : process(clk, rst)
  begin
    if rst = '1' then
      buffer_s <= '0';
      output_s <= '0';
    elsif rising_edge(clk) then
      -- Invert and remember input.
      buffer_s <= not input_s;
      -- No sticky fingers.
      output_s <= not input_s and not buffer_s;
    end if;
  end process;
  output <= output_s;
end inverted;
