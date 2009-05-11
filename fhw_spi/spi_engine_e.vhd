library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_engine_e is
  generic(
    spi_cpol : std_logic := 0;
	spi_cpha : std_logic := 0;
  );
  port(
    clock : in  std_logic;
	reset : in  std_logic;
	
	running : in std_logic;
	trigger : in std_logic;
	
	data : in  std_logic_vector(data_width - 1 downto 0);
	done : out std_logic;
	
	spi_in    : in  std_logic;
	spi_out   : out std_logic;
	spi_clock : out std_logic);
end spi_engine_e;

-----------------------------------------------------------------------

architecture rtl of spi_engine_e is
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
