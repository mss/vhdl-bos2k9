library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_counter_e is
  generic(
    count : positive);
  port(
    clock  : in  std_logic;
	reset  : in  std_logic;
	enable : in  std_logic;
	
	done : out std_logic);
end spi_counter_e;

-----------------------------------------------------------------------

architecture rtl of spi_counter_e is
  signal count_s : natural range 0 to count;
begin
  process(clock, reset, enable)
  begin
    if reset = '1' then
	  done <= '0';
	  count_s <= 0;
    elsif rising_edge(clock) then
	  done  <= '0';
	  count_s <= count_s'low;
	  if enable = '1' then
	    if count_s = count_s'high then
		  done <= '1';
	    else
	      count_s <= count_s + 1;
		end if;
	  end if;
	end if;
  end process;
end rtl;