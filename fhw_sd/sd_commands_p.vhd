-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This package contains constants for all the supported commands used
-- by the entites `sd_parser` and `sd_flow`.
--
-- Constants starting with `cmd_do_` are internal commands, real SD
-- commands use only the prefix `cmd_` followed by the official 
-- mnemonic name.
--
-- A lot of the arguments (especially the internal ones) are constant
-- and specified here as well.
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;

package sd_commands_p is
  -- CMD0: GO_IDLE_STATE: all-zero argument
  constant cmd_go_idle_state_c : std_logic_cmd_t := to_cmd(cmd_type_std_c, 0);
  constant arg_go_idle_state_c : std_logic_arg_t := arg_null_c;
  
  -- CMD1: SEND_OP_COND: all-zero argument
  constant cmd_send_op_cond_c : std_logic_cmd_t := to_cmd(cmd_type_std_c, 1);
  constant arg_send_op_cond_c : std_logic_arg_t := arg_null_c;
  
  -- CMD16: SET_BLOCKLEN: enforce 512 Byte blocklen
  constant cmd_set_blocklen_c : std_logic_cmd_t := to_cmd(cmd_type_std_c, 16);
  constant arg_set_blocklen_c : std_logic_arg_t := to_arg(512);
  
  -- CMD17: READ_SINGLE_BLOCK: address has to be padded/shifted by nine bit
  constant cmd_read_single_block_c : std_logic_cmd_t := to_cmd(cmd_type_std_c, 17);
  constant pad_read_single_block_c : std_logic_vector(31 - block_address_width_c downto 0) := (others => '0');
  
  -- Internal: START: apply at least 75 SCKs; 10 Byte are 80 SCK
  constant cmd_do_start_c : std_logic_cmd_t := to_cmd(cmd_type_int_c, 1);
  constant arg_do_start_c : std_logic_arg_t := to_arg(10);
  
  -- Internal: SEEK: try to detect Data Token.  The argument is the timeout
  -- which isn't defined anywhere so we use a big value.
  constant cmd_do_seek_c : std_logic_cmd_t := to_cmd(cmd_type_int_c, 2);
  constant arg_do_seek_c : std_logic_arg_t := to_arg(50);
  
  -- Internal: PIPE: directly pipe incoming data from the SPI master to the
  -- output.  Do this 512 times.
  constant cmd_do_pipe_c : std_logic_cmd_t := to_cmd(cmd_type_int_c, 3);
  constant arg_do_pipe_c : std_logic_arg_t := to_arg(512);
  
  -- Internal: SKIP: ignore the 16 bit CRC following the data.
  constant cmd_do_skip_c : std_logic_cmd_t := to_cmd(cmd_type_int_c, 4);
  constant arg_do_skip_c : std_logic_arg_t := to_arg(2);
end sd_commands_p;
