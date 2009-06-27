-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals_p.all;

library fhw_spi;
use fhw_spi.spi_master;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_io_e is
  port(
    clock : in std_logic;
    reset : in std_logic;
    
    frame  : in  std_logic_frame_t;
    start  : in  std_logic;
    busy   : out std_logic;
    data   : out std_logic_byte_t;
    shift  : out std_logic;
    
    cnt_tick : out std_logic;
    cnt_done : in  std_logic;
    
    spi_start : out std_logic;
    spi_busy  : in  std_logic;
    spi_txd   : out std_logic_byte_t;
    spi_rxd   : in  std_logic_byte_t);
end sd_io_e;

-----------------------------------------------------------------------

architecture rtl of sd_io_e is
  type state_t is(
    idle_state_c,
    load_state_c,
    send_state_c,
    shft_state_c,
    next_state_c);
  signal state_s : state_t;

  signal frame_s : std_logic_frame_t;
  signal done_s  : std_logic;
begin
  busy      <= '0' when state_s = idle_state_c else '1';
  shift     <= '1' when state_s = next_state_c else '0';
  data      <= spi_rxd;
  
  spi_txd   <= get_frame_head(frame_s);
  spi_start <= '1' when state_s = send_state_c else '0';
  
  cnt_tick  <= '1' when state_s = send_state_c
          else '1' when state_s = load_state_c
          else '0';

  status : process(clock)
  begin
    if rising_edge(clock) then
      if state_s = idle_state_c then
        done_s <= '0';
      elsif cnt_done = '1' then
        done_s <= '1';
      end if;
    end if;
  end process;
          
  sequence : process(clock, reset)
  begin
    if reset = '1' then
      state_s <= idle_state_c;
    elsif rising_edge(clock) then
      case state_s is
        when idle_state_c =>
          if start = '1' then
            state_s <= load_state_c;
          end if;
        when load_state_c =>
          state_s <= send_state_c;
        when send_state_c =>
          state_s <= shft_state_c;
        when shft_state_c =>
          if spi_busy = '0' then
            state_s <= next_state_c;
          end if;
        when next_state_c =>
          if done_s = '1' then
            state_s <= idle_state_c;
          else
            state_s <= send_state_c;
          end if;
      end case;
    end if;
  end process;
  
  framer : process(clock)
  begin
    if rising_edge(clock) then
      case state_s is
        when load_state_c => frame_s <= frame;
        when next_state_c => frame_s <= shift_frame(frame_s);
        when others => null;
      end case;
    end if;
  end process;
end rtl;
