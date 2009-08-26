-- RS232 interface.
    signal ser_send_s   : std_logic;
    signal ser_data_s   : std_logic_byte_t;
    signal ser_busy_s   : std_logic;
    
    -- Read and write addressess of the MMU.
    signal r_address_s    : std_logic_byte_address_t;
    signal r_address_lo_s : std_logic;
    signal r_address_hi_s : std_logic;
    signal w_address_s    : std_logic_byte_address_t;
    signal w_address_lo_s : std_logic;
    signal w_address_hi_s : std_logic;
    
    signal start_s : std_logic;
    signal shift_s : std_logic;
    signal write_s : std_logic;

sd_start_s <= read_btn_s and not write_s;
    
    -------------------------------------------------------------------
    
    write_s <= start_s or not r_address_lo_s;
    
    starter : process(clock_s, reset_s)
    begin
      if reset_s = '1' then
        start_s <= '0';
      elsif rising_edge(clock_s) then
        if write_s = '0' then
          start_s <= not w_address_lo_s;
        else
          start_s <= r_address_lo_s;
        end if;
      end if;
    end process;
    
    ser_send_s <= write_s and not shift_s;
    
    shifter : process(clock_s, reset_s)
    begin
      if reset_s = '1' then
        shift_s <= '0';
      elsif rising_edge(clock_s) then
        shift_s <= write_s and not ser_busy_s and not start_s;
      end if;
    end process;
    
    trigger : process(clock_s, reset_s)
    begin
      if reset_s = '1' then
        
      elsif rising_edge(clock_s) then
        
      end if;
    end process;
    
    addresser : process(clock_s, reset_s)
    begin
      if reset_s = '1' then
        r_address_s <= (others => '0');
      elsif rising_edge(clock_s) then
        if shift_s = '1' then
          r_address_s <= std_logic_vector(unsigned(r_address_s) + 1);
        end if;
      end if;
    end process;
      
      
--        if (write_s and not ser_busy_s and not start_s and not shift_s) = '1' then
--          
--          shift_s <= '1';
--        end if;
--      end if;    end process;
    
    address_net : process(r_address_s, w_address_s)
      variable r_address_lo_v : std_logic;
      variable r_address_hi_v : std_logic;
      variable w_address_lo_v : std_logic;
      variable w_address_hi_v : std_logic;
    begin
      r_address_lo_v := '1';
      r_address_hi_v := '1';
      w_address_lo_v := '1';
      r_address_hi_v := '1';
      for i in std_logic_byte_address_t'range loop
        r_address_lo_v := r_address_lo_v and not r_address_s(i);
        r_address_hi_v := r_address_hi_v and     r_address_s(i);
        w_address_lo_v := w_address_lo_v and not w_address_s(i);
        r_address_hi_v := r_address_hi_v and     w_address_s(i);
      end loop;
      r_address_lo_s <= r_address_lo_v;
      r_address_hi_s <= r_address_hi_v;
      w_address_lo_s <= w_address_lo_v;
      r_address_hi_s <= r_address_hi_v;
    end process;