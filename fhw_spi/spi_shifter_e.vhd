library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

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
