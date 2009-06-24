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
  generic(
    block_address_width : block_address_width_t);
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    address : in std_logic_vector(block_address_width - 1 downto 0);
    start   : in std_logic;
    
    ready : out std_logic;
    busy  : out std_logic;
    
    command  : out std_logic_cmd_t;
    argument : out std_logic_arg_t;
    response : in  std_logic_rsp_t;
    shifting : in  std_logic);
end sd_manager_e;

-----------------------------------------------------------------------

architecture rtl of sd_manager_e is
  
  type states_t is (
    rset_state_c,
    init_state_c,
    idle_state_c,
    read_state_c);
  signal curr_s : state_t;
  signal next_s : state_t;
  
  signal error_s : std_logic;

begin
  
  sequence : process(clock, reset, curr_s, next_s)
  begin
    if error = '1' then
      next_s <= rset_state_c;
    else
      if curr_s = 
    end if;
    
    case curr_s is
      when rset_state_c =>
        next_s <= 
    end case;
  end;
  
  output : process(clock, reset, curr_s, next_s)
  begin
    
  end;
  
  transition : process(clock, reset, curr_s, next_s)
  begin
    if reset = '1' then
      curr_s <= reset_state_c;
    elsif rising_edge(clock) then
      curr_s <= next_s;
    end if;
  end;
  
end rtl;
