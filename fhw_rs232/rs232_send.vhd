-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO
-- 
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232
library fhw_rs232;
use fhw_rs232.rs232_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rs232_send is
  generic(
    clock_interval : time;
    clock_divider  : positive; -- TODO: calculate this based on clock_interval
    data_width     : positive := 8;
    parity_enabled : std_logic := '0';
    parity_type    : std_logic := '0');
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
  type state_t is (
    state_idle_c,
    state_send_c,
    state_wait_c);
  signal state_s : state_t;
  
  subtype frame_t is std_logic_vector(data_width - 1 + 2 + 1 downto 0);
  signal frame_s : frame_t;
  signal index_s : frame_t;
  
  signal timer_s : std_logic;
  signal done_s  : std_logic;
begin
  txb <= '0' when state_s = state_idle_c
    else '1';
  
  frame_s(frame_t'high) <= '1';
  frame_s(frame_t'high - 1) <= '0';
  frame_s(frame_t'high - 2 downto frame_t'high - 2 - (data_width - 1)) <= txd;
  frame_s(frame_t'low + 1) <= get_parity(txd, parity_type) when parity_enabled = '1'
                         else frame_s(frame_t'low);
  frame_s(frame_t'low) <= '1';
  
  done_s <= index_s(frame_t'low + 0) when parity_enabled = '1'
       else index_s(frame_t'low + 1);

  output : process(clk)
    variable output_v : std_logic;
  begin
    output_v := '0';
    for i in frame_t'high downto frame_t'low loop
      output_v := output_v or (frame_s(i) and index_s(i));
    end loop;
    tx <= output_v;
  
    if rising_edge(clk) then
      case state_s is
        when state_idle_c =>
          index_s(frame_t'high) <= '1';
          index_s(frame_t'high - 1 downto frame_t'low) <= (others => '0');
        when state_send_c =>
          index_s <= '0' & index_s(frame_t'high downto frame_t'low + 1);
        when others =>
          null;
      end case;
    end if;
  end process;
  
  sequence : process(clk, rst)
  begin
    if rst = '1' then
      state_s <= state_idle_c;
    elsif rising_edge(clk) then
      case state_s is
        when state_idle_c =>
          if txn = '1' then
            state_s <= state_send_c;
          end if;
        when state_send_c =>
          state_s <= state_wait_c;
        when state_wait_c =>
          if timer_s = '1' then
            if done_s = '1' then
              state_s <= state_idle_c;
            else
              state_s <= state_send_c;
            end if;
          end if;
      end case;
    end if;
  end process;
  
end rtl;
