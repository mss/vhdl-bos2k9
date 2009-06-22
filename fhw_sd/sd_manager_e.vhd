-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_types.all;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_manager_e is
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    start : in  std_logic;
    ready : out std_logic;
    busy  : out std_logic;
    
    command  : out std_logic_cmd_t;
    argument : out std_logic_arg_t;
    response : in  std_logic_rsp_t;
    shifting : in  std_logic);
end sd_manager_e;

-----------------------------------------------------------------------

architecture rtl of sd_manager_e is
begin
end rtl;
