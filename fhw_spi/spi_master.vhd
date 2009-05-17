-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This SPI master processes the serial 4-wire full duplex bus-protocol
-- called SPI (Serial Peripheral Interface), also known as Microwire.
-- The four lines used by SPI are called MISO (Master In Slave Out,
-- input `miso`), MOSI (Master Out Slave In, output `mosi`), SCK
-- (Serial ClocK, output `sck`) and SS (Slave Select, low active, can
-- be derived from the `busy` line).
--
-- SPI can operate with varying frame sizes which can be specified
-- via the generic `data_width`, defaulting to eigth bit. The two
-- bit wide generic `spi_mode` is for compatibility to devices which 
-- do not use the default mode 0; the low bit is also known as CPHA
-- (Clock PHAse), the high bit as CPOL (Clock POLarity). When CPHA is
-- set, the first SCK edge is ignored; when CPOL is set, the polarity
-- of the SCK is inverted (ie. SCK is low active).
-- 
-- The maximum speed of the SPI bus depends on the maximum speed of 
-- both master and slave and can be changed via the generic `clk_div`
-- which must be even and greater or equal than six.
--
-- For more information and details on SPI see
--   http://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus
--
-- This entity is synchronized on the rising edge of the clock `clk`
-- and the reset line `rst` is high active.
-- 
-- It is idle until `start` goes high. Data to be transmitted over SPI
-- must be stable on `txd` at that point and be held stable for one
-- `clk` cycle afterwards. Then, next data can be prepared.

-- While data is shifted, the `busy` line is high and `start` is
-- ignored. Even if `start` stays high all the time, `busy` will go
-- low for one `clk` cycle when all data is shifted out to signal a
-- stable output on `rxd`. The state of the latter is undefined (ie.
-- not stable) while `busy` is high.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi
library fhw_spi;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
  generic(
    clk_div    : positive := 6;
    data_width : positive := 8;
    spi_mode   : integer range 0 to 3 := 0);
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
end spi_master;

-----------------------------------------------------------------------

architecture rtl of spi_master is
  constant spi_mode_c : unsigned(1 downto 0) := to_unsigned(spi_mode, 2);
  constant spi_cpol_c : std_logic := spi_mode_c(1);
  constant spi_cpha_c : std_logic := spi_mode_c(0);
  
  component spi_counter_e
    generic(
      count : positive := clk_div / 2;
      edge  : std_logic := '0');
    port(
      clock  : in  std_logic;
      reset  : in  std_ulogic;
      enable : in  std_logic;
      
      override : in std_logic;
    
      done : out std_logic);
  end component;
  
  component spi_starter_e
    port(
      clock   : in  std_logic;
      reset   : in  std_logic;
    
      start   : in  std_logic;
      stop    : in  std_logic;
    
      status  : out std_logic);
  end component;
  
  component spi_engine_e
    generic(
      data_width : positive := data_width;
      spi_cpol   : std_logic := spi_cpol_c;
      spi_cpha   : std_logic := spi_cpha_c);
    port(
      clock : in  std_logic;
      reset : in  std_ulogic;
    
      trigger : in  std_logic;
      done    : out std_logic;
    
      data_in  : in  std_logic_vector(data_width - 1 downto 0);
      data_out : out std_logic_vector(data_width - 1 downto 0);
    
      spi_in    : in  std_logic;
      spi_out   : out std_logic;
      spi_clock : out std_logic);
  end component;

  signal clock_s : std_logic;
  signal reset_s : std_logic;
  
  signal start_s   : std_logic;
  signal stop_s    : std_logic;
  signal running_s : std_logic;
  
  signal trigger_s : std_logic;
  
  signal data_in_s  : std_logic_vector(data_width - 1 downto 0);
  signal data_out_s : std_logic_vector(data_width - 1 downto 0);
  
  signal spi_in_s    : std_logic;
  signal spi_out_s   : std_logic;
  signal spi_clock_s : std_logic;
begin
  assert clk_div >= 6      report "clk_div can not be lower than 6" severity error;
  assert clk_div mod 2 = 0 report "clk_div will be rounded down to the next even value" severity warning;

  clock_s <= clk;
  reset_s <= rst;
  
  start_s <= start and not running_s; -- make sure we don't trigger a start while running
  busy    <= running_s;
  
  -- Direct output; beware of hazards!
  data_in_s <= txd;
  rxd <= data_out_s;
  
  spi_in_s <= miso;
  mosi <= spi_out_s;
  sck <= spi_clock_s;
  
  starter : spi_starter_e port map(
    clock  => clock_s,
    reset  => reset_s,
    
    start   => start_s,
    stop    => stop_s,
    
    status  => running_s);
    
  trigger : spi_counter_e port map(
    clock  => clock_s,
    reset  => reset_s,
    enable => running_s,
    
    override => start_s,
    
    done   => trigger_s);
    
  engine : spi_engine_e port map(
    clock => clock_s,
    reset => reset_s,
    
    trigger => trigger_s,
    done    => stop_s,
    
    data_in  => data_in_s,
    data_out => data_out_s,
    
    spi_in    => spi_in_s,
    spi_out   => spi_out_s,
    spi_clock => spi_clock_s);
  
end rtl;
