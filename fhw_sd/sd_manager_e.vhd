-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_types.all;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_manager_e is
  generic(
    block_address_width : block_address_width_t);
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    address : in std_logic_vector(block_address_width - 1 downto 0);
    start   : in std_logic;
    
    ready : out std_logic;
    busy  : out std_logic;
    error : out std_logic;
    
    command  : out std_logic_cmd_t;
    argument : out std_logic_arg_t;
    response : in  std_logic_rsp_t;
    shifting : in  std_logic);
end sd_manager_e;

-----------------------------------------------------------------------

architecture rtl of sd_manager_e is
  
  type state_t is (
    rset_state_c,
    strt_state_c,
    init_state_c,
    bsiz_state_c,
    read_state_c,
    send_state_c,
    shft_state_c,
    vrfy_state_c,
    idle_state_c);
  signal curr_state_s : state_t;
  signal prev_state_s : state_t;
  signal next_state_s : state_t;
  
  signal error_s : std_logic;

begin
  
  output : process(curr_state_s, address)
  begin
    prev_state_s <= curr_state_s;
    case curr_state_s is
      when rset_state_c =>
        command  <= to_cmd(63);
        argument <= to_arg(50); -- 1+ ms: 8 SCK (1 byte) @ 400 kHz = 2.5 us * 8 = 20 us
      when strt_state_c =>
        command  <= to_cmd(62);
        argument <= to_arg(10); -- 75+ SCKs (10 byte)
      when init_state_c =>
        command  <= to_cmd(0);
        argument <= to_arg(0);
      when bsiz_state_c =>
        command  <= to_cmd(16);
        argument <= to_arg(512);
      when read_state_c =>
        command  <= to_cmd(17);
        argument <= to_arg(to_integer(unsigned(address & "000000000")));
      when others =>
        prev_state_s <= prev_state_s;
    end case;
  end process;
  
  -- verify : process(clock, reset, curr_state_s)
  -- begin
    -- if reset = '1' then
      -- error_s <= '0';
    -- elsif rising_edge(clock) then
      -- case curr_state_s is
        -- when shft_state_c =>
          -- if shifting = '0' then
            -- next_state_s <= vrfy_state_c;
          -- end if;
        -- when vrfy_state_c then
          -- if response = "00000000" then
            -- error_s <= '0';
          -- end if;
      -- end case;
    -- end if;
  -- end;
  
  sequence : process(clock, reset, next_state_s)
  begin
    if reset = '1' then
      curr_state_s <= rset_state_c;
    elsif rising_edge(clock) then
      case curr_state_s is
        when rset_state_c => curr_state_s <= strt_state_c;
        when strt_state_c => curr_state_s <= send_state_c;
        when init_state_c => curr_state_s <= send_state_c;
        when bsiz_state_c => curr_state_s <= send_state_c;
        when read_state_c => curr_state_s <= send_state_c;
        when send_state_c => curr_state_s <= shft_state_c;
        when shft_state_c => curr_state_s <= next_state_s;
        when vrfy_state_c => curr_state_s <= next_state_s;
        when idle_state_c => curr_state_s <= next_state_s;
      end case;
    end if;
  end process;
  
  -- sequence : process(clock, reset, curr_s, next_s)
  -- begin
    -- if error = '1' then
      -- next_s <= rset_state_c;
    -- else
      -- if curr_s = 
    -- end if;
    
    -- case curr_s is
      -- when rset_state_c =>
        -- next_s <= 
    -- end case;
  -- end;
  
  -- output : process(clock, reset, curr_s, next_s)
  -- begin
    
  -- end;
  
  -- transition : process(clock, reset, curr_s, next_s)
  -- begin
    -- if reset = '1' then
      -- curr_s <= reset_state_c;
    -- elsif rising_edge(clock) then
      -- curr_s <= next_s;
    -- end if;
  -- end;
  
end rtl;
