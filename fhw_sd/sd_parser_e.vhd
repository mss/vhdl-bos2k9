-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals_p.all;
use fhw_sd.sd_commands_p.all;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_parser_e is
  generic(
    counter_max : positive);
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    command  : in  std_logic_cmd_t;
    argument : in  std_logic_arg_t;
    trigger  : in  std_logic;
    response : out std_logic_rsp_t;
    shifting : out std_logic;
    
    pipe     : out std_logic;
      
    io_frame : out std_logic_frame_t;
    io_start : out std_logic;
    io_busy  : in  std_logic;
    io_data  : in  std_logic_byte_t;
    io_shift : in  std_logic;
      
    cnt_top  : out natural range 1 to counter_max);
end sd_parser_e;

-----------------------------------------------------------------------

architecture rtl of sd_parser_e is

begin
  
  
  -- translate : process(clock, reset)
  -- begin
    -- if reset = '1' then
      -- spi_start_s <= '0';
      -- frame_s     <= (others => '0');
    -- elsif rising_edge(clock) then
    
      -- spi_start_s <= '0';
      
      -- frame_s <= create_frame(command, argument);
    
      -- case command is
        -- when cmd_do_reset_c =>
          -- spi_txd <= (others => '1');
          
        -- when cmd_do_start_c =>
          -- null;
        -- when cmd_set_blocklen_c =>
          -- null;
        -- when cmd_read_single_block_c =>
          
        -- when others =>
          -- null;
      -- end case;
    -- end if;
  -- end process;
  
  -- framer : process(clock)
  -- begin
    -- if rising_edge(clock) then
      -- case state_s is
        -- when load_state_c => frame_s <= create_frame(command, argument);
        -- when shft_state_c => frame_s <= frame_s(std_logic_frame_t'high - 8 downto 0) & pad_c;
        -- when others => null;
      -- end case;
    -- end if;
  -- end process;
end rtl;
