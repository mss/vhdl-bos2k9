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
    trigger  : in  std_logic;
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
  signal spi_start_s : std_logic;
  signal spi_busy_s  : std_logic;
  signal sd_busy_s   : std_logic;

  signal frame_s : std_logic_frame_t;

  --signal counter_s : 
begin
  shifting <= sd_busy_s;
  
  spi_start <= spi_start_s;
  spi_busy_s <= spi_busy;

  translate : process(clock, reset)
  begin
    if reset = '1' then
      spi_start_s <= '0';
      frame_s     <= (others => '0');
    elsif rising_edge(clock) then
    
      spi_start_s <= '0';
      
      frame_s <= create_frame(command, argument);
    
      case command is
        when cmd_do_reset_c =>
          spi_txd <= (others => '1');
          
        when cmd_do_start_c =>
          null;
        when cmd_set_blocklen_c =>
          null;
        when cmd_read_single_block_c =>
          
        when others =>
          null;
      end case;
    end if;
  end process;
  
  shifting_ff : process(clock, reset)
  begin
    if reset = '1' then
      sd_busy_s <= spi_busy_s;
    elsif rising_edge(clock) then
      if trigger = '1' then
        sd_busy_s <= '1';
      elsif spi_start_s = '1' then
        sd_busy_s <= spi_busy_s;
      end if;
    end if;
  end process;
end rtl;
