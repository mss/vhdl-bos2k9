library ieee;
use ieee.std_logic_1164.all;

library fhw_spi;
use fhw_spi.all;

-----------------------------------------------------------------------

entity spi_starter_t is
  generic(
    clock_interval : time := 20 us);
end spi_starter_t;

-----------------------------------------------------------------------

architecture test of spi_starter_t is
  component spi_starter_e is
    port(
      clock   : in  std_logic;
      reset   : in  std_logic;
	
	  start   : in  std_logic;
	  stop    : in  std_logic;
    
      status  : out std_logic);
  end component;

  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  signal start_s  : std_logic;
  signal stop_s   : std_logic;
  signal status_s : std_logic;
begin
  dut : spi_starter_e port map(clock_s, reset_s, start_s, stop_s, status_s);

  stimulus : process
  begin
    start_s <= '0';
    stop_s  <= '0';
    wait until falling_edge(reset_s);
    
    wait until rising_edge(clock_s);
    start_s <= '1';
    wait until rising_edge(clock_s);
    start_s <= '0';
    
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    stop_s <= '1';
    wait until rising_edge(clock_s);
    stop_s <= '0';
    
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
