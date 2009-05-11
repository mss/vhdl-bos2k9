library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_starter_e is
  port(
    clock   : in  std_logic;
    reset   : in  std_logic;
	
	start   : in  std_logic;
	stop    : in  std_logic;
    
    status  : out std_logic);
end spi_starter_e;

-----------------------------------------------------------------------

architecture rtl of spi_starter_e is
  signal running_s  : std_logic;
begin
  status <= running_s;
  
  runner : process(clock, reset, stop)
  begin
	if reset = '1' then
	  running_s <= '0';
	elsif rising_edge(clock) then
	  if (start or stop) = '1' then
	    running_s <= start and not stop;
	  end if;
	end if;
  end process;

end rtl;
