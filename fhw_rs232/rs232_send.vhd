-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232
library fhw_rs232;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rs232_send is
  generic(
    clock_interval : time;
    clock_divider  : positive; -- TODO: calculate this based on clock_interval
    data_width     : positive := 8;
    parity         : std_logic_vector(1 downto 0) := "00");
  port(
    clk : in  std_logic;
    rst : in  std_logic;
    
    tx  : out std_logic;
    txd : in  std_logic_vector(data_width - 1 downto 0);
    txn : in  std_logic;
    txb : out std_logic);
 end rs232_send;
 
-----------------------------------------------------------------------

architecture rtl of rs232_send is
  constant parity_enabled_c : std_logic := parity(1);
  constant parity_c         : std_logic := parity(0);
  
  type state_t is (
    state_idle_c,
    state_load_c,
    state_send_c,
    state_wait_c,
    state_loop_c);
  signal state_s : state_t;
  
  subtype frame_t is std_logic_vector((data_width - 1 + 2 + 1) downto 0);
  signal frame_s  : frame_t;
  signal parity_s : std_logic;
  
  signal timer_s : std_logic;
  signal done_s  : std_logic;
begin
  txb <= '0' when state_s = state_idle_c
    else '1';
  
  frame_s(frame_t'high) <= '0';
  frame_s(frame_t'high - 1 downto frame_t'high - 8) <= txd;
  frame_s(frame_t'low + 1) <= parity_s;
  frame_s(frame_t'low) <= '1';

  sequence : process(clk, rst)
  begin
    if rst = '1' then
      state_s <= state_idle_c;
    elsif rising_edge(clk) then
      case state_s is
        when state_idle_c =>
          if txn = '1' then
            state_s <= state_load_c;
          end if;
        when state_load_c =>
          state_s <= state_send_c;
        when state_send_c =>
          state_s <= state_wait_c;
        when state_wait_c =>
          if timer_s = '1' then
            state_s <= state_loop_c;
          end if;
        when state_loop_c =>
          if done_s = '0' then
            state_s <= state_send_c;
          else
            state_s <= state_idle_c;
          end if;
      end case;
    end if;
  end process;
  
  parit : process(clk, rst)
  begin
    if parity_enabled_c = '0' then
      parity_s <= '1';
    else
      -- TODO
    end if;
  end process;
end rtl;
