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

entity rs232_send is
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
    txb : out std_logic);
 end rs232_send;
 
-----------------------------------------------------------------------

architecture rtl of rs232_send is
  constant parity_enabled_c : std_logic := parity(1);
  constant parity_c         : std_logic := parity(0);
begin
  
end rtl;