-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity implementing a shift register. It is driven
-- by `clock` on the rising edge. As it doesn't have a reset line, the
-- initial state is undefined but can be preset parallely by `preload`
-- while `load` is high.
--
-- While `enable` is high, each `clock` the `data` is shifted left and
-- the lowest bit is filled up with `input`. Data is NOT shifted out
-- into `output` but discared; `output` is simply wired to the top
-- `data` bit.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi
library fhw_spi;

library ieee;
use ieee.std_logic_1164.all;

entity spi_shifter_e is
  generic(
    data_width : positive);
  port(
    clock  : in  std_logic;
    enable : in  std_logic;
    
    preload : in  std_logic_vector(data_width - 1 downto 0);
    load    : in  std_logic;
    data    : out std_logic_vector(data_width - 1 downto 0);
    
    input  : in  std_logic;
    output : out std_logic);
end spi_shifter_e;

-----------------------------------------------------------------------

architecture rtl of spi_shifter_e is
  signal data_s : std_logic_vector(data_width - 1 downto 0);
begin
  data   <= data_s;
  output <= data_s(data_s'high);
  
  process(clock, enable)
  begin
    if rising_edge(clock) then
      if (enable or load) = '1' then
        if load = '1' then
          data_s <= preload;
        else
          data_s <= data_s(data_s'high - 1 downto data_s'low) & input;
        end if;
      end if;
    end if;
  end process;
end rtl;
