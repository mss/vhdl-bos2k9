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

entity sd_flow_e is
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    address : in std_logic_block_address_t;
    start   : in std_logic;
    
    ready : out std_logic;
    busy  : out std_logic;
    
    command  : out std_logic_cmd_t;
    argument : out std_logic_arg_t;
    trigger  : out std_logic;
    shifting : in  std_logic;
    error    : in  std_logic;
    idled    : in  std_logic);
end sd_flow_e;

-----------------------------------------------------------------------

architecture rtl of sd_flow_e is
  type state_t is (
    rset_state_c,
    strt_state_c,
    idle_state_c,
    init_state_c,
    loop_state_c,
    bsiz_state_c,
    read_state_c,
    seek_state_c,
    pipe_state_c,
    skip_state_c,
    send_state_c,
    shft_state_c,
    vrfy_state_c,
    jump_state_c,
    wait_state_c);
  signal curr_state_s : state_t;
  signal prev_state_s : state_t;
  signal next_state_s : state_t;
begin
  
  sequence : process(clock, reset)
  begin
    if reset = '1' then
      curr_state_s <= rset_state_c;
    elsif rising_edge(clock) then
      case curr_state_s is
        when rset_state_c => curr_state_s <= send_state_c;
        when strt_state_c => curr_state_s <= send_state_c;
        when idle_state_c => curr_state_s <= send_state_c;
        when init_state_c => curr_state_s <= loop_state_c;
        when loop_state_c => curr_state_s <= next_state_s;
        when bsiz_state_c => curr_state_s <= send_state_c;
        when read_state_c => curr_state_s <= send_state_c;
        when seek_state_c => curr_state_s <= send_state_c;
        when pipe_state_c => curr_state_s <= send_state_c;
        when skip_state_c => curr_state_s <= send_state_c;
        when send_state_c => curr_state_s <= shft_state_c;
        when shft_state_c => curr_state_s <= next_state_s;
        when vrfy_state_c => curr_state_s <= jump_state_c;
        when jump_state_c => curr_state_s <= next_state_s;
        when wait_state_c => curr_state_s <= next_state_s;
      end case;
    end if;
  end process;
  
  output : process(clock, reset)
  begin
    if reset = '1' then
      command  <= (others => '0');
      argument <= (others => '0');
    elsif rising_edge(clock) then
      prev_state_s <= curr_state_s;
      case curr_state_s is
        when rset_state_c =>
          command  <= cmd_do_reset_c;
          argument <= arg_do_reset_c;
        when strt_state_c =>
          command  <= cmd_do_start_c;
          argument <= arg_do_start_c;
        when idle_state_c =>
          command  <= cmd_go_idle_state_c;
          argument <= arg_go_idle_state_c;
        when init_state_c =>
          command  <= cmd_send_op_cond_c;
          argument <= arg_send_op_cond_c;
        when bsiz_state_c =>
          command  <= cmd_set_blocklen_c;
          argument <= arg_set_blocklen_c;
        when read_state_c =>
          command  <= cmd_read_single_block_c;
          argument <= address & pad_read_single_block_c;
        when seek_state_c =>
          command  <= cmd_do_seek_c;
          argument <= arg_do_seek_c;
        when pipe_state_c =>
          command  <= cmd_do_pipe_c;
          argument <= arg_do_pipe_c;
        when skip_state_c =>
          command  <= cmd_do_skip_c;
          argument <= arg_do_skip_c;
        when others =>
          prev_state_s <= prev_state_s;
      end case;
    end if;
  end process;
  
  ready   <= '1' when curr_state_s = wait_state_c else '0';
  busy    <= '0' when curr_state_s = wait_state_c else '1'; -- TODO?
  trigger <= '1' when curr_state_s = send_state_c else '0';
  
  branch : process(clock)
  begin
    if rising_edge(clock) then
      case curr_state_s is
        when send_state_c =>
          next_state_s <= shft_state_c;
        when shft_state_c =>
          if shifting = '0' then
            next_state_s <= vrfy_state_c;
          end if;
        when vrfy_state_c =>
          if error = '0' then
            case prev_state_s is
              when rset_state_c => next_state_s <= strt_state_c;
              when strt_state_c => next_state_s <= idle_state_c;
              when idle_state_c => next_state_s <= init_state_c;
              when init_state_c => next_state_s <= init_state_c;
              when bsiz_state_c => next_state_s <= wait_state_c;
              when read_state_c => next_state_s <= seek_state_c;
              when seek_state_c => next_state_s <= pipe_state_c;
              when pipe_state_c => next_state_s <= skip_state_c;
              when skip_state_c => next_state_s <= wait_state_c;
              when others => null;
            end case;
          else
            next_state_s <= rset_state_c;
          end if;
        when init_state_c =>
          if idled = '1' then
            next_state_s <= send_state_c;
          else
            next_state_s <= bsiz_state_c;
          end if;
        when wait_state_c =>
          if start = '1' then
            next_state_s <= read_state_c;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process;
 
end rtl;