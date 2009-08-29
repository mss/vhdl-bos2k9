 -----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: This is an incomplete UART implementation, only including a 
-- sender.  See `rs232_send` for details.
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
    clock_divider  : positive;
    data_width     : positive := 8;
    parity_enabled : std_logic := '0';
    parity_type    : std_logic := '0');
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
      clock_divider  : positive := clock_divider;
      data_width     : positive := data_width;
      parity_enabled : std_logic := parity_enabled;
      parity_type    : std_logic := parity_type);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
      
      tx  : out std_logic;
      txd : in  std_logic_vector(data_width - 1 downto 0);
      txn : in  std_logic;
      txb : out std_logic);
   end component;
   component rs232_recv is
    generic(
      clock_divider  : positive := clock_divider;
      data_width     : positive := data_width;
      parity_enabled : std_logic := parity_enabled;
      parity_type    : std_logic := parity_type);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
      
      rx  : in  std_logic;
      rxd : out std_logic_vector(data_width - 1 downto 0);
      rxn : out std_logic;
      rxb : out std_logic);
   end component;
begin
  send : rs232_send port map(clk, rst, tx, txd, txn, txb);
  recv : rs232_recv port map(clk, rst, rx, rxd, rxn, rxb);
end rtl;
