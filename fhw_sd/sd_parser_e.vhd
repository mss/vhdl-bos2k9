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
    shifting : out std_logic;
    error    : out std_logic;
    idled    : out std_logic;
    
    pipe     : out std_logic;
    
    spi_start : out std_logic;
    spi_busy  : in  std_logic;
    spi_txd   : out std_logic_byte_t;
    spi_rxd   : in  std_logic_byte_t);
end sd_parser_e;

-----------------------------------------------------------------------

architecture rtl of sd_parser_e is
  component sd_counter_e is
    generic(
      max : positive := counter_max_c);
    port(
      clock  : in  std_logic;
      enable : in  std_logic;
    
      rewind : in  std_logic;
    
      top  : in  counter_top_t;
      done : out std_logic);
  end component;
  signal cnt_top_s  : counter_top_t;
  signal cnt_rwnd_s : std_logic;
  signal cnt_tick_s : std_logic;
  signal cnt_done_s : std_logic;

  type state_t is(
    idle_state_c,
    load_state_c,
    send_state_c,
    shft_state_c,
    vrfy_state_c,
    loop_state_c);
  signal state_s : state_t;
  
  signal frame_s : std_logic_frame_t;
  
  signal done_s  : std_logic;
  signal break_s : std_logic;
  signal error_s : std_logic;
begin
  shifting <= '0' when state_s = idle_state_c
         else '1';
  error    <= error_s;
  idled    <= is_std_cmd(command)
          and spi_rxd(0);
  pipe     <= '1' when command = cmd_do_pipe_c
                   and state_s = loop_state_c
         else '0';
  
  cnt_top_s  <= create_counter_top(command, argument);
  cnt_rwnd_s <= '1' when state_s = idle_state_c
           else '0';
  cnt_tick_s <= '1' when state_s = load_state_c
           else '1' when state_s = send_state_c
           else '0';
  
  spi_txd   <= get_frame_head(frame_s);
  spi_start <= '1' when state_s = send_state_c
          else '0';
  
  break_s <= not spi_rxd(7) when get_cmd_type(command) = cmd_type_std_c
        else not spi_rxd(0) when command = cmd_do_seek_c
        else '0';
  
  status : process(clock, reset)
  begin
    if reset = '1' then
      done_s <= '0';
    elsif rising_edge(clock) then
      case state_s is
        when idle_state_c => done_s <= '0';
        when shft_state_c => done_s <= done_s or cnt_done_s;
        when vrfy_state_c => done_s <= done_s or break_s;
        when others       => null;
      end case;
    end if;
  end process;
  
  framer : process(clock, reset)
  begin
    if reset = '1' then
      frame_s <= (others => '0');
    elsif rising_edge(clock) then
      case state_s is
        when load_state_c => frame_s <= create_frame(command, argument);
        when loop_state_c => frame_s <= shift_frame(frame_s);
        when others => null;
      end case;
    end if;
  end process;
  
  parser : process(clock, reset)
  begin
    if reset = '1' then
      error_s <= '0';
    elsif rising_edge(clock) then
      if state_s = vrfy_state_c and (done_s or break_s) = '1' then
        if break_s = '1' then
          if get_cmd_type(command) = cmd_type_std_c then
            error_s <= spi_rxd(6)
                    or spi_rxd(5)
                    or spi_rxd(4)
                    or spi_rxd(3)
                    or spi_rxd(2)
                    or spi_rxd(1);
          elsif command = cmd_do_seek_c then
            error_s <= spi_rxd(7);
          else
            error_s <= '0';
          end if;
        else
          if get_cmd_type(command) = cmd_type_std_c then
            error_s <= '1';
          elsif command = cmd_do_seek_c then
            error_s <= '1';
          else
            error_s <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  sequence : process(clock, reset)
  begin
    if reset = '1' then
      state_s <= idle_state_c;
    elsif rising_edge(clock) then
      case state_s is
        when idle_state_c =>
          if trigger = '1' then
            state_s <= load_state_c;
          end if;
        when load_state_c =>
          state_s <= send_state_c;
        when send_state_c =>
          state_s <= shft_state_c;
        when shft_state_c =>
          if spi_busy = '0' then
            state_s <= vrfy_state_c;
          end if;
        when vrfy_state_c =>
          state_s <= loop_state_c;
        when loop_state_c =>
          if done_s = '1' then
            state_s <= idle_state_c;
          else
            state_s <= send_state_c;
          end if;
      end case;
    end if;
  end process;
  
  counter : sd_counter_e port map(
    clock  => clock,
    enable => cnt_tick_s,
    rewind => cnt_rwnd_s,
    top    => cnt_top_s,
    done   => cnt_done_s);
end rtl;
