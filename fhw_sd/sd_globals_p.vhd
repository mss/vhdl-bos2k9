-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This package collects a lot of the internal logic of the SD parser
-- and state machine.  Some of this stuff should be moved to the 
-- entities where it is used.
-- 
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

  -- A traditional (non-SDHC) SD card can address 32 bit (4 GiB) of 
  -- data.  As each block is 512 Byte (9 bit) big, we need 23 bit to
  -- address all blocks.
  constant block_address_width_c : positive := 23;
  subtype  block_address_width_t is integer range 1 to block_address_width_c;
  subtype  std_logic_block_address_t is std_logic_vector(block_address_width_c - 1 downto 0);

  -- SD commands are 6 bit wide (the upper two bits are constant start
  -- bits), arguments 32 bit.  The (R1) response is 7 bit wide (the 
  -- highest bit is a constant start bit again).
  subtype  std_logic_cmd_t is std_logic_vector(5 downto 0);
  subtype  std_logic_arg_t is std_logic_vector(31 downto 0);
  subtype  std_logic_rsp_t is std_logic_vector(6 downto 0);
  
  -- We use two types of commands:  Standard SD commands and internal
  -- control commands.  We can use the sixth bit as we only implement
  -- SD commands up to 17.  A bunch of functions abstracts this 
  -- detail so we can change it easily if we have to.
  constant cmd_type_std_c : std_logic := '0';
  constant cmd_type_int_c : std_logic := '1';
  function to_cmd(
    typ : std_logic;
    idx : integer range 0 to 31) return std_logic_cmd_t;
  function get_cmd_type(
    cmd : std_logic_cmd_t) return std_logic;
  function is_std_cmd(
    cmd : std_logic_cmd_t) return std_logic;
  function is_int_cmd(
    cmd : std_logic_cmd_t) return std_logic;
  
  -- Converts an unsigned 32 bit integer to the corresponding
  -- argument bit vector.
  function to_arg(
    val : integer range 0 to 65535) return std_logic_arg_t;
  
  -- An SD (command) frame is 6 Byte, ie. 48 bit, big.  The last byte
  -- is constant and consists of a 7 bit CRC and a stop bit.  As we
  -- don't use the CRC, only CMD0 needs a CRC and is ignored for all
  -- other commands so we can just use the same value for everything.
  subtype  std_logic_frame_t is std_logic_vector(47 downto 0);
  subtype  std_logic_crc7_t  is std_logic_vector(6 downto 0);
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t;
  function shift_frame(
    frame : std_logic_frame_t) return std_logic_frame_t;
  function get_frame_head(
    frame : std_logic_frame_t) return std_logic_byte_t;
  constant crc_c : std_logic_crc7_t := "1001010";
  constant pad_c : std_logic_byte_t := (others => '1');
  constant arg_null_c : std_logic_arg_t := (others => '0');
  constant arg_ones_c : std_logic_arg_t := (others => '1');

  -- The highest value our counter has to support are 512 Byte of 
  -- data.  The top value is determined based on the current command
  -- and its argument.
  constant counter_max_c : positive := 512;
  subtype  counter_top_t is integer range 0 to counter_max_c;
  function create_counter_top(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return counter_top_t;
  
end sd_globals_p;

package body sd_globals_p is

  -- Create a SD command based on the type and the command index.
  function to_cmd(
    typ : std_logic;
    idx : integer range 0 to 31) return std_logic_cmd_t is
    variable cmd : std_logic_cmd_t;
  begin
    -- As we use '1' to encode internal commands, we can simply
    -- concat the bytes.
    cmd := typ & std_logic_vector(to_unsigned(idx, std_logic_cmd_t'length - 1));
    return cmd;
  end to_cmd;
  
  -- Determine wether the command is an internal one or a real SD 
  -- command.
  function get_cmd_type(
    cmd : std_logic_cmd_t) return std_logic is
  begin
    -- The highest bit encodes the type.
    return cmd(std_logic_cmd_t'high);
  end get_cmd_type;
  -- Determine if the command is an SD command.
  function is_std_cmd(
    cmd : std_logic_cmd_t) return std_logic is
  begin
    return not get_cmd_type(cmd);
  end is_std_cmd;
  -- Determine if the command is an internal command.
  function is_int_cmd(
    cmd : std_logic_cmd_t) return std_logic is
  begin
    return get_cmd_type(cmd);
  end is_int_cmd;
  
  -- Encode an unsigned 32 bit number as a bit vector.
  function to_arg(
    val : integer range 0 to 65535) return std_logic_arg_t is
  begin
    return std_logic_vector(to_unsigned(val, std_logic_arg_t'length));
  end to_arg;
  
  -- Create a command frame from the command, the argument and the 
  -- constant bits.
  function create_frame(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return std_logic_frame_t is
    variable frame_v : std_logic_frame_t;
  begin
    if get_cmd_type(cmd) = cmd_type_std_c then
      -- Prepend the start bits and add the CRC and the stop bit.
      frame_v := "01" & cmd & arg & crc_c & "1";
    else
      -- Internal commands always output a constant high bit stream.
      frame_v := (others => '1');
    end if;
    return frame_v;
  end create_frame;
  -- Once a byte is sent, we shift the frame buffer left and pad it 
  -- with high bits.
  function shift_frame(
    frame : std_logic_frame_t) return std_logic_frame_t is
    variable frame_v : std_logic_frame_t;
  begin
    frame_v := frame(std_logic_frame_t'high - 8 downto 0) & pad_c;
    return frame_v;
  end shift_frame;
  -- Just return the high byte of the frame buffer.
  function get_frame_head(
    frame : std_logic_frame_t) return std_logic_byte_t is
    variable head_v : std_logic_byte_t;
  begin
    head_v := frame(std_logic_frame_t'high downto std_logic_frame_t'high - 7);
    return head_v;
  end get_frame_head;

  -- Determine the top value of the counter based on command and 
  -- argument.
  function create_counter_top(
    cmd : std_logic_cmd_t;
    arg : std_logic_arg_t) return counter_top_t is
    variable cnt_v : counter_top_t;
  begin
    if get_cmd_type(cmd) = cmd_type_std_c then
      -- R1 commands are always six Byte long, followed by an optional
      -- break of up to eight Byte and the final response byte.
      cnt_v := std_logic_cmd_t'length + 8 + 1;
    else
      -- Internal commands encode their maximum length in the argument.
      cnt_v := to_integer(unsigned(arg));
    end if;
    return cnt_v;
  end create_counter_top;
  
end sd_globals_p;
