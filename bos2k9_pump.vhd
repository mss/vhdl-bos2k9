-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO
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
    
    busy  : out std_logic;
    
    txn : in  std_logic;
    txd : in  std_logic_byte_t;
    tx : out std_logic);
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

  signal sout_s : std_logic_byte_t;
  signal strg_s : std_logic;
  signal sbsy_s : std_logic;

  signal iaddr_s : std_logic_byte_address_t;
  signal oaddr_s : std_logic_byte_address_t;
begin

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
