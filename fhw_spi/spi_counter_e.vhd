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
    
    override : in std_logic;
    
    done : out std_logic);
end spi_counter_e;

-----------------------------------------------------------------------

architecture rtl of spi_counter_e is
  subtype count_t is natural range 0 to count - 1;
  signal count_s : count_t;
begin
  counter : process(clock, reset, enable, override)
  begin
    if reset = '1' then
      count_s <= 0;
      done    <= '0';
    elsif rising_edge(clock) then
      done <= '0';
      if (enable or override) = '1' then
        if (count_s = count_t'high) or (override = '1') then
          count_s <= count_t'low;
          done <= '1';
        else
          count_s <= count_s + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
