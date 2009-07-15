-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232
library fhw_rs232;
use fhw_rs232.rs232_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rs232_recv is
  generic(
    clock_interval : time;
    clock_divider  : positive; -- TODO: calculate this based on clock_interval
    data_width     : positive := 8;
    parity_enabled : std_logic := '0';
    parity_type    : std_logic := '1');
  port(
    clk : in  std_logic;
    rst : in  std_logic;
    
    rx  : in  std_logic;
    rxd : out std_logic_vector(data_width - 1 downto 0);
    rxn : out std_logic;
    rxb : out std_logic);
 end rs232_recv;
 
-----------------------------------------------------------------------

architecture rtl of rs232_recv is
begin
  
end rtl;
