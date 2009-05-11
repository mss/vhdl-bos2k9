library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_master is
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
end spi_master;

-----------------------------------------------------------------------

architecture rtl of spi_master is
  
begin
  
end rtl;
