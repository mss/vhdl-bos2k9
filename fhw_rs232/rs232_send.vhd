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
    clock_divider  : positive;
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
  component rs232_counter_e is
    generic(
      count : positive := clock_divider);
    port(
      clock  : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;
      
      done : out std_logic);
  end component;

  type state_t is (
    state_idle_c,
    state_send_c,
    state_wait_c);
  signal state_s : state_t;
  
  subtype frame_t is std_logic_vector((2 + data_width + 2) - 1 downto 0);
  signal frame_s : frame_t;
  signal index_s : frame_t;
  
  signal sending_s : std_logic;
  signal timer_s   : std_logic;
  
  signal done_s  : std_logic;
begin
  txb <= '0' when state_s = state_idle_c
    else '1';
  
  frame_s(frame_t'high - 0) <= '1'; -- Stop
  frame_s(frame_t'high - 1) <= get_parity(txd, parity_type) when parity_enabled = '1'
                          else frame_s(frame_t'high);
  frame_s(frame_t'high - 2 downto frame_t'low + 2) <= txd;
  frame_s(frame_t'low + 1) <= '0'; -- Start
  frame_s(frame_t'low + 0) <= '1'; -- Idle
  
  done_s <= index_s(frame_t'high);

  output : process(frame_s, index_s)
    variable output_v : std_logic;
  begin
    output_v := '0';
    for i in frame_t'range loop
      output_v := output_v or (frame_s(i) and index_s(i));
    end loop;
    tx <= output_v;
  end process;
  
  shifter : process(clk, rst)
  begin
    if rst = '1' then
      index_s(frame_t'low) <= '1';
      index_s(frame_t'high downto frame_t'low + 1) <= (others => '0');
    elsif rising_edge(clk) then
      if state_s = state_send_c then
        index_s <= index_s(frame_t'high - 1 downto frame_t'low) & index_s(frame_t'high);
      end if;
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
  
  sending_s <= '1' when state_s = state_wait_c
          else '0';
  trigger : rs232_counter_e port map(
    clock  => clk,
    reset  => rst,
    enable => sending_s,
    
    done   => timer_s);
end rtl;
