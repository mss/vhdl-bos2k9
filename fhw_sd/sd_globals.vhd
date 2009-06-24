-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Some SD related types.

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sd_globals is

  subtype  block_address_width_t is integer range 1 to 12;

  subtype  std_logic_cmd_t is std_logic_vector(5 downto 0);
  subtype  std_logic_arg_t is std_logic_vector(31 downto 0);
  subtype  std_logic_rsp_t is std_logic_vector(7 downto 0);
  
  function to_cmd(
    number : integer range 0 to 63) return std_logic_cmd_t;
  function to_arg(
    number : integer range 0 to 65535) return std_logic_arg_t;
  
  subtype  std_logic_frame_t is std_logic_vector(47 downto 0);
  subtype  std_logic_crc7_t  is std_logic_vector(6 downto 0);
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t;
  
  constant cmd_do_reset_c : std_logic_cmd_t := to_cmd(63);
  constant arg_do_reset_c : std_logic_arg_t := to_arg(50); -- 1+ ms: 8 SCK (1 byte) @ 400 kHz = 2.5 us * 8 = 20 us
  
  constant cmd_do_idle_c : std_logic_cmd_t := to_cmd(62);
  constant arg_do_idle_c : std_logic_arg_t := to_arg(10); -- 75+ SCKs (10 byte)
  
  constant cmd_go_idle_state_c : std_logic_cmd_t := to_cmd(0);
  constant arg_go_idle_state_c : std_logic_arg_t := to_arg(0);
  
  constant cmd_set_blocklen_c : std_logic_cmd_t := to_cmd(16);
  constant arg_set_blocklen_c : std_logic_arg_t := to_arg(512);
  
  constant cmd_read_single_block_c : std_logic_cmd_t := to_cmd(17);
  constant pad_read_single_block_c : std_logic_vector(8 downto 0) := (others => '0');
  
  constant crc_c : std_logic_crc7_t := "1001010";

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
    return std_logic_vector(to_unsigned(number, 32));
  end to_arg;
  
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_cmd_t is
  begin
    return cmd(std_logic_cmd_t'high) & '1' & cmd & arg & crc_c & '1';
  end create_frame;

end sd_globals;
