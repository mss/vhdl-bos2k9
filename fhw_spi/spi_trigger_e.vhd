library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_trigger_e is
  generic(
    clk_div : positive);
  port(
    clock  : in  std_logic;
	reset  : in  std_logic;
	
	output : out std_logic);
end spi_trigger_e;

-----------------------------------------------------------------------

architecture rtl of spi_trigger_e is
  signal ticks_s : natural range 0 to clk_div - 1;
begin
  process(clock, reset)
  begin
    if reset = '1' then
	  output <= '0';
	  ticks_s <= ticks_s'low;
	elsif rising_edge(clock) then
	  output <= '0';
	  if ticks_s = ticks_s'high then
	    output <= '1';
		ticks_s <= ticks_s'low;
	  else
	    ticks_s <= ticks_s + 1;
	  end if;
	  
	end if;
  end process;

end rtl;
