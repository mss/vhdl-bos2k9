library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is
end entity;

architecture test of spi is
  constant t : time := 1 us;
  constant n : positive := 5;
  type sck_t is(
    idle,
    latch,
    shift);
  attribute enum_encoding : string;
  attribute enum_encoding of sck_t : type is "0011 0110 1001";
  signal miso    : unsigned(3 downto 0);
  signal mosi    : unsigned(3 downto 0);
  signal ss      : bit;
  signal sck     : sck_t;
  signal sck0    : bit;
  signal sck1    : bit;
  signal sck2    : bit;
  signal sck3    : bit;
  signal trigger : bit;
begin
  mosi <= miso;
  
  sck0 <= '1' when (sck = shift) else '0';
  sck1 <= '1' when (sck = latch) else '0';
  sck2 <= not sck0;
  sck3 <= not sck1;

  process
  begin
    miso    <= (others => 'Z');
    mosi    <= (others => 'Z');
    ss      <= '1';
    sck     <= idle;
    trigger <= '0';
    
    wait for n * t;
    ss <= '0';
    wait for n * t;
    trigger <= not trigger;
    miso <= x"1";
    sck <= latch;
    wait for 1 * t;
    trigger <= not trigger;
    
    while not (miso = x"8") loop
      wait for (n - 1) * t;
      trigger <= not trigger;
      sck <= shift;
      wait for 1 * t;
      trigger <= not trigger;
    
      wait for (n - 1) * t;
      trigger <= not trigger;
      miso <= miso + 1;
      sck <= latch;
      wait for 1 * t;
      trigger <= not trigger;
    end loop;
    
    wait for (n - 1) * t;
    trigger <= not trigger;
    sck <= shift;
    wait for 1 * t;
    trigger <= not trigger;
    
    wait for (n - 1) * t;
    trigger <= not trigger;
    miso <= (others => 'Z');
    sck <= idle;
    wait for 1 * t;
    trigger <= not trigger;
    
    wait for (n - 1) * t;
    ss <= '1';
    
    wait;
  end process;
end test;
