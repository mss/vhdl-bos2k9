library ieee;
use ieee.std_logic_1164.all;

library fhw_spi;
use fhw_spi.all;

-----------------------------------------------------------------------

entity bos2k9 is
  generic(
    clock_interval : time :=  20 ns;
    data_width : positive := 8);
  port(
    clk : in  std_logic; --pin:N2
    rst : in  std_logic; --pin:G25
    
    miso : in  std_logic;
    mosi : out std_logic;
    sck  : out std_logic);
end bos2k9;

-----------------------------------------------------------------------

architecture board of bos2k9 is

  component spi_master 
    generic(
      clk_div    : positive := 8;
      data_width : positive := data_width;
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
  end component;

  signal start_s : std_logic;
  signal busy_s  : std_logic;
  
  signal ibuf_s  : std_logic_vector(data_width - 1 downto 0);
  signal obuf_s  : std_logic_vector(data_width - 1 downto 0);
  
begin
  
  start_s <= '0';
  
  spi_io : spi_master port map(
    clk => clk,
    rst => rst,
    
    start => start_s,
    busy  => busy_s,
    
    txd   => obuf_s,
    rxd   => ibuf_s,
    
    miso  => miso,
    mosi  => mosi,
    sck   => sck);

  

end board;
