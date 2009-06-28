-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the sd_parser.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd_t
library fhw_sd_t;
library fhw_sd;
use fhw_sd.all;
use fhw_sd.sd_globals_p.all;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------

entity sd_parser_t is
  generic(
    clock_interval : time := 20 us);
end sd_parser_t;

-----------------------------------------------------------------------

architecture test of sd_parser_t is
  component sd_parser_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      command  : in  std_logic_cmd_t;
      argument : in  std_logic_arg_t;
      trigger  : in  std_logic;
      response : out std_logic_rsp_t;
      shifting : out std_logic;
      
      pipe     : out std_logic;
      
      io_frame : out std_logic_frame_t;
      io_start : out std_logic;
      io_busy  : in  std_logic;
      io_data  : in  std_logic_byte_t;
      io_shift : in  std_logic;
      
      cnt_top  : out counter_top_t);
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal command_i_s  : std_logic_cmd_t;
  signal argument_i_s : std_logic_arg_t;
  signal trigger_i_s  : std_logic;
  signal response_o_s : std_logic_rsp_t;
  signal shifting_o_s : std_logic;
  signal pipe_o_s     : std_logic;
  signal frame_o_s    : std_logic_frame_t;
  signal start_o_s    : std_logic;
  signal busy_i_s     : std_logic;
  signal data_i_s     : std_logic_byte_t;
  signal shift_i_s    : std_logic;
  signal cnt_top_o_s  : counter_top_t;
  
  constant address_c  : std_logic_address_t := "10101010101010101010101";
begin
  dut : sd_parser_e port map(clock_s, reset_s,
    command_i_s,
    argument_i_s,
    trigger_i_s,
    response_o_s,
    shifting_o_s,
    pipe_o_s,
    frame_o_s,
    start_o_s,
    busy_i_s,
    data_i_s,
    shift_i_s,
    cnt_top_o_s);
  
  stimulus : process
  begin
    wait for clock_interval / 4;
    
    -- Test standard command with argument.
    command_s  <= cmd_read_single_block_c;
    argument_s <= address_c & pad_read_single_block_c;
    
    -- Test internal command with argument shorter than frame size.
    command_s  <= cmd_do_skip_c;
    argument_s <= arg_do_skip_c;
    
    -- Test internal command with long argument and piping.
    command_s  <= cmd_do_pipe_c;
    argument_s <= arg_do_pipe_c;
    
    wait;
  end process;
  
  reset : process
  begin
    reset_s <= '1';
    wait until rising_edge(clock_s);
    reset_s <= '0';
    wait;
  end process;
  
  clock : process
  begin
    clock_s <= '0';
    wait for clock_interval / 2;
    clock_s <= '1';
    wait for clock_interval / 2;
  end process;
  
end test;
