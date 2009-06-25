-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- TODO: description

-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd
library fhw_sd;
use fhw_sd.sd_globals.all;

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
    
    command  : in  std_logic_cmd_t;
    argument : in  std_logic_arg_t;
    trigger  : in  std_logic;
    response : out std_logic_rsp_t;
    shifting : out std_logic;
    
    data  : out std_logic_byte_t;
    shift : out std_logic;
    
    spi_start : out std_logic;
    spi_busy  : in  std_logic;
    spi_txd   : out std_logic_byte_t;
    spi_rxd   : in  std_logic_byte_t);
end sd_io_e;

-----------------------------------------------------------------------

architecture rtl of sd_io_e is
  component sd_counter_e is
    generic(
      max : positive := 511);
    port(
      clock  : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;
    
      top  : in  natural range 1 to 511;
      done : out std_logic);
  end component;
  signal count_top_s  : natural range 1 to 511;
  signal count_done_s : std_logic;
  
  type state_t is(
    idle_state_c,
    load_state_c,
    send_state_c,
    busy_state_c,
    shft_state_c);
  signal state_s : state_t;
  signal next_state_s : state_t;

  signal spi_start_s : std_logic;
  signal spi_busy_s  : std_logic;
  
  signal frame_s : std_logic_frame_t;

  --signal counter_s : 
begin
  shifting <= '0' when state_s = idle_state_c else '1';
  
  spi_busy_s <= spi_busy;
  spi_start <= spi_start_s;
  spi_start_s <= '1' when state_s = send_state_c else '0';
  spi_txd <= get_frame_head(frame_s);

  sequence : process(clock, reset)
  begin
    if reset = '1' then
      state_s <= idle_state_c;
    elsif rising_edge(clock) then
      case state_s is
        when idle_state_c =>
          if trigger = '1' then
            state_s <= load_state_c;
          end if;
        when load_state_c =>
          state_s <= send_state_c;
        when send_state_c =>
          state_s <= shft_state_c;
        when busy_state_c =>
          if spi_busy = '0' then
            state_s <= shft_state_c;
          end if;
        when shft_state_c =>
          null;
      end case;
    end if;
  end process;
  
  
  
  -- translate : process(clock, reset)
  -- begin
    -- if reset = '1' then
      -- spi_start_s <= '0';
      -- frame_s     <= (others => '0');
    -- elsif rising_edge(clock) then
    
      -- spi_start_s <= '0';
      
      -- frame_s <= create_frame(command, argument);
    
      -- case command is
        -- when cmd_do_reset_c =>
          -- spi_txd <= (others => '1');
          
        -- when cmd_do_start_c =>
          -- null;
        -- when cmd_set_blocklen_c =>
          -- null;
        -- when cmd_read_single_block_c =>
          
        -- when others =>
          -- null;
      -- end case;
    -- end if;
  -- end process;
  
  framer : process(clock)
  begin
    if rising_edge(clock) then
      case state_s is
        when load_state_c => frame_s <= create_frame(command, argument);
        when shft_state_c => frame_s <= frame_s(std_logic_frame_t'high - 8 downto 0) & pad_c;
        when others => null;
      end case;
    end if;
  end process;
  
  -- counter_prepare : process(clock)
  -- begin
    -- count_top_s <= to_integer(argument(8 downto 0))
    
    
  -- end;
  counter : sd_counter_e port map(
    clock => clock,
    reset => reset,
    enable => spi_start_s,
    top    => count_top_s,
    done   => count_done_s);
end rtl;
