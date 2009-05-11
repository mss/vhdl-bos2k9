library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_shifter_e is
  generic(
    data_width : positive;
	spi_cpol : std_ulogic := '0';
	spi_cpha : std_ulogic := '0');
  port(
    clock : in  std_logic;
	
	trigger : in std_logic;
	
	data_in  : in  std_logic_vector(data_width - 1 downto 0);
	data_out : out std_logic_vector(data_width - 1 downto 0);
	load     : in  std_logic;	
	
	spi_in   : in  std_logic;
	spi_out  : out std_logic);
end spi_shifter_e;

-----------------------------------------------------------------------

architecture rtl of spi_shifter_e is
  signal data_s : std_logic_vector(data_width - 1 downto 0);
  
  signal buffer_s : std_logic;
  signal shift_s  : std_logic;
begin
  data_out <= data_s;
  
  shifter : process(clock, load)
  begin
    if rising_edge(clock) then
	  if (load or shift_s) = '1' then
	    if load = '1' then
	      data_s <= data_in;
		else
		  spi_out <= data_s(data_s'high);
		  data_s(data_s'high downto data_s'low + 1) <= data_s(data_s'high - 1 downto data_s'low);
		end if;
	  end if;
	end if;
  end process;

end rtl;
