-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Some SD related types.

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;

package sd_commands_p is
  constant cmd_do_reset_c : std_logic_cmd_t := to_cmd(63);
  constant arg_do_reset_c : std_logic_arg_t := to_arg(50); -- 1+ ms: 8 SCK (1 byte) @ 400 kHz = 2.5 us * 8 = 20 us
  
  constant cmd_do_start_c : std_logic_cmd_t := to_cmd(62);
  constant arg_do_start_c : std_logic_arg_t := to_arg(10); -- 75+ SCKs (10 byte)
  
  constant cmd_do_pipe_c : std_logic_cmd_t := to_cmd(61);
  constant arg_do_pipe_c : std_logic_arg_t := to_arg(512);
  
  constant cmd_go_idle_state_c : std_logic_cmd_t := to_cmd(0);
  constant arg_go_idle_state_c : std_logic_arg_t := arg_null_c;
  
  constant cmd_send_op_cond_c : std_logic_cmd_t := to_cmd(1);
  constant arg_send_op_cond_c : std_logic_arg_t := arg_null_c;
  
  constant cmd_set_blocklen_c : std_logic_cmd_t := to_cmd(16);
  constant arg_set_blocklen_c : std_logic_arg_t := to_arg(512);
  
  constant cmd_read_single_block_c : std_logic_cmd_t := to_cmd(17);
  constant pad_read_single_block_c : std_logic_vector(31 - block_address_width_c downto 0) := (others => '0');
end sd_commands_p;