-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the SD host.
--
-- SPI input data is read from the text file `sd_host_t.dat` (or the
-- filename specified by the generic `spi_filename`). Each line 
-- consists of two bytes, std_logic style and separated by a single 
-- space: The first byte is the data expected from the SPI master (ie. 
-- the SD host), the second the reply to be sent. All following 
-- characters on the line are ignored and can be used as a comment.
--
-- Of course lines are only read when data is read, not while the 
-- system is idle.
--
-- If the data sent by the SD host doesn't equal the expected data,
-- an assertion is raised. Each input and output data is printed on 
-- stdout.
--
-- This test should be run about 1500 us to reach the first simulated
-- read.  A full 512 Byte block needs about 15 ms.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_sd_t
library fhw_sd_t;
library fhw_sd;
use fhw_sd.all;
use fhw_sd.sd_globals_p.all;

library fhw_tools;
use fhw_tools.types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stefanvhdl;
use stefanvhdl.txt_util.all;

use std.textio.all;

-----------------------------------------------------------------------

entity sd_host_t is
  generic(
    clock_interval : time     := 20 ns;
    clock_divider  : positive := 128;
    spi_filebase   : string   := ".";
    spi_filepath   : string   := "fhw_sd_t";
    spi_filename   : string   := "sd_host_t.dat");
end sd_host_t;

-----------------------------------------------------------------------

architecture test of sd_host_t is

  component sd_host is
    generic(
      clock_interval : time     := clock_interval;
      clock_divider  : positive := clock_divider);
    port(
      clk : in  std_logic;
      rst : in  std_logic;

      init  : in  std_logic;
      ready : out std_logic;
      error : out std_logic;
      
      address : in  std_logic_block_address_t;
      start   : in  std_logic;
      rxd     : out std_logic_byte_t;
      shd     : out std_logic;
      
      miso  : in  std_logic;
      mosi  : out std_logic;
      sck   : out std_logic;
      cs    : out std_logic);
  end component;
  
  -- These are the low eight bytes sent as the read address;
  -- if this constant is changed, the data file has to be
  -- modified as well.
  constant addr_sw_c : std_logic_byte_t := "01101010";

  constant spi_filename_c : string := spi_filebase & "/" & spi_filepath & "/" & spi_filename;
  file   spi_file         : text open read_mode is spi_filename_c;
  signal test_s           : integer;
  
  signal clock_s  : std_logic;
  signal reset_s  : std_logic;
  
  signal init_i_s     : std_logic;
  signal ready_o_s    : std_logic;
  signal error_o_s    : std_logic;
  signal address_i_s  : std_logic_block_address_t;
  signal start_i_s    : std_logic;
  signal rxd_o_s      : std_logic_byte_t;
  signal shd_o_s      : std_logic;
  signal miso_i_s     : std_logic;
  signal mosi_o_s     : std_logic;
  signal sck_o_s      : std_logic;
  signal cs_o_s       : std_logic;
  
  signal txd_s   : std_logic_byte_t;
  signal rxd_s   : std_logic_byte_t;
  signal spi_s   : spi_bus_t;
begin
  dut : sd_host port map(clock_s, reset_s,
    init_i_s,
    ready_o_s,
    error_o_s,
    address_i_s,
    start_i_s,
    rxd_o_s,
    shd_o_s,
    miso_i_s,
    mosi_o_s,
    sck_o_s,
    cs_o_s);
  miso_i_s   <= spi_s.miso;
  spi_s.mosi <= mosi_o_s;
  spi_s.sck  <= sck_o_s;
  spi_s.cs   <= cs_o_s;
  
  -- Send the init and the start signal.
  stimulus : process
  begin
    init_i_s  <= '0';
    start_i_s <= '0';
    wait until falling_edge(reset_s);
    
    init_i_s <= '1';
    wait until rising_edge(clock_s);
    init_i_s <= '0';
    
    wait until rising_edge(ready_o_s);
    start_i_s <= '1';
    wait until rising_edge(clock_s);
    start_i_s <= '0';
    
    wait;
  end process;
  
  -- Validate input and output against the data in the data file.
  -- Uses helper routines from txt_util.
  slave : process
    procedure read_skip_header is
      variable line_v  : line;
    begin
      print("reading from file " & spi_filename_c);
      readline(spi_file, line_v);
    end read_skip_header;
    procedure read_txd_and_rxd is
      variable line_v  : line;
      variable input_v : string(1 to 17);
      variable byte_v  : std_logic_byte_t;
    begin
      readline(spi_file, line_v);
      read(line_v, input_v);
      print(input_v);
      txd_s <= to_std_logic_vector(input_v(1 to 8));
      rxd_s <= to_std_logic_vector(input_v(10 to 17));
      wait until rising_edge(clock_s);
    end read_txd_and_rxd;
    variable index_v : integer;
    variable txd_v   : std_logic_byte_t;
  begin
    read_skip_header;
    rxd_s <= (others => 'Z');
    txd_v := (others => 'U');
    test_s <= 0;
    spi_s.miso <= 'Z';
    wait until falling_edge(clock_s);
    
    while true loop
      test_s <= test_s + 1;
      index_v := 7;
      read_txd_and_rxd;
      while true loop
        -- Latch on odd edges, shift on even
        spi_s.miso <= rxd_s(index_v);
        wait until rising_edge(spi_s.sck);
        txd_v(0) := spi_s.mosi;
        wait until falling_edge(spi_s.sck);
        index_v  := index_v - 1;
        if index_v = -1 then
          exit;
        end if;
        txd_v    := txd_v(6 downto 0) & 'U';
      end loop;
      test_s <= test_s + 1;
      assert txd_v = txd_s report "unexpected spi data. got: " & str(txd_v) & " expected: " & str(txd_s);
    end loop;
  end process;
  
  reset : process
  begin
    reset_s <= '1';
    wait until rising_edge(clock_s);
    wait until rising_edge(clock_s);
    reset_s <= '0';
    wait;
  end process;
  
  clock : process
  begin
    clock_s <= '0';
    wait for clock_interval / 2;
    clock_s <= '1';
    wait for clock_interval / 2;
  end process;
  
end test;
