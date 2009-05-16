library ieee;
use ieee.std_logic_1164.all;

library fhw_spi;
use fhw_spi.all;

-----------------------------------------------------------------------

entity spi_engine_t is
  generic(
    clock_interval : time := 20 us;
    clock_divider  : positive := 6;
    data_width : positive := 8;
    data_pattern : std_logic_vector(8 - 1 downto 0) := "10010110";
    spi_pattern : std_logic_vector(8 - 1 downto 0) := "LHLHLHLH");
end spi_engine_t;

-----------------------------------------------------------------------

architecture test of spi_engine_t is
  component spi_engine_e is
    generic(
      data_width : positive := data_width;
      spi_cpol   : std_logic;
      spi_cpha   : std_logic);
    port(
      clock : in  std_logic;
      reset : in  std_logic;
  
      trigger : in  std_logic;
      done    : out std_logic;
  
      data_in  : in  std_logic_vector(data_width - 1 downto 0);
      data_out : out std_logic_vector(data_width - 1 downto 0);
  
      spi_in    : in  std_logic;
      spi_out   : out std_logic;
      spi_clock : out std_logic);
  end component;
  
  component spi_counter_e is
    generic(
      count : positive := clock_divider;
      edge  : std_logic := '0');
    port(
      clock  : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;
      
      override : in std_logic;

      done : out std_logic);
  end component;

  signal test_s : natural;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  signal enable_s : std_logic;
  signal trigger_s : std_logic;
  signal done_a_s  : std_logic;
  signal done_0_s  : std_logic;
  signal done_1_s  : std_logic;
  signal done_2_s  : std_logic;
  signal done_3_s  : std_logic;
  signal data_in_a_s   : std_logic_vector(data_width - 1 downto 0);
  signal data_in_0_s   : std_logic_vector(data_width - 1 downto 0);
  signal data_in_1_s   : std_logic_vector(data_width - 1 downto 0);
  signal data_in_2_s   : std_logic_vector(data_width - 1 downto 0);
  signal data_in_3_s   : std_logic_vector(data_width - 1 downto 0);
  signal data_out_0_s  : std_logic_vector(data_width - 1 downto 0);
  signal data_out_1_s  : std_logic_vector(data_width - 1 downto 0);
  signal data_out_2_s  : std_logic_vector(data_width - 1 downto 0);
  signal data_out_3_s  : std_logic_vector(data_width - 1 downto 0);
  signal spi_in_0_s    : std_logic;
  signal spi_in_1_s    : std_logic;
  signal spi_in_2_s    : std_logic;
  signal spi_in_3_s    : std_logic;
  signal spi_out_0_s   : std_logic;
  signal spi_out_1_s   : std_logic;
  signal spi_out_2_s   : std_logic;
  signal spi_out_3_s   : std_logic;
  signal spi_clock_0_s : std_logic;
  signal spi_clock_1_s : std_logic;
  signal spi_clock_2_s : std_logic;
  signal spi_clock_3_s : std_logic;
begin
  dut0 : spi_engine_e  generic map(spi_cpol => '0', spi_cpha => '0') port map(clock_s, reset_s, trigger_s, done_0_s, data_in_0_s, data_out_0_s, spi_in_0_s, spi_out_0_s, spi_clock_0_s);
  dut1 : spi_engine_e  generic map(spi_cpol => '0', spi_cpha => '1') port map(clock_s, reset_s, trigger_s, done_1_s, data_in_1_s, data_out_1_s, spi_in_1_s, spi_out_1_s, spi_clock_1_s);
  dut2 : spi_engine_e  generic map(spi_cpol => '1', spi_cpha => '0') port map(clock_s, reset_s, trigger_s, done_2_s, data_in_2_s, data_out_2_s, spi_in_2_s, spi_out_2_s, spi_clock_2_s);
  dut3 : spi_engine_e  generic map(spi_cpol => '1', spi_cpha => '1') port map(clock_s, reset_s, trigger_s, done_3_s, data_in_3_s, data_out_3_s, spi_in_3_s, spi_out_3_s, spi_clock_3_s);
  trig : spi_counter_e port map(clock_s, reset_s, enable_s, '0', trigger_s);
  
  done_a_s <= done_0_s or done_1_s or done_2_s or done_3_s;
  
  data_in_0_s <= data_in_a_s;
  data_in_1_s <= data_in_a_s;
  data_in_2_s <= data_in_a_s;
  data_in_3_s <= data_in_a_s;
  
  stimulus : process
  begin
    test_s <= 0;
    enable_s <= '0';
    data_in_a_s <= (others => 'U');
    wait until falling_edge(reset_s); test_s <= test_s + 1;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    enable_s <= '1';
    
    wait until rising_edge(trigger_s); test_s <= test_s + 1;
    data_in_a_s <= data_pattern;
    
    wait until rising_edge(trigger_s); test_s <= test_s + 1;
    data_in_a_s <= (others => 'U');
    
    wait until rising_edge(done_0_s); test_s <= test_s + 1;
    enable_s <= '0';
    
    wait;
  end process;
  
  input_0 : process
    variable index_v : integer;
  begin
    index_v := data_width - 1;
    while not (index_v = -1) loop
      spi_in_0_s <= spi_pattern(index_v);
      wait until falling_edge(spi_clock_0_s);
      index_v := index_v - 1;
    end loop;
  end process;
  
  input_1 : process
    variable index_v : integer;
  begin
    index_v := data_width - 1;
    wait until rising_edge(spi_clock_1_s);
    while not (index_v = -1) loop
      spi_in_1_s <= spi_pattern(index_v);
      wait until rising_edge(spi_clock_1_s);
      index_v := index_v - 1;
    end loop;
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
