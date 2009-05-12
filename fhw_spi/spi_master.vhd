library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------------------------------------

entity spi_master is
  generic(
    clk_div    : positive := 10;
	data_width : positive :=  8;
	spi_mode   : integer range 0 to 3 := 0);
  port(
    clk : in  std_logic;
	rst : in  std_logic;
	
	start : in  std_logic;
	busy  : out std_logic;
	
	txd   : in  std_logic_vector(data_width - 1 downto 0);
	rxd   : out std_logic_vector(data_width - 1 downto 0);
	
	miso  : in  std_logic;
	mosi  : out std_logic;
	sck   : out std_logic);
end spi_master;

-----------------------------------------------------------------------

use ieee.numeric_std.all;

architecture rtl of spi_master is
  constant spi_mode_c : unsigned(1 downto 0) := to_unsigned(spi_mode, 2);
  constant spi_cpol_c : std_logic := spi_mode_c(0);
  constant spi_cpha_c : std_logic := spi_mode_c(1);
  
  component spi_counter_e
    generic(
	  count : positive := clk_div / 2);
    port(
      clock  : in  std_logic;
	  reset  : in  std_ulogic;
	  enable : in  std_logic;
	
	  done : out std_logic);
  end component;
  
  component spi_starter_e
    port(
      clock   : in  std_logic;
      reset   : in  std_logic;
	
	  start   : in  std_logic;
	  stop    : in  std_logic;
    
      status  : out std_logic);
  end component;
  
  component spi_engine_e
    generic(
      data_width : positive := data_width;
	  spi_cpol   : std_logic := spi_cpol_c;
	  spi_cpha   : std_logic := spi_cpha_c);
    port(
      clock : in  std_logic;
	  reset : in  std_ulogic;
	
	  trigger : in  std_logic;
	  done    : out std_logic;
	
	  data_in  : in  std_logic_vector(data_width - 1 downto 0);
	  data_out : out std_logic_vector(data_width - 1 downto 0);
	
	  spi_in   : in  std_logic;
	  spi_out  : out std_logic);
  end component;

  signal clock_s : std_logic;
  signal reset_s : std_logic;
  
  signal start_s   : std_logic;
  signal stop_s    : std_logic;
  signal running_s : std_logic;
  
  signal trigger_s : std_logic;
  
  signal data_in_s  : std_logic_vector(data_width - 1 downto 0);
  signal data_out_s : std_logic_vector(data_width - 1 downto 0);
  
  signal spi_in_s    : std_logic;
  signal spi_out_s   : std_logic;
  signal spi_clock_s : std_logic;
begin
  clock_s <= clk;
  reset_s <= rst;
  
  start_s <= start and not running_s; -- make sure we don't trigger a start while running
  busy    <= running_s;
  
  -- Direct output; beware of hazards!
  data_in_s <= txd;
  rxd <= data_out_s;
  
  spi_in_s <= miso;
  mosi <= spi_out_s;
  sck <= spi_clock_s;
  
  starter : spi_starter_e port map(
    clock  => clock_s,
	reset  => reset_s,
	
	start   => start_s,
	stop    => stop_s,
	
	status  => running_s);
	
  trigger : spi_counter_e port map(
    clock  => clock_s,
	reset  => reset_s,
	enable => running_s,
	
	done   => trigger_s);
	
  engine : spi_engine_e port map(
    clock => clock_s,
	reset => reset_s,
	
	trigger => trigger_s,
	done    => stop_s,
	
	data_in  => data_in_s,
	data_out => data_out_s,
	
	spi_in   => spi_in_s,
	spi_out  => spi_out_s);
	
	
  -- engine : spi_engine_e port map(
    -- clock => clock_s,
	-- reset => reset_s,
	
	-- running => status_s,
	-- trigger => trigger_s,
	
	
	-- done    => stop_s,
	
	
  -- );
  
  

  -- spi_gen : process(clock_s, reset_s, running_s, trigger_s)
    -- variable old_running_v : std_logic;
    -- variable old_clock_v : std_logic;
  -- begin
    -- if reset_s = '1' then
	  -- spi_out_s   <= '0';
	  -- spi_clock_s <= spi_cpol_c;
	-- elsif rising_edge(clock_s) then
	  -- if running_s = '1' and trigger_s = '1' then
	    -- old_clock_v := spi_clock_s;
	    -- spi_clock_s <= not spi_clock_s;
		
		-- if old_clock_v = spi_cpol_c then
		  -- if spi_cpha_c = '0' then
		    -- spi_out_s <= data_s(0);
		    -- data_s(6 downto 0) <= data_s(7 downto 1);
			
		  -- else
		    
		  -- end if;
		-- else
		  -- if spi_cpha_c = '1' then
		    -- spi_out_s <= data_s(0);
			-- data_s(6 downto 0) <= data_s(7 downto 1);
		  -- else
		    
		  -- end if;
		-- end if;
	  -- end if;
	-- end if;
  -- end process;
  
end rtl;
