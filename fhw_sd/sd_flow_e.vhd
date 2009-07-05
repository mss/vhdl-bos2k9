-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Command flow state machine.
-- 
-- This helper entity handles the SD/SPI protocol flow in combination
-- with the `sd_parser_e`.
--
-- The following ports are connected directly to the `sd_host` ports:
--  * `clock`: input, from `clk`
--  * `reset`: input, from `rst`
--  * `init`: output
--  * `ready`: output
--  * `address`: input
--  * `start`: input
--  * `error`: input
--  * `resetted`: output, to `cs`
--
-- The following ports are connected to the `sd_parser_e` ports:
--  * `command`: output, SD command
--  * `argument`: output, SD command argument
--  * `trigger`: output, start `sd_parser_e`
--  * `shifting`: input, `sd_parser_e` busy
--  * `error`: input, SD error occurred
--  * `idled`: input, SD idle mode
-- 
-- The protocol flow is handled by one big state machine handled
-- by the signals `curr_state_s`, `next_state_s`, and `prev_state_s.
--
-- There are four different kind of states, some of them branching
-- via `next_state_s`:
--
-- The idle states `rset_state_c` and `wait_state_c` loop until the
-- external events `start` or `init` happen.  In `rset_state_c` the
-- SD card is resetted by pulling the CS via `resetted` high.  An
-- `init` starts the initialization procedure which ends in
-- `wait_state_c` if successful.  Here, a `start` kicks off the block
-- reading and another `init` throws the system back into 
-- `rset_state_c`.
-- 
-- The protocol states are most states followed by `send_state_c` and
-- the intermediate state `loop_state_c`.  These set the `command` and
-- `argument` to be sent to the `sd_parser_e`.  There are both real SD
-- commands and internal ones (cf. description of `sd_parser_e`).  All
-- commands are defined in the package `sd_commands_p`.  The protocol
-- flow is determined by storing the current protocol state in 
-- `prev_state_s` and branching in `jump_state_c` after the data was 
-- sent in and verified.
--
-- The basic protocol flow after `init` is:
--  * `strt_state_c`: `cmd_do_start_c`: 75 or more SPI clocks to 
--    enable SPI mode.
--  * `idle_state_c`: `cmd_go_idle_state_c`: Put the card into idle 
--    mode.
--  * `init_state_c`: `cmd_send_op_cond_c`: Initialize the card so it 
--    accepts commands.
--  * `bsiz_state_c`: `cmd_set_blocklen_c`: Enforce a blocklen of 512 
--    Byte, just in case.
-- 
-- Because the `cmd_go_idle_state_c` has to be sent multiple times 
-- until `idled` occurs, there is another branch state `loop_state_c`
-- for a simpler lookup table in `jump_state_c`.
-- 
-- After initialization, the `address`ed block can be read as 
-- described in `sd_host`.  To handle the data, there is the fourth
-- kind of states, the data handling.  These make sure, first the gap 
-- between command execution and data retrieval is possible
-- (`seek_state_c`), then the data is shifted out (`pipe_state_c`)
-- and finally the 16 bit CRC is skipped (`skip_state_c').
--
-- Finally the fourth kind of states those handling the `sd_parser_e`:
-- `send_state_c` sets the `trigger` and puts the (idle) `sd_parser_e`
-- into `shifting` state.  Once it has shifted out all data (based on
-- `command` and `argument`), `shft_state_c` jumps to `vrfy_state_c`
-- which determines if an `error` or timeout occurred.  It then 
-- proceeds in `jump_state_c` either with the protocol or back to 
-- `rset_state_c`.
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

entity sd_flow_e is
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    init    : in  std_logic;
    ready   : out std_logic;
    
    address : in std_logic_block_address_t;
    start   : in std_logic;
    
    command  : out std_logic_cmd_t;
    argument : out std_logic_arg_t;
    trigger  : out std_logic;
    shifting : in  std_logic;
    error    : in  std_logic;
    idled    : in  std_logic;
    resetted : out std_logic);
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
  -- CS (low active) has to be high in `rset_state_c` and until 
  -- `strt_state_c` is finished.
  resetted <= '1' when curr_state_s = rset_state_c
         else '1' when curr_state_s = strt_state_c
         else '1' when prev_state_s = strt_state_c
         else '0';
  -- The `sd_host` is `ready` when it is waiting for the `start`.
  ready    <= '1' when curr_state_s = wait_state_c else '0';
  -- The `sd_parser_e` is started by `send_state_c`.
  trigger  <= '1' when curr_state_s = send_state_c else '0';
  
  -- The state flow, branching is done via the signal `next_state_s`
  -- which is set in the `branch` process below.
  sequence : process(clock, reset)
  begin
    if reset = '1' then
      curr_state_s <= rset_state_c;
    elsif rising_edge(clock) then
      case curr_state_s is
        when rset_state_c => curr_state_s <= next_state_s;
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
  
  -- Assign the correct `command` and `argument` cased on the current
  -- (protocol) state.  If these are set, the state is stored in
  -- `prev_state_s`.  The latter signal doesn't need a reset because
  -- it can't be read before it was set.
  output : process(clock, reset)
  begin
    if reset = '1' then
      command  <= (others => '0');
      argument <= (others => '0');
    elsif rising_edge(clock) then
      prev_state_s <= curr_state_s;
      case curr_state_s is
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
  
  -- All branching is based on `next_state_s` handled here.
  branch : process(clock, reset)
  begin
    if reset = '1' then
      next_state_s <= rset_state_c;
    elsif rising_edge(clock) then
      case curr_state_s is
        -- `rset_state_c` loops until `init` occurs.
        when rset_state_c =>
          if init = '1' then
            next_state_s <= strt_state_c;
          end if;
        -- `send_state_c` doesn't branch but we have to make 
        -- `shft_state_c` loop and set `next_state_s` here.
        when send_state_c =>
          next_state_s <= shft_state_c;
        -- `shft_state_c` loops until the `sd_parser_e` is done
        when shft_state_c =>
          if shifting = '0' then
            next_state_s <= vrfy_state_c;
          end if;
        -- If an `error` occurred, we reset the card, else proceed 
        -- with the protocol based on `prev_state_s`.
        when vrfy_state_c =>
          if error = '0' then
            case prev_state_s is
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
        -- If we aren't `idled` yet, we've got to send an 
        -- `cmd_send_op_cond_c` again.  Else we can proceed.with the
        -- protocol.
        when init_state_c =>
          if idled = '1' then
            next_state_s <= send_state_c;
          else
            next_state_s <= bsiz_state_c;
          end if;
        -- `wait_state_c` loops until it is told to `start` reading.
        when wait_state_c =>
          if start = '1' then
            next_state_s <= read_state_c;
          end if;
        -- The other states do depend on this signal.
        when others =>
          null;
      end case;
    end if;
  end process;
 
end rtl;
