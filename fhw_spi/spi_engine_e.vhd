library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_engine_e is
  generic(
    data_width : positive;
	spi_cpol : std_ulogic;
	spi_cpha : std_ulogic);
  port(
    clock : in  std_logic;
	reset : in  std_ulogic;
	
	trigger : in  std_logic;
	done    : out std_logic;
	
	data_in  : in  std_logic_vector(data_width - 1 downto 0);
	data_out : out std_logic_vector(data_width - 1 downto 0);
	
	spi_in    : in  std_logic;
	spi_out   : out std_logic;
	spi_clock : out std_logic);
end spi_engine_e;

-----------------------------------------------------------------------

architecture rtl of spi_engine_e is
  component spi_counter_e
    generic(
	  count : positive := data_width * 2);
    port(
      clock  : in  std_logic;
	  reset  : in  std_ulogic;
	  enable : in  std_logic;
	
	  done : out std_logic);
  end component;

  type state_t is (
    start_state_c,
	latch_state_c,
	shift_state_c,
	finis_state_c);
  signal state_s : state_t;

  signal data_s   : std_logic_vector(data_width - 1 downto 0);
  signal buffer_s : std_logic;
  signal done_s   : std_logic;
  
  signal spi_clock_s : std_logic;
begin
  data_out <= data_s;
  done     <= done_s;
  
  spi_out  <= data_s(data_s'high);
  
  spi_clock <= spi_clock_s;
  
  sequence : process(clock, reset, trigger)
  begin
    if reset = '1' then
	  state_s  <= state_s'low;
	elsif rising_edge(clock) then
	  case state_s is
	  
	    when start_state_c =>
		  if trigger = '1' then
		    data_s <= data_in; -- snapshot
			
		    state_s <= latch_state_c;
		  end if;
		
		when latch_state_c =>
		  if trigger = '1' then
		    buffer_s <= spi_in;
			
		    state_s <= shift_state_c;
		  end if;
		
		when shift_state_c =>
		  if trigger = '1' then
		    data_s(data_s'low) <= buffer_s;
		    data_s(data_s'high downto data_s'low + 1) <= data_s(data_s'high - 1 downto data_s'low);
			
			state_s <= finis_state_c;
		  end if;
		
		when finis_state_c =>
          if done_s = '0' then
		    state_s <= latch_state_c;
		  else
		    state_s <= start_state_c;
		  end if;		
	  
	  end case;
	end if;
  end process;
  
  clocker : process(clock, reset, trigger)
  begin
    if reset = '1' then
	  spi_clock_s <= spi_cpol;
	elsif rising_edge(clock) then
	  if trigger = '1' then
	    case state_s is
		  when start_state_c =>
		    if spi_cpha = '1' then
		      spi_clock_s <= not spi_clock_s;
		    end if;
		  when others =>
		    spi_clock_s <= not spi_clock_s;
	    end case;
	  end if;
	end if;
  end process;
  
  counter : spi_counter_e port map(
    clock  => clock,
	reset  => reset,
	enable => trigger,
	
	done => done_s);

end rtl;
