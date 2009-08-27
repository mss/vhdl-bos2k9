-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This entity is a drop-in replacement for `fhw_rs232.rs232_send`
-- which sends out 512 Bytes (buffered internally) at once.
--
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library fhw_tools;
use fhw_tools.types.all;

use work.bos2k9_globals.all;

entity bos2k9_pump is
  generic(
    clock_divider  : positive;
    parity_enabled : std_logic := '1');
  port(
    clock : in  std_logic;
    reset : in  std_logic;
    
    txn : in  std_logic;
    txd : in  std_logic_byte_t;
    txb : out std_logic;
    tx  : out std_logic);
end bos2k9_pump;

-----------------------------------------------------------------------

architecture rtl of bos2k9_pump is
     component rs232_send is
    generic(
      clock_divider  : positive  := clock_divider;
      parity_enabled : std_logic := parity_enabled);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
      
      tx  : out std_logic;
      txd : in  std_logic_byte_t;
      txn : in  std_logic;
      txb : out std_logic);
   end component;
 
   component bos2k9_mmu is
    port(
      clock : in  std_logic;
      reset : in  std_logic;
    
      write_next : in  std_logic;
      write_addr : out std_logic_byte_address_t;
      write_data : in  std_logic_byte_t;
    
      read_addr : in  std_logic_byte_address_t;
      read_data : out std_logic_byte_t);
  end component;
  
  type state_t is(
    idle_state_c,
    send_state_c,
    wait_state_c,
    next_state_c);
  signal state_s : state_t;

  signal busy_s : std_logic;
  signal done_s : std_logic;
  
  signal otrg_s : std_logic;
  
  signal sout_s : std_logic_byte_t;
  signal strg_s : std_logic;
  signal sbsy_s : std_logic;

  signal iadr_s : std_logic_byte_address_t;
  signal oadr_s : std_logic_byte_address_t;
begin
  -- We're busy as soon as the state machine goes off.
  txb <= busy_s or txn;
  
  -- Just to be sure, wait until the second byte was read.
  otrg_s <= iadr_s(1);
  
  strg_s <= '1' when state_s = send_state_c
       else '0';

  sequence : process(clock, reset)
  begin
    if reset = '1' then
      state_s <= idle_state_c;
    elsif rising_edge(clock) then
      case state_s is
        when idle_state_c =>
          if otrg_s = '1' then
            state_s <= send_state_c;
          end if;
        when send_state_c =>
          state_s <= wait_state_c;
        when wait_state_c =>
          if sbsy_s = '0' then
            state_s <= next_state_c;
          end if;
        when next_state_c =>
          if done_s = '1' then
            state_s <= send_state_c;
          else
            state_s <= idle_state_c;
          end if;
      end case;
    end if;
  end process;
  
  pointer : process(clock, reset)
  begin
    if reset = '1' then
      oadr_s <= (others => '0');
    elsif rising_edge(clock) then
      if state_s = next_state_c then
        oadr_s <= std_logic_vector(unsigned(oadr_s) + 1);
      end if;
    end if;
  end process;
  
  busy_ff : process(clock, reset)
  begin
    if reset = '1' then
      busy_s <= '0';
    elsif rising_edge(clock) then
      if busy_s = '0' then
        busy_s <= txn;
      elsif state_s = next_state_c then
        busy_s <= not done_s;
      end if;
    end if;
  end process;

  done_net : process(oadr_s)
    variable done_v : std_logic;
  begin
    done_v := '1';
    for i in std_logic_byte_address_t'range loop
      done_v := done_v and oadr_s(i);
    end loop;
    done_s <= done_v;
  end process;
  
  ser_io : rs232_send port map(
    clk => clock,
    rst => reset,
    
    tx  => tx,
    txd => sout_s,
    txn => strg_s,
    txb => sbsy_s);
  mmu : bos2k9_mmu port map(
    clock => clock,
    reset => reset,
    write_next => txn,
    write_addr => iadr_s,
    write_data => txd,
    read_addr  => oadr_s,
    read_data  => sout_s);
end rtl;
