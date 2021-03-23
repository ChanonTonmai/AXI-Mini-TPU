use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity weight_ctrl is
    Port ( clk, reset : in STD_LOGIC;
           enable : in STD_LOGIC;
           start : in STD_LOGIC;
           en0 : out std_logic;
           base_addr : in WEIGHT_ADDRESS_TYPE;
           addr : out WEIGHT_ADDRESS_TYPE;
           valid : out std_logic;
           activate_weight : out STD_LOGIC);
end weight_ctrl;

architecture Behavioral of weight_ctrl is
    type state_type is (idle, send_data); 
    signal state : state_type;
    type state_type2 is (idle, count, valid_state); 
    signal state2 : state_type2; 
    
    signal addr_o, tmp_addr : WEIGHT_ADDRESS_TYPE;
    signal load_weight_tmp : std_logic;
    
    signal start_delay : std_logic;
    signal start_delay2 : std_logic;
    signal start_delay3 : std_logic;
--    signal start_delay4 : std_logic;
    signal cnt : integer := 0; 
    signal valid_tmp : std_logic; 
    
    
begin
addr <= addr_o;
en0 <= load_weight_tmp;
valid <= valid_tmp;

process(clk) is begin
    if clk'event and clk = '1' then
       start_delay <= start; 
       start_delay2 <= start_delay; 
       start_delay3 <= start; 
--       start_delay4 <= start_delay3; 
    end if;
end process; 

activate_weight <= start_delay2;


process(clk) is begin 
    if clk'event and clk='1' then
        case state2 is 
            when idle =>
                valid_tmp <= '0'; 
                if start_delay3 = '1' then 
                    state2 <= count; 
                else 
                    state2 <= idle;
                end if; 
                
             when count => 
                valid_tmp <= '0'; 
                if cnt < 4 then 
                    cnt <= cnt + 1 ;
                    state2 <= count;
                else 
                    cnt <= 0; 
                    state2 <= valid_state;  
                end if; 
                
              when valid_state => 
                if cnt < 4 then 
                    valid_tmp <= '1'; 
                    cnt <= cnt + 1;
                    state2 <= valid_state;
                else 
                    valid_tmp <= '0'; 
                    cnt <= 0;
                    state2 <= idle;
                end if ;   
                    
               
              when others => 
                    state2 <= idle; 
         end case; 
    end if;
end process;

process(clk) is 
begin 
    if clk'event and clk = '1' then
        if reset = '1' then
            state <= idle;
            addr_o <= (others=>'0');
            load_weight_tmp <= '0';
        else
            if enable = '1' then
                case state is 
                    when idle => 
                        load_weight_tmp <= '0';
                        addr_o <= base_addr; 
                        tmp_addr <= base_addr;
                        if start = '1' then 
                            load_weight_tmp <= '1';
                            state <= send_data;
                        else 
                            state <= idle; 
                        end if; 
                        
                    when send_data => 
                        load_weight_tmp <= '1';
                        if addr_o < std_logic_vector(unsigned(tmp_addr) + 3) then 
                            addr_o <= std_logic_vector(unsigned(addr_o) + 1);
                            state <= send_data; 
                         else 
                            load_weight_tmp <= '0';
                            state <= idle;
                            addr_o <= tmp_addr; 
                         end if; 
                            
                      
                    when others => 
                        state <= idle;
                 end case; 
            end if ;
        end if;
    end if;
 end process; 

end Behavioral;
