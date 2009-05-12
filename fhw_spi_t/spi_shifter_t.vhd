library ieee;
use ieee.std_logic_1164.all;

library fhw_spi;
use fhw_spi.all;

-----------------------------------------------------------------------

entity spi_shifter_t is
  generic(
    clock_interval : time := 20 us;
    data_width : positive := 4);
end spi_shifter_t;

-----------------------------------------------------------------------

architecture test of spi_shifter_t is
  component spi_shifter_e is
    generic(
      data_width : positive := data_width);
    port(
      clock  : in  std_logic;
      enable : in  std_logic;

      preload : in  std_logic_vector(data_width - 1 downto 0);
      load    : in  std_logic;
      data    : out std_logic_vector(data_width - 1 downto 0);
	
      input  : in  std_logic;
      output : out std_logic);
  end component;

  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  signal enable_s : std_logic;
  signal preload_s : std_logic_vector(data_width - 1 downto 0);
  signal load_s    : std_logic;
  signal data_s    : std_logic_vector(data_width - 1 downto 0);
  signal input_s  : std_logic;
  signal output_s : std_logic;
begin
  dut : spi_shifter_e port map(clock_s, enable_s, preload_s, load_s, data_s, input_s, output_s);

  stimulus : process
  begin
    enable_s <= '0';
    load_s   <= '0';
    input_s  <= '0';
    wait until falling_edge(reset_s);
    
    preload_s <= "1100";
    load_s    <= '1';
    wait until rising_edge(clock_s);
    preload_s <= "UUUU";
    load_s    <= '0';
    
    wait until rising_edge(clock_s);
    input_s <= '1';
    
    wait until rising_edge(clock_s);
    enable_s <= '1';
    
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
