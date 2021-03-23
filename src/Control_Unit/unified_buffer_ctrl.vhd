use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity unified_buffer_ctrl is
    Port ( clk, reset : in STD_LOGIC;
           enable : in STD_LOGIC;
           start : in STD_LOGIC;
           
           base_addr : in BUFFER_ADDRESS_TYPE;
           addr : out BUFFER_ADDRESS_TYPE;
           en0 : out std_logic; 
           
           load_finish : out std_logic; 
           
           load_weight : out STD_LOGIC;
           weight_addr : out BYTE_TYPE);
end unified_buffer_ctrl;

architecture Behavioral of unified_buffer_ctrl is
    type state_type is (idle, send_data); 
    signal state : state_type;
    
    signal addr_o : BUFFER_ADDRESS_TYPE ;
    signal addr_tmp1 : BYTE_TYPE ;
    signal addr_tmp2 : BYTE_TYPE ;
    
    signal tmp_addr : BUFFER_ADDRESS_TYPE ;
    signal load_weight_tmp, load_weight_tmp1, load_weight_tmp2 : std_logic; 
    signal weight_addr_tmp : std_logic_vector(11 downto 0 ); 
    
    signal weight_cnt_int : integer; 
    
begin
addr <= addr_o;
en0 <= load_weight_tmp; 
--weight_addr <= weight_addr_tmp(7 downto 0);
--load_weight <= load_weight_tmp;


process(clk) is 
begin
    if clk'event and clk='1' then 
        load_weight_tmp1 <= load_weight_tmp;
        load_weight_tmp2 <= load_weight_tmp1;
        load_weight <= load_weight_tmp1;
     end if;
end process; 


-- weight_addr should be something like 0, 1, 2, 3
process(clk) is 
begin
    if clk'event and clk='1' then 
        addr_tmp1 <= std_logic_vector(to_unsigned(weight_cnt_int, addr_tmp1'length));
        addr_tmp2 <= addr_tmp1;
        weight_addr <= addr_tmp1; -- need to fix bug around here : cannot use addr_o as weight_addr
     end if;
end process; 

process(clk) is 
begin 
    if clk'event and clk = '1' then
        if reset = '1' then
            state <= idle;
            addr_o <= (others=>'0');
            load_weight_tmp <= '0';
            load_finish <= '0';
            weight_cnt_int <= 0;
        else
            if enable = '1' then
                case state is 
                    when idle => 
                        load_finish <= '0';
                        load_weight_tmp <= '0';
                        addr_o <= base_addr; 
                        tmp_addr <= base_addr;
                        weight_cnt_int <= 0;
                        if start = '1' then 
                            load_weight_tmp <= '1';
                            state <= send_data;
                        else 
                            state <= idle; 
                        end if; 
                        
                    when send_data => 
                        load_weight_tmp <= '1';
                        load_finish <= '0';
                        if addr_o < std_logic_vector(unsigned(tmp_addr) + 3) then
                            weight_cnt_int <= weight_cnt_int + 1; 
                            addr_o <= std_logic_vector(unsigned(addr_o) + 1);
                            state <= send_data; 
                         else
                            load_finish <= '1'; 
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
