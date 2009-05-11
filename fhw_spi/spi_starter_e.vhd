library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_starter_e is
  port(
    clock   : in  std_logic;
    reset   : in  std_logic;
	
	start   : in  std_logic;
	trigger : in  std_logic;
	stop    : in  std_logic;
    
    status  : out std_logic);
end spi_starter_e;

-----------------------------------------------------------------------

architecture rtl of spi_starter_e is
  signal starting_s : std_logic;
  signal running_s  : std_logic;
begin
  status <= running_s;
  
  starter : process(clock, reset, start, trigger)
  begin
    if reset = '1' then
	  starting_s <= '0';
	elsif rising_edge(clock) then
	  if (start or trigger) = '1' then
        starting_s <= start;
	  end if;
	end if;
  end process;
  
  runner : process(clock, reset, starting_s, trigger, stop)
  begin
	if reset = '1' then
	  running_s <= '0';
	elsif rising_edge(clock) then
	  if (starting_s or stop) = '1' then
	    if stop = '1' then -- stop over stray trigger
		  assert(starting_s = '0');
		  running_s <= '0';
		elsif trigger = '1' then -- must be the starter calling
		  running_s <= '1';
        end if;
	  end if;
	end if;
  end process;

end rtl;
