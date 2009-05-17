-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- This is a helper entity implementing the main logic (including the
-- state machine) of the SPI master. It is driven by `clock` on the
-- rising edge but it is assumed that the `trigger` wired in by the
-- parent entity is driven on the falling edge to avoid timing issues.
-- `reset` is active high.
--
-- When `trigger` is high, data is latched or shifted, ie. `trigger`
-- must run at the double rate of the needed frequency.
--
-- Once both the data and the state machine is finished, `done` does
-- high for a single `clock`.
--
-- The meaning of the generics `data_width`, `spi_cpol` and `spi_cpha`
-- are explained in the parent entity. `spi_in` is MISO, `spi_out` MOSI
-- and `spi_clock` SCK. `data_in` is the parallel input, `data_out` the
-- output and the same constraints as described in the parent entity
-- apply.
--
-- This entity might be folded into the parent entity one day.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_spi
library fhw_spi;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
  -- This counts the SPI clock edges plus one.  Can't really remember
  -- why plus one but it made sense back then and is needed to make
  -- this stuff work.  Voodoo.
  component spi_counter_e
    generic(
      count : positive  := data_width * 2 + 1);
    port(
      clock  : in  std_logic;
      reset  : in  std_ulogic;
      enable : in  std_logic;
      
      override : in std_logic;
    
      done : out std_logic);
  end component;
  
  -- Manager of the IO. The `input` is buffered externally.
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

  -- The state machine, implemented as one-hot.  Quartus doesn't really
  -- like this and can't paint a pretty state machine from this code.
  -- But we check the current state a lot of times and encoding the
  -- states like this saved almost 50% of the MUXes. Or so, at least
  -- last time I checked.
  constant state_count_c : positive := 4;
  constant start_state_c : natural := state_count_c - 1;
  constant latch_state_c : natural := state_count_c - 2;
  constant shift_state_c : natural := state_count_c - 3;
  constant clock_state_c : natural := state_count_c - 4;
  subtype state_t is std_logic_vector(0 to state_count_c - 1);
  signal state_s : state_t;
  
  -- IO signal, will be wired to the buffer of the shifter.
  signal data_s   : std_logic_vector(data_width - 1 downto 0);
  -- We need to buffer the input on latch.
  signal buffer_s : std_logic;
  -- And a separate done signal which occurs a little later than the
  -- done signal of the shifter.
  signal done_s   : std_logic;
  
  -- This will be the SPI clock aka SCK.
  signal spi_clock_s : std_logic;
  
  -- The shifter wants a bunch of signals, here we go (`load`,
  -- `enable`, `done`).
  signal shifter_load_s : std_logic;
  signal shifter_trig_s : std_logic;
  signal shifter_done_s : std_logic;
begin
  -- These outputs are represented as signals internally.
  data_out  <= data_s;
  done      <= done_s;
  spi_clock <= spi_clock_s;
  
  -- The state machine. This process is responsible for the state
  -- transitions only, no outputs in here. As this is encoded as
  -- one-hot, each transition has to set the bit of the new state
  -- and unset the bit of the old.
  sequence : process(clock, reset, trigger, state_s, spi_clock_s)
  begin
    if reset = '1' then
      -- We start with Start, duh!
      state_s <= (start_state_c => '1', others => '0');
    elsif rising_edge(clock) then
      -- State: Start (idle state)
      -- Transition: on `trigger`
      if (state_s(start_state_c) and trigger) = '1' then
        state_s(start_state_c) <= '0';
        -- With CPHA we need an immediate edge which is essentially
        -- ignored, else we can go to Latch immediately.
        if spi_cpha = '0' then
          state_s(latch_state_c) <= '1';
        else
          state_s(clock_state_c) <= '1';
        end if;
      end if;
      -- States: Latch (buffer input) and Shift (next output)
      -- Transition: on `trigger`
      if ((state_s(latch_state_c) or state_s(shift_state_c)) and trigger) = '1' then
        -- As both Latch and Shift are followed by Clock, we can handle
        -- both here.
        state_s(latch_state_c) <= '0';
        state_s(shift_state_c) <= '0';
        state_s(clock_state_c) <= '1';
      end if;
      -- State: Clock (generate SPI clock)
      -- Transition: on `clock`, but target changes when we're finished
      if (state_s(clock_state_c)) = '1' then
        state_s(clock_state_c) <= '0';
        -- If anybody says we're done, we'll go back to Start.
        if (shifter_done_s or done_s) = '1' then
          state_s(start_state_c) <= '1';
        -- This is tricky. Check the current SPI clock state to see if
        -- we came from Latch or Shift. The second term is constant and
        -- represents that Latch is on low when both bits are equal and
        -- else on high.
        elsif spi_clock_s = (spi_cpol xor spi_cpha) then
          state_s(shift_state_c) <= '1';
        -- This is the only remaining possibility and the opposite of
        -- the check above.
        else
          state_s(latch_state_c) <= '1';
        end if;
      end if;
    end if;
  end process;
  
  -- Generates the SPI clock aka SCK depending on the current state.
  clocker : process(clock, reset, trigger, state_s, done_s, spi_clock_s)
  begin
    if reset = '1' then
      -- Tricky: CPOL changes the polarity, toggles between active low
      -- and active high. But all we have to do is initialize correctly
      -- and just invert on each clock.
      spi_clock_s <= spi_cpol;
    elsif rising_edge(clock) then
      -- We do something in Clock state only.
      if state_s(clock_state_c) = '1' then
        -- Bah, stupid CPHA again. If set, we've got to check the
        -- earlier done flag. Because... well... dunno, can't remember
        -- but I deducted this from staring at the output for a long
        -- time. Probably the first place where this whole code will
        -- fall in pieces.
        if spi_cpha = '0' then
          if done_s = '0' then
            spi_clock_s <= not spi_clock_s;
          end if;
        else
          if shifter_done_s = '0' then
            spi_clock_s <= not spi_clock_s;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- Buffering of input data.
  latcher : process(clock, trigger, state_s)
  begin
    -- We don't care about initializing properly on `reset`, not
    -- needed.
    if rising_edge(clock) then
      -- Because `trigger` is acting on falling edge, this is true at
      -- the end of each Latch state. Magic!
      if (state_s(latch_state_c) and trigger) = '1' then
        buffer_s <= spi_in;
      end if;
    end if;
  end process;
  
  -- Propagate the shifter's done signal to the global one so we can be
  -- sure that our state machine is finished.
  done_sync : process(clock, reset, state_s)
  begin
    if reset = '1' then
      done_s <= '0';
    elsif rising_edge(clock) then
      done_s <= shifter_done_s;
    end if;
  end process;
  
  -- Trigger the shifter in the correct states.
  shifter_sync : process(clock, reset, trigger, state_s)
    variable done_v : std_logic;
  begin
    if reset = '1' then
      shifter_load_s <= '0';
      shifter_trig_s <= '0';
    elsif rising_edge(clock) then
      -- Same magic as above:  `trigger` reacts on falling edges, so
      -- this is true at the end of each state.
      shifter_load_s <= state_s(start_state_c) and trigger;
      shifter_trig_s <= state_s(shift_state_c) and trigger;
    end if;
  end process;

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
    
    done => shifter_done_s);

end rtl;
