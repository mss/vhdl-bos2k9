-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi
library fhw_spi;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_host is
  generic(
    clk_div    : positive := 6);
  port(
    clk : in  std_logic;
    rst : in  std_logic;
      
    spi_txd : out   std_logic_vector(7 downto 0);
    spi_rxd : in    std_logic_vector(7 downto 0);
    spi_sts : inout std_logic);
 end sd_host;
 
-----------------------------------------------------------------------

architecture rtl of sd_host is
  component spi_master
    generic(
      clk_div    : positive := clk_div;
      data_width : positive := 8);
  end component;
  port(
    clk : in  std_logic;
    rst : in  std_logic;
  );
begin
end rtl;
