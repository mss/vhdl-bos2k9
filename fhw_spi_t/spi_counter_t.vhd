library ieee;
use ieee.std_logic_1164.all;

library fhw_spi;
use fhw_spi.all;

-----------------------------------------------------------------------

entity spi_counter_t is
  generic(
    clock_interval : time := 20 us;
    count : positive := 4);
end spi_counter_t;

-----------------------------------------------------------------------

architecture test of spi_counter_t is
  component spi_counter_e is
    generic(
      count : positive := count);
    port(
      clock  : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;

      done : out std_logic);
  end component;

  signal clock_s : std_logic;
  signal reset_s : std_logic;
  signal enable_s : std_logic;
  signal done_s : std_logic;
begin
  dut : spi_counter_e port map(clock_s, reset_s, enable_s, done_s);

  stimulus : process
  begin
    enable_s <= '1';
    wait until rising_edge(done_s);
    
    enable_s <= '0';
    wait until rising_edge(clock_s);
    enable_s <= '1';
    wait until rising_edge(done_s);
    
    wait;
  end process;
  
  reset : process
  begin
    reset_s <= '1';
    wait until rising_edge(clock_s);
    reset_s <= '0';
    wait;
  end process;
  
  clock : process
  begin
    clock_s <= '0';
    wait for clock_interval;
    clock_s <= '1';
    wait for clock_interval;
  end process;
  
end test;
