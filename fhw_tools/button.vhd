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
    clk : in std_logic;
    rst : in std_logic;
  
    input  : in  std_ulogic;
    output : out std_ulogic);
end button;

-----------------------------------------------------------------------

architecture inverted of button is
  signal input_s  : std_logic;
  signal output_s : std_logic;
begin
  input_s <= not input;
  output  <= output_s;
  toggle : process(clk, rst)
  begin
    if rst = '1' then
      output_s <= '0';
    elsif rising_edge(clk) then
      if output_s = input_s then
        output_s <= '0';
      elsif output_s = '0' then
        output_s <= '1';
      end if;
    end if;
  end process;
end inverted;
