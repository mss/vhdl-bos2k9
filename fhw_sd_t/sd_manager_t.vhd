-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the sd_manager.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd_t
library fhw_sd_t;
library fhw_sd;
use fhw_sd.all;
use fhw_sd.sd_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------

entity sd_manager_t is
  generic(
    clock_interval : time := 20 us);
end sd_manager_t;

-----------------------------------------------------------------------

architecture test of sd_manager_t is
  component sd_manager_e is
    port(
      clock : in std_logic;
      reset : in std_logic;
    
      address : in std_logic_block_address_t;
      start   : in std_logic;
      
      ready : out std_logic;
      busy  : out std_logic;
      error : out std_logic;
    
      command  : out std_logic_cmd_t;
      argument : out std_logic_arg_t;
      trigger  : out std_logic;
      response : in  std_logic_rsp_t;
      shifting : in  std_logic);
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal address_i_s  : std_logic_block_address_t;
  signal start_i_s    : std_logic;
  signal ready_o_s    : std_logic;
  signal busy_o_s     : std_logic;
  signal error_o_s    : std_logic;
  signal command_o_s  : std_logic_cmd_t;
  signal argument_o_s : std_logic_arg_t;
  signal trigger_o_s  : std_logic;
  signal response_i_s : std_logic_rsp_t;
  signal shifting_i_s : std_logic;
  
  signal response_sent_s : std_logic;
begin
  dut : sd_manager_e port map(clock_s, reset_s,
                       address_i_s,
                       start_i_s,
                       ready_o_s,
                       busy_o_s,
                       error_o_s,
                       command_o_s,
                       argument_o_s,
                       trigger_o_s,
                       response_i_s,
                       shifting_i_s);
  
  stimulus : process
  begin
    wait for clock_interval / 4;
  
    address_i_s <= (others => 'U');
    start_i_s   <= '0';
  
    wait until falling_edge(busy_o_s);
    
    address_i_s <= (others => '0');
    start_i_s   <= '0'; -- TODO
  
    wait;
  end process;
  
  response : process
    procedure respond(
      rsp : std_logic_rsp_t) is
    begin
      wait until rising_edge(trigger_o_s);
      response_i_s <= (others => 'U');
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      response_i_s <= rsp;
      response_sent_s <= '1';
      wait until rising_edge(clock_s);
      response_sent_s <= '0';
    end respond;
  begin
    response_sent_s <= '0';
  
    respond("0000000");
    
    wait;
  end process;
  
  shifting_i_s <= '0' when reset_s = '1'
             else '1' when trigger_o_s = '1'
             else '0' when response_sent_s = '1'
             else unaffected;
  
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
