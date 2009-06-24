-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals.all;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_io_e is
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    command  : in  std_logic_cmd_t;
    argument : in  std_logic_arg_t;
    response : out std_logic_rsp_t;
    shifting : out std_logic;
    
    data  : out std_logic_byte_t;
    shift : out std_logic;
    
    spi_start : out std_logic;
    spi_busy  : in  std_logic;
    spi_txd   : out std_logic_byte_t;
    spi_rxd   : in  std_logic_byte_t);
end sd_io_e;

-----------------------------------------------------------------------

architecture rtl of sd_io_e is
begin
  process(clock, reset)
  begin
    spi_start <= '0';
    if reset = '1' then
    elsif rising_edge(clock) then
      case command is
        when cmd_do_reset_c =>
          spi_txd <= (others => '1');
        when cmd_do_idle_c =>
          null;
        when cmd_set_blocklen_c =>
          null;
        when cmd_read_single_block_c =>
          null;
        when others =>
          null;
      end case;
    end if;
  end process;
end rtl;
