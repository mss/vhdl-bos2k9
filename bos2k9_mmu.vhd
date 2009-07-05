-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- A simple shift register with separate read and write addresses
-- around a single 512 Byte M5K block implemented in the
-- MegaWizard generated entity `mf_block_ram'.
--
-- Input data applied to `write_data` is latched in by a high signal
-- `write_next`.  The current `write_addr` is increased by one.
--
-- Output data at the current `read_addr` can be read via `read_data`.
--
-- Writing to and reading from the same address will result in the old 
-- data.
--
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library fhw_tools;
use fhw_tools.types.all;

use work.bos2k9_globals.all;

entity bos2k9_mmu is
  port(
    clock : in  std_logic;
    reset : in  std_logic;
    
    write_next : in  std_logic;
    write_addr : out std_logic_byte_address_t;
    write_data : in  std_logic_byte_t;
    
    read_addr : in  std_logic_byte_address_t;
    read_data : out std_logic_byte_t);
end bos2k9_mmu;

-----------------------------------------------------------------------

architecture rtl of bos2k9_mmu is
  component mf_block_ram is
    port(
      clock : in  std_logic;
      wraddress : in  std_logic_byte_address_t;
      wren      : in  std_logic;
      data      : in  std_logic_byte_t;
      rdaddress : in  std_logic_byte_address_t;
      q         : out std_logic_byte_t);
  end component;
  signal write_addr_s : std_logic_byte_address_t;
  signal write_enab_s : std_logic;
begin
  write_addr <= write_addr_s;
  shifter : process(clock, reset, write_next)
  begin
    if reset = '1' then
      write_enab_s <= '0';
      write_addr_s <= (others => '0');
    elsif rising_edge(clock) then
      if write_next = '1' then
        write_enab_s <= '1';
      elsif write_enab_s = '1' then
        write_enab_s <= '0';
        if not (unsigned(write_addr_s) = 511) then
          write_addr_s <= std_logic_vector(unsigned(write_addr_s) + 1);
        else
          write_addr_s <= (others => '0');
        end if;
      end if;
    end if;
  end process;
  ram : mf_block_ram port map(
    clock => clock,
    wraddress => write_addr_s,
    wren      => write_enab_s,
    data      => write_data,
    rdaddress => read_addr,
    q         => read_data);
end rtl;
