-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the sd_flow.
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

entity sd_flow_t is
  generic(
    clock_interval : time := 20 ns);
end sd_flow_t;

-----------------------------------------------------------------------

architecture test of sd_flow_t is
  component sd_flow_e is
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
  end component;

  signal test_s : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;

  signal init_i_s     : std_logic;
  signal ready_o_s    : std_logic;  
  signal address_i_s  : std_logic_block_address_t;
  signal start_i_s    : std_logic;
  signal command_o_s  : std_logic_cmd_t;
  signal argument_o_s : std_logic_arg_t;
  signal trigger_o_s  : std_logic;
  signal shifting_i_s : std_logic;
  signal error_i_s    : std_logic;
  signal idled_i_s    : std_logic;
  signal resetted_o_s : std_logic;
  
  signal response_sent_s : std_logic;
begin
  dut : sd_flow_e port map(clock_s, reset_s,
    init_i_s,
    ready_o_s,
    address_i_s,
    start_i_s,
    command_o_s,
    argument_o_s,
    trigger_o_s,
    shifting_i_s,
    error_i_s,
    idled_i_s,
    resetted_o_s);
  
  response : process
    procedure respond(
      error : std_logic;
      idled : std_logic) is
    begin
      wait until rising_edge(trigger_o_s);
      error_i_s <= '0';
      idled_i_s <= '0';
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      wait until rising_edge(clock_s);
      error_i_s <= error;
      idled_i_s <= idled;
      response_sent_s <= '1';
      wait until rising_edge(clock_s);
      response_sent_s <= '0';
    end respond;
    procedure respond_init is
    begin
      respond('0', '0'); -- strt
      respond('0', '1'); -- idle
      respond('0', '1'); -- init
      respond('0', '1'); -- init
      respond('0', '0'); -- init
      respond('0', '0'); -- bsiz
    end;
  begin
    response_sent_s <= '0';
  
    respond_init;
    respond('1', '0');  -- read
    
    respond_init;
    respond('0', '0');   -- read
    respond('0', '0');   -- seek
    respond('0', '0');   -- pipe
    respond('0', '0');   -- skip
    respond('0', '0');   -- read
    respond('0', '0');   -- seek
    respond('0', '0');   -- pipe
    respond('0', '0');   -- skip
    
    respond('1', '0');  -- read
    
    wait;
  end process;
  shifting_i_s <= '0' when reset_s = '1'
             else '1' when trigger_o_s = '1'
             else '0' when response_sent_s = '1'
             else unaffected;
  
  initializer : process
  begin
    init_i_s <= '0';
    wait until falling_edge(reset_s);
    
    while true loop
      wait until rising_edge(clock_s);
      init_i_s <= '1';
      wait until rising_edge(clock_s);
      init_i_s <= '0';
      wait until rising_edge(resetted_o_s);
    end loop;
  end process;
  
  starter : process
  begin
    address_i_s <= (others => 'U');
    start_i_s   <= '0';
    
    wait until rising_edge(ready_o_s);
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    
    address_i_s <= (others => '0');
    start_i_s   <= '1';
    wait until rising_edge(clock_s);
    start_i_s   <= '0';
    
    wait until rising_edge(trigger_o_s);
    wait until rising_edge(trigger_o_s);
  end process;
  
  mark: process
  begin
    test_s <= -1;
    wait until falling_edge(reset_s);
    test_s <= test_s + 1;
    while true loop
      if (init_i_s or start_i_s) = '1' then
        test_s <= test_s + 1;
      end if;
      wait until rising_edge(clock_s);
    end loop;
  end process;
  
  reset : process
  begin
    reset_s <= '1';
    wait until rising_edge(clock_s);
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
