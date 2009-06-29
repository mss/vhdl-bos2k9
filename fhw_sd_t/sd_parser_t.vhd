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
use fhw_sd.sd_commands_p.all;

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
      shifting : out std_logic;
      error    : out std_logic;
      idled    : out std_logic;
      
      pipe     : out std_logic;
      
      spi_start : out std_logic;
      spi_busy  : in  std_logic;
      spi_txd   : out std_logic_byte_t;
      spi_rxd   : in  std_logic_byte_t;
      spi_cs    : out std_logic);
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal command_i_s  : std_logic_cmd_t;
  signal argument_i_s : std_logic_arg_t;
  signal trigger_i_s  : std_logic;
  signal shifting_o_s : std_logic;
  signal error_o_s    : std_logic;
  signal idled_o_s    : std_logic;
  signal pipe_o_s     : std_logic;
  signal start_o_s    : std_logic;
  signal busy_i_s     : std_logic;
  signal txd_o_s      : std_logic_byte_t;
  signal rxd_i_s      : std_logic_byte_t;
  signal cs_o_s       : std_logic;
  
  constant address_c  : std_logic_block_address_t := "10101010101010101010101";
  
  signal counter_s : natural;
  signal delay_s   : natural;
  signal data_s    : std_logic_byte_t;
begin
  dut : sd_parser_e port map(clock_s, reset_s,
    command_i_s,
    argument_i_s,
    trigger_i_s,
    shifting_o_s,
    error_o_s,
    idled_o_s,
    pipe_o_s,
    start_o_s,
    busy_i_s,
    txd_o_s,
    rxd_i_s,
    cs_o_s);
  
  stimulus : process
    procedure send(
      cmd : std_logic_cmd_t;
      arg : std_logic_arg_t;
      cnt : natural;
      dat : std_logic_byte_t) is
    begin
      delay_s <= cnt;
      data_s  <= dat;
      command_i_s  <= cmd;
      argument_i_s <= arg;
      trigger_i_s  <= '1';
      wait until rising_edge(clock_s);
      trigger_i_s  <= '0';
      wait until falling_edge(shifting_o_s);
    end send;
  begin
    wait for clock_interval / 4;
    
    command_i_s  <= (others => 'U');
    argument_i_s <= (others => 'U');
    trigger_i_s  <= '0';
    wait until falling_edge(reset_s);
    
    -- Test internal command with argument shorter than frame size.
    send(cmd_do_skip_c,
      arg_do_skip_c,
      1, x"00");

    -- Test standard command with argument.
    send(cmd_read_single_block_c,
      address_c & pad_read_single_block_c,
      6 + 2, x"00");
    
    -- Test internal command with long argument and piping.
    send(cmd_do_pipe_c,
      arg_do_pipe_c,
      1, x"00");
    
    wait;
  end process;
  
  io_data : process
  begin
    rxd_i_s <= (others => 'U');
    
    wait until rising_edge(start_o_s);
    
    while shifting_o_s = '1' loop
      if counter_s = delay_s then
        rxd_i_s <= data_s;
      else
        rxd_i_s <= (others => '1');
      end if;
      wait until rising_edge(clock_s);
    end loop;
  end process;
  
  io_flow : process
  begin
    busy_i_s  <= '0';
    counter_s <= 0;
    
    wait until rising_edge(start_o_s);
    busy_i_s  <= '1';
    while shifting_o_s = '1' loop
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      counter_s <= counter_s + 1;
      wait until rising_edge(clock_s);
    end loop;
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
