-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Some SD related types.

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sd_globals is

  constant block_address_width_c : positive := 23; -- max 4 GiB of 512 B blocks
  subtype  block_address_width_t is integer range 1 to block_address_width_c;
  subtype  std_logic_block_address_t is std_logic_vector(block_address_width_c - 1 downto 0);

  subtype  std_logic_cmd_t is std_logic_vector(5 downto 0);
  subtype  std_logic_arg_t is std_logic_vector(31 downto 0);
  subtype  std_logic_rsp_t is std_logic_vector(6 downto 0);
  
  function to_cmd(
    number : integer range 0 to 63) return std_logic_cmd_t;
  function to_arg(
    number : integer range 0 to 65535) return std_logic_arg_t;
  
  subtype  std_logic_frame_t is std_logic_vector(47 downto 0);
  subtype  std_logic_crc7_t  is std_logic_vector(6 downto 0);
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t;
  function get_frame_head(
    frame : std_logic_frame_t) return std_logic_byte_t;
  
  constant arg_null_c : std_logic_arg_t := (others => '0');
  
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
  
  constant crc_c : std_logic_crc7_t := "1001010";
  constant pad_c : std_logic_byte_t := (others => '1');

end sd_globals;

package body sd_globals is

  function to_cmd(
    number : integer range 0 to 63) return std_logic_cmd_t is
  begin
    return std_logic_vector(to_unsigned(number, std_logic_cmd_t'length));
  end to_cmd;
  
  function to_arg(
    number : integer range 0 to 65535) return std_logic_arg_t is
  begin
    return std_logic_vector(to_unsigned(number, std_logic_arg_t'length));
  end to_arg;
  
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t is
    variable frame_v : std_logic_frame_t;
  begin
    if cmd(std_logic_cmd_t'high) = '0' then
      frame_v := "01" & cmd & arg & crc_c & "1";
    else
      frame_v := (others => '1');
    end if;
    return frame_v;
  end create_frame;
  function get_frame_head(
    frame : std_logic_frame_t) return std_logic_byte_t is
  begin
    return frame(std_logic_frame_t'high downto std_logic_frame_t'high - 7);
  end get_frame_head;

end sd_globals;
