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
      
    cnt_top  : out counter_top_t);
end sd_parser_e;

-----------------------------------------------------------------------

architecture rtl of sd_parser_e is
  type state_t is(
    idle_state_c,
    send_state_c,
    loop_state_c,
    next_state_c);
  signal state_s : state_t;
  
  signal frame_s : std_logic_frame_t;
begin
  shifting <= '0' when state_s = idle_state_c else '1';
  
  io_start <= '1' when state_s = send_state_c else '0';
  io_frame <= create_frame(command, argument);
  cnt_top  <= create_counter_top(command, argument);
  
  sequence : process(clock, reset)
  begin
    if reset = '1' then
      state_s <= idle_state_c;
    elsif rising_edge(clock) then
      case state_s is
        when idle_state_c =>
          if trigger = '1' then
            state_s <= send_state_c;
          end if;
        when send_state_c =>
          state_s <= loop_state_c;
        when loop_state_c =>
          if io_shift = '1' then
            state_s <= next_state_c;
          end if;
        when next_state_c =>
          if io_busy = '1' then
            state_s <= loop_state_c;
          else
            state_s <= idle_state_c;
          end if;
      end case;
    end if;
  end process;
  
  pipe <= io_shift when command = cmd_do_pipe_c
     else '0';
  
  
  -- translate : process(clock, reset)
  -- begin
    -- if reset = '1' then
      -- spi_start_s <= '0';
      -- frame_s     <= (others => '0');
    -- elsif rising_edge(clock) then
    
      -- spi_start_s <= '0';
      
      -- 
    
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
        -- when shft_state_c => frame_s <= 
        -- when others => null;
      -- end case;
    -- end if;
  -- end process;
end rtl;
