-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Command and SPI parser state machine.
-- 
-- This helper entity parsers the SD/SPI protocol in combination
-- with the `sd_flow_e`.
--
-- The following ports are connected directly to the `sd_host` ports:
--  * `clock`: input, from `clk`
--  * `reset`: input, from `rst`
--  * `error`: output
--  * `pipe`: output, to `shd`
--  * `spi_rxd`: input, also `rxd`
--
-- The following ports are connected to the `sd_flow_e` ports:
--  * `command`: input, SD command
--  * `argument`: input, SD command argument
--  * `trigger`: input, start `sd_parser_e`
--  * `shifting`: output, `sd_parser_e` busy
--  * `error`: output, SD error occurred
--  * `idled`: output, SD idle mode
--
-- The following port are connected to the `spi_master` ports without
-- the `spi_` prefix:
--  * `spi_start`
--  * `spi_busy`
--  * `spi_txd`
--  * `spi_rxd`
-- 
-- A relatively simple state machine with a variable `sd_counter_e`
-- is `trigger`ed by the `sd_flow_e` protocol state machine to send
-- a SD frame built from `command` and `argument`.
-- 
-- There are two kinds of commands:  Real SD commands and internal
-- ones.  They are listed in `sd_commands_p` and their details are 
-- described in `sd_globals_p`.  Real commands are shifted out as-is
-- while internal commands carry the (maximum) number of bytes to
-- receive in their argument and shift out a steady flow of high bits.
-- 
-- The `sd_counter_e` `top` value is used to count the bytes while 
-- `shifting`.
--
-- An initial 6 Byte frame is built when the state machine pulled 
-- from looping in `idle_state_c` to `load_state_c` by the `trigger`.
-- Implementing the variable part of the SD protocol is easy by 
-- padding the frame with all-ones for each shifted byte and waiting
-- on the right end token based on the current `command`.
-- 
-- In `load_state_c` the 'shifting' is started and as `spi_txd` always 
-- points to the head byte of the frame, the SPI master can be started#
-- via `spi_start` in `send_state_c`. While the SPI master is busy 
-- (`spi_busy`), the state machine loops in `shft_state_c`.
--
-- After each Byte, `vrfy_state_c` checks if a stop token was seen or
-- an error or a timeout occurred, shifts, and branches either to the 
-- next `send_state_c` or back to `idle_state_c`.
--
-- `command` and `argument` have to be stable while `shifting`.
-- 
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
  -- The entity is busy when it isn't idle (duh).
  shifting <= '0' when state_s = idle_state_c
         else '1';
  -- Hand out the error.
  error    <= error_s;
  -- The idle flag is the lowest bit of the R1 answer of standard commands.
  idled    <= is_std_cmd(command)
          and spi_rxd(0);
  -- Shifting is done with the internal command `cmd_do_pipe_c` (the 
  -- `sd_host`'s `rxd` is directly wired to `spi_rxd`).
  pipe     <= '1' when command = cmd_do_pipe_c
                   and state_s = loop_state_c
         else '0';
  
  -- Because `command` and `argument` are required to be stable, we can
  -- feed the `top` of the counter directly.
  cnt_top_s  <= create_counter_top(command, argument);
  -- But we have to reset the counter when done because some commands 
  -- have a variable response time.
  cnt_rwnd_s <= '1' when state_s = idle_state_c
           else '0';
  -- The counter is increased not only on `send_state_c` but also in 
  -- the first `load_state_c` so we don't have to count to N-1.
  cnt_tick_s <= '1' when state_s = load_state_c
           else '1' when state_s = send_state_c
           else '0';
  
  -- Directly wired to the first byte of the frame.
  spi_txd   <= get_frame_head(frame_s);
  -- The SPI master is triggered in `send_state_c`.
  spi_start <= '1' when state_s = send_state_c
          else '0';
  
  -- Detects a response token.  `spi_rxd` is high while the SD card is
  -- working and R1s are announced with a low high bit.  The Data Token
  -- on the other hand is announced by a low low bit.  All other 
  -- internal commands have a fixed size.
  break_s <= not spi_rxd(7) when get_cmd_type(command) = cmd_type_std_c
        else not spi_rxd(0) when command = cmd_do_seek_c
        else '0';
  
  -- There are several ways the `done_s` flag can be set.
  status : process(clock, reset)
  begin
    if reset = '1' then
      done_s <= '0';
    elsif rising_edge(clock) then
      case state_s is
        -- The flag is reset in `idle_state_c`.
        when idle_state_c => done_s <= '0';
        -- The counter is increased in `send_state_c`, so the 
        -- `cnt_done_s` (aka timeout) can appear on the first `clock`
        -- of the `shft_state_c`.
        when shft_state_c => done_s <= done_s or cnt_done_s;
        -- Else we might have detected a response token.
        when vrfy_state_c => done_s <= done_s or break_s;
        -- All other states must not set this flag.
        when others       => null;
      end case;
    end if;
  end process;
  
  -- The SD frame has to be set and shifted.
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
  
  -- In `vrfy_state_c` we have to determine if an `error` occurred.
  parser : process(clock, reset)
  begin
    if reset = '1' then
      error_s <= '0';
    elsif rising_edge(clock) then
      -- We've got to test both signals because `break_s` will be 
      -- joined with `done_s` just after this state.
      if state_s = vrfy_state_c and (done_s or break_s) = '1' then
        -- Did we see a response token?
        if break_s = '1' then
          -- Any bit except the highest and the lowest (idle) indicates
          -- an error for a R1 response.
          if get_cmd_type(command) = cmd_type_std_c then
            error_s <= spi_rxd(6)
                    or spi_rxd(5)
                    or spi_rxd(4)
                    or spi_rxd(3)
                    or spi_rxd(2)
                    or spi_rxd(1);
          -- The high bit will be set in an Data Error Token.
          elsif command = cmd_do_seek_c then
            error_s <= not spi_rxd(7);
          -- Nah, everything is fine.
          else
            error_s <= '0';
          end if;
        -- If we didn't see a response, there must have been a timeout.
        else
          -- Most internal commands actually can't time out but send 
          -- a fixed number of bytes.
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
  
  -- There's very little branching in this state machine.
  sequence : process(clock, reset)
  begin
    if reset = '1' then
      state_s <= idle_state_c;
    elsif rising_edge(clock) then
      case state_s is
        -- A `trigger` starts the state machine.
        when idle_state_c =>
          if trigger = '1' then
            state_s <= load_state_c;
          end if;
        -- After the frame was built, we always send it.
        when load_state_c =>
          state_s <= send_state_c;
        -- `send_state_c` is just a trigger for the SPI master, go on.
        when send_state_c =>
          state_s <= shft_state_c;
        -- When the SPI master is finished, it isn't `spi_busy`.
        when shft_state_c =>
          if spi_busy = '0' then
            state_s <= vrfy_state_c;
          end if;
        -- This state just verifies, the next branches.
        when vrfy_state_c =>
          state_s <= loop_state_c;
        -- Based on what `vrfy_state_c` found out, we either send 
        -- another byte or are done.
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
