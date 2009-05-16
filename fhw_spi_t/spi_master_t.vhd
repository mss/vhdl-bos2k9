library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library fhw_spi;
use fhw_spi.all;

-----------------------------------------------------------------------

entity spi_master_t is
  generic(
    clock_interval : time := 20 us;
    clock_divider  : positive := 6;
    data_width : positive := 8;
    spi_mode : natural := 0);
end spi_master_t;

-----------------------------------------------------------------------

architecture test of spi_master_t is
  constant spi_mode_c : unsigned(1 downto 0) := to_unsigned(spi_mode, 2);
  constant spi_cpol_c : std_logic := spi_mode_c(1);
  constant spi_cpha_c : std_logic := spi_mode_c(0);

  component spi_master is
    generic(
      clk_div    : positive;
      data_width : positive;
      spi_mode   : integer range 0 to 3);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
    
      start : in  std_logic;
      busy  : out std_logic;
    
      txd   : in  std_logic_vector(data_width - 1 downto 0);
      rxd   : out std_logic_vector(data_width - 1 downto 0);
    
      miso  : in  std_logic;
      mosi  : out std_logic;
      sck   : out std_logic);
  end component;
  
  constant pattern_c : std_logic_vector(data_width - 1 downto 0) := ('1', '0', '0', '1', '0', '1', '1', '0', others => '0');

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal start_s : std_logic;
  signal busy_s  : std_logic;
  signal txd_s   : std_logic_vector(data_width - 1 downto 0);
  signal rxd_s   : std_logic_vector(data_width - 1 downto 0);
  signal miso_s  : std_logic;
  signal mosi_s  : std_logic;
  signal sck_s   : std_logic;
  
  signal ss_n    : std_logic;
  signal data_s  : std_logic_vector(data_width - 1 downto 0);
begin
  dut : spi_master generic map(clock_divider, data_width, spi_mode) port map(clock_s, reset_s, start_s, busy_s, txd_s, rxd_s, miso_s, mosi_s, sck_s);
  
  stimulus : process
  begin
    test_s <= -3;
    start_s <= '0';
    txd_s   <= (others => 'U');
    miso_s  <= 'Z';
    wait until falling_edge(reset_s); test_s <= test_s + 1;
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    txd_s  <= pattern_c;
    miso_s <= '1';
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    start_s <= '1';
    
    wait until rising_edge(clock_s); test_s <= test_s + 1;
    start_s <= '0';
    
    wait until falling_edge(busy_s); test_s <= test_s + 1;
    txd_s  <= (others => 'U');
    miso_s <= 'Z';
    
    wait;
  end process;
  
  ss_n <= not (start_s or busy_s);
  sample : process
    variable count_v : integer;
  begin
    data_s <= (others => 'U');
    if spi_cpha_c = '0' then
      count_v := 0;
    else
      count_v := -1;
    end if;
    wait until falling_edge(ss_n);
    
    while ss_n = '0' loop
      wait until sck_s'event or ss_n'event;
      if ss_n = '0' then
        count_v := count_v + 1;
        if (count_v mod 2) = 1 then
          data_s(0) <= mosi_s;
        else
          data_s <= data_s(data_width - 2 downto 0) & data_s(data_width - 1);
        end if;
      end if;
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
