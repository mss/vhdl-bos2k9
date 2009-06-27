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

package sd_globals_p is

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
  function get_cmd_type(
    cmd : std_logic_cmd_t) return std_logic;
  constant cmd_type_std_c : std_logic := '0';
  constant cmd_type_int_c : std_logic := '1';
  
  subtype  std_logic_frame_t is std_logic_vector(47 downto 0);
  subtype  std_logic_crc7_t  is std_logic_vector(6 downto 0);
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t;
  function shift_frame(
    frame : std_logic_frame_t) return std_logic_frame_t;
  function get_frame_head(
    frame : std_logic_frame_t) return std_logic_byte_t;
  
  constant arg_null_c : std_logic_arg_t := (others => '0');
  constant arg_ones_c : std_logic_arg_t := (others => '1');
  
  constant crc_c : std_logic_crc7_t := "1001010";
  constant pad_c : std_logic_byte_t := (others => '1');

  constant counter_max_c : positive := 512;
  subtype  counter_top_t is integer range 0 to counter_max_c;
  function create_counter_top(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return counter_top_t;
  
end sd_globals_p;

package body sd_globals_p is

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
  
  function get_cmd_type(
    cmd : std_logic_cmd_t) return std_logic is
  begin
    return cmd(std_logic_cmd_t'high);
  end get_cmd_type;
  
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t is
    variable frame_v : std_logic_frame_t;
  begin
    if get_cmd_type(cmd) = cmd_type_std_c then
      frame_v := "01" & cmd & arg & crc_c & "1";
    else
      frame_v := (others => '1');
    end if;
    return frame_v;
  end create_frame;
  function shift_frame(
    frame : std_logic_frame_t) return std_logic_frame_t is
  begin
    return frame(std_logic_frame_t'high - 8 downto 0) & pad_c;
  end shift_frame;
  function get_frame_head(
    frame : std_logic_frame_t) return std_logic_byte_t is
    variable head_v : std_logic_byte_t;
  begin
    head_v := frame(std_logic_frame_t'high downto std_logic_frame_t'high - 7);
    return head_v;
  end get_frame_head;

  function create_counter_top(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return counter_top_t is
    variable cnt_v : counter_top_t;
  begin
    if get_cmd_type(cmd) = cmd_type_std_c then
      cnt_v := std_logic_cmd_t'length + 8 + 1;
    else
      cnt_v := to_integer(unsigned(arg));
    end if;
    return cnt_v;
  end create_counter_top;
  
end sd_globals_p;
