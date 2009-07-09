 -----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232
library fhw_rs232;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_host is
  generic(
    clock_interval : time;
    clock_divider  : positive; -- TODO: calculate this based on clock_interval
    data_width     : positive := 8;
    parity         : std_logic_vector(1 downto 0) := "00");
  port(
    clk : in  std_logic;
    rst : in  std_logic;
    
    tx  : out std_logic;
    txd : in  std_logic_vector(data_width - 1 downto 0);
    txn : in  std_logic;
    txb : out std_logic;
    
    rx  : in  std_logic;
    rxd : out std_logic_vector(data_width - 1 downto 0);
    rxn : out std_logic;
    rxb : out std_logic);
 end sd_host;
 
-----------------------------------------------------------------------

architecture rtl of sd_host is
  component rs232_send is
    generic(
      clock_interval : time := clock_interval;
      clock_divider  : positive := clock_divider;
      data_width     : positive := data_width;
      parity         : std_logic_vector(1 downto 0) := parity);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
      
      tx  : out std_logic;
      txd : in  std_logic_vector(data_width - 1 downto 0);
      txb : out std_logic);
   end component;
   component rs232_recv is
    generic(
      clock_interval : time := clock_interval;
      clock_divider  : positive := clock_divider;
      data_width     : positive := data_width;
      parity         : std_logic_vector(1 downto 0) := parity);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
      
      rx  : in  std_logic;
      rxd : out std_logic_vector(data_width - 1 downto 0);
      rxb : out std_logic);
   end component;
begin
  send : rs232_send port map(clk, rst, tx, txd, txb);
  recv : rs232_recv port map(clk, rst, rx, rxd, rxb);
end rtl;
