-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the RS232 sending unit in all possible combinations with
-- one byte long words (ie. 8e1, 8o1, and 8n1 which is actually 8n2).
--
-- There are two processes, one sending data while the other collects
-- the output and checks for correctnes.
--
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232_t
library fhw_rs232_t;
library fhw_rs232;
use fhw_rs232.rs232_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stefanvhdl;
use stefanvhdl.txt_util.all;

-----------------------------------------------------------------------

entity rs232_send_t is
  generic(
    clock_interval : time := 20 ns);
end rs232_send_t;

architecture test of rs232_send_t is
  -- Use a low, but not too low clock divider so we can still read the
  -- output while not entering any border cases.
  constant div_c : positive := 4;
  subtype std_logic_byte_t is std_logic_vector(7 downto 0);
  component rs232_send is
    generic(
      clock_divider  : positive;
      data_width     : positive;
      parity_enabled : std_logic;
      parity_type    : std_logic);
    port(
      clk : in  std_logic;
      rst : in  std_logic;
      
      tx  : out std_logic;
      txd : in  std_logic_byte_t;
      txn : in  std_logic;
      txb : out std_logic);
   end component;
   
   signal clock_s : std_logic;
   signal reset_s : std_logic;
   
   -- A bunch of signals for all the combinations of input and output
   -- signals.  Name format: port_format_io
   signal tx_8n1_o_s  : std_logic;
   signal txd_8n1_o_s : std_logic_byte_t;
   signal txd_8n1_i_s : std_logic_byte_t;
   signal txn_8n1_i_s : std_logic;
   signal txb_8n1_o_s : std_logic;
   signal tx_8o1_o_s  : std_logic;
   signal txd_8o1_o_s : std_logic_byte_t;
   signal txd_8o1_i_s : std_logic_byte_t;
   signal txn_8o1_i_s : std_logic;
   signal txb_8o1_o_s : std_logic;
   signal tx_8e1_o_s  : std_logic;
   signal txd_8e1_o_s : std_logic_byte_t;
   signal txd_8e1_i_s : std_logic_byte_t;
   signal txn_8e1_i_s : std_logic;
   signal txb_8e1_o_s : std_logic;
   
   signal busy_s : std_logic;
   
begin
  -- Three possible combinations of frame format.
  tx_8n1 : rs232_send generic map(div_c, 8, '0', '0') port map(clock_s, reset_s, tx_8n1_o_s, txd_8n1_i_s, txn_8n1_i_s, txb_8n1_o_s);
  tx_8o1 : rs232_send generic map(div_c, 8, '1', '0') port map(clock_s, reset_s, tx_8o1_o_s, txd_8o1_i_s, txn_8o1_i_s, txb_8o1_o_s);
  tx_8e1 : rs232_send generic map(div_c, 8, '1', '1') port map(clock_s, reset_s, tx_8e1_o_s, txd_8e1_i_s, txn_8e1_i_s, txb_8e1_o_s);
  
  -- The current test is busy until the last entity finished.
  busy_s <= txb_8n1_o_s or txb_8o1_o_s or txb_8e1_o_s;
  
  stimulus : process
    -- Send an arbitrary `word` through the entities.
    procedure send(
       word : in std_logic_byte_t) is
    begin
      txn_8n1_i_s <= '1'; txd_8n1_i_s <= word;
      txn_8o1_i_s <= '1'; txd_8o1_i_s <= word;
      txn_8e1_i_s <= '1'; txd_8e1_i_s <= word;
      wait until rising_edge(clock_s);
      txn_8n1_i_s <= '0';
      txn_8o1_i_s <= '0';
      txn_8e1_i_s <= '0';
      wait until falling_edge(busy_s);
    end send;
  begin
    wait until falling_edge(reset_s);
    
    -- Four test pattern should be enough.
    send("01000111");
    send("10010010");
    send("11111111");
    send("00000000");
    
    wait;
  end process;
  
  verify : process
    variable wait_v : natural;
  begin
    -- Nothing happened yet.
    txd_8n1_o_s <= (others => '-');
    txd_8o1_o_s <= (others => '-');
    txd_8e1_o_s <= (others => '-');
    -- Wait for the start bit.
    wait until falling_edge(tx_8n1_o_s);
    txd_8n1_o_s <= (others => 'U');
    txd_8o1_o_s <= (others => 'U');
    txd_8e1_o_s <= (others => 'U');
    -- Sync
    for i in div_c downto 1 loop
      wait until rising_edge(clock_s);
    end loop;
    -- Read eight bit.
    for i in 0 to 7 loop
      txd_8n1_o_s(i) <= tx_8n1_o_s;
      txd_8o1_o_s(i) <= tx_8o1_o_s;
      txd_8e1_o_s(i) <= tx_8e1_o_s;
      -- Sync
      for t in div_c downto 1 loop
        wait until rising_edge(clock_s);
      end loop;

      wait until rising_edge(clock_s);
    end loop;
    -- Compare input and output.
    assert txd_8n1_o_s = txd_8n1_i_s report "data mismatch 8n1: got: " & str(txd_8n1_o_s) & " exp: " & str(txd_8n1_i_s);
    assert txd_8o1_o_s = txd_8n1_i_s report "data mismatch 8o1: got: " & str(txd_8o1_o_s) & " exp: " & str(txd_8o1_i_s);
    assert txd_8e1_o_s = txd_8n1_i_s report "data mismatch 8e1: got: " & str(txd_8e1_o_s) & " exp: " & str(txd_8e1_i_s);
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
