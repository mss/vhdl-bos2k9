library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
      
      override : in std_logic;
	
	  done : out std_logic);
  end component;
  
  component spi_shifter_e
    generic(
      data_width : positive := data_width);
    port(
      clock  : in  std_logic;
	  enable : in  std_logic;
	
	  preload : in  std_logic_vector(data_width - 1 downto 0);
	  load    : in  std_logic;
	  data    : out std_logic_vector(data_width - 1 downto 0);
	
	  input  : in  std_logic;
	  output : out std_logic);
  end component;

  -- type state_t is (
    -- start_state_c,
	-- latch_state_c,
	-- shift_state_c,
	-- finis_state_c);
  -- signal state_s : state_t;
  constant state_count_c : positive := 4;
  subtype state_t is std_logic_vector(state_count_c - 1 downto 0);
  signal state_s : state_t;
  constant start_state_c : natural := 0;
  constant latch_state_c : natural := 1;
  constant shift_state_c : natural := 2;
  constant finis_state_c : natural := 3;

  signal data_s   : std_logic_vector(data_width - 1 downto 0);
  signal buffer_s : std_logic;
  signal done_s   : std_logic;
  
  signal spi_clock_s : std_logic;
  
  signal shifter_load_s : std_logic;
  signal shifter_trig_s : std_logic;
begin
  data_out <= data_s;
  done     <= done_s;
  
  spi_clock <= spi_clock_s;
  
  sequence : process(clock, reset, trigger, state_s)
  begin
    if reset = '1' then
	  state_s <= (start_state_c => '1', others => '0');
	elsif rising_edge(clock) then
	  if (state_s(start_state_c) and trigger) = '1' then
        state_s(start_state_c) <= '0';
		state_s(latch_state_c) <= '1';
	  end if;
	  if (state_s(latch_state_c) and trigger) = '1' then
        state_s(latch_state_c) <= '0';
		state_s(shift_state_c) <= '1';
	  end if;
      if (state_s(shift_state_c) and trigger) = '1' then
	    state_s(shift_state_c) <= '0';
		state_s(finis_state_c) <= '1';
	  end if;
      if (state_s(finis_state_c)) = '1' then
	    state_s(finis_state_c) <= '0';
        if done_s = '0' then
		  state_s(latch_state_c) <= '1';
		else
		  state_s(start_state_c) <= '1';
		end if;
	  end if;
	end if;
  end process;
  
  clocker : process(clock, reset, trigger, state_s)
  begin
    if reset = '1' then
	  spi_clock_s <= spi_cpol;
	elsif rising_edge(clock) then
	  if trigger = '1' then
	    if state_s(start_state_c) = '1' then
		  if spi_cpha = '1' then
		    spi_clock_s <= not spi_clock_s;
		  end if;
		else
		  spi_clock_s <= not spi_clock_s;
		end if;
	  end if;
	end if;
  end process;
  
  latcher : process(trigger, state_s)
  begin
    if (state_s(latch_state_c) and trigger) = '1' then
	  buffer_s <= spi_in;
	end if;
  end process;
  
  shifter_load_s <= state_s(start_state_c) and trigger;
  shifter_trig_s <= state_s(shift_state_c) and trigger;
  shifter : spi_shifter_e port map(
    clock  => clock,
	enable => shifter_trig_s,
	
	preload => data_in,
	load    => shifter_load_s,
	data    => data_s,
	
	input  => buffer_s,
	output => spi_out);
  
  counter : spi_counter_e port map(
    clock  => clock,
	reset  => reset,
	enable => trigger,
    
    override => '0',
	
	done => done_s);

end rtl;
