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

  signal busy_s : std_logic;
  
  signal sout_s : std_logic_byte_t;
  signal strg_s : std_logic;
  signal sbsy_s : std_logic;

  signal iaddr_s : std_logic_byte_address_t;
  signal inull_s : std_logic;
  signal oaddr_s : std_logic_byte_address_t;
  signal onull_s : std_logic;
begin

  txb <= busy_s;

  
  
  busy_sync : process(clock, reset)
  begin
    if reset = '1' then
      busy_s <= '0';
    elsif rising_edge(clock) then
      -- Hold busy line until all data was shifted out.
      -- Assumption:  foo
      busy_s <= txn
             or sbsy_s
             or (not onull_s and not inull_s);
    end if;
  end process;

  null_net : process(iaddr_s, oaddr_s)
    variable inull_v : std_logic;
    variable onull_v : std_logic;
  begin
    inull_v := '1';
    onull_v := '1';
    for i in std_logic_byte_address_t'range loop
      inull_v := inull_v and not iaddr_s(i);
      onull_v := onull_v and not oaddr_s(i);
    end loop;
    inull_s <= inull_v;
    onull_s <= onull_v;
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
    write_addr => iaddr_s,
    write_data => txd,
    read_addr  => oaddr_s,
    read_data  => sout_s);
end rtl;
