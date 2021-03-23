use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity unified_2_to_1_ctrl is
    Port ( clk, reset : in STD_LOGIC;
           enable : in std_logic; 
           unified_buffer_2_start : in STD_LOGIC;
           
           -- for unified buffer 2 => READ
           ACTIVATION_ADDRESS : OUT BUFFER_ADDRESS_TYPE; 
           ACTIVATION_EN : OUT STD_LOGIC; 
           
           -- for unified buffer 1 => WRITE
           WRITE_ADDRESS : OUT BUFFER_ADDRESS_TYPE; 
           WRITE_EN : OUT STD_LOGIC;   
           finish_one_layer : out std_logic;          
           matrix_height : in WORD_TYPE;
           matrix_width : in WORD_TYPE 
           ); 
end unified_2_to_1_ctrl;

architecture Behavioral of unified_2_to_1_ctrl is

type state_type is (idle, wait_for_send, send, delay); 
signal state : state_type; 

signal WRITE_ADDRESS_tmp2 : BUFFER_ADDRESS_TYPE;
signal WRITE_ADDRESS_tmp : BUFFER_ADDRESS_TYPE;

signal ACTIVATION_ADDRESS_tmp2, ACTIVATION_ADDRESS_tmp : BUFFER_ADDRESS_TYPE;
signal ACTIVATION_EN_tmp2, ACTIVATION_EN_tmp : std_logic;
signal WRITE_EN_tmp2, WRITE_EN_tmp : std_logic;

signal row_count : integer; 

signal addr_for_read : integer;
signal addr_for_write : integer;

signal en_for_read : std_logic; 
signal en_for_write : std_logic;

signal en_for_write_delay : std_logic; 
signal en_for_write_delay2 : std_logic; 
signal en_for_write_delay3 : std_logic; 
signal en_for_write_delay4 : std_logic; 

signal addr_for_write_delay : integer; 
signal addr_for_write_delay2 : integer;   
signal addr_for_write_delay3 : integer; 
signal addr_for_write_delay4 : integer;   

signal delay_cnt : integer; 
signal matrix_size : integer; 

begin
matrix_size <= (to_integer(unsigned(matrix_width(7 downto 1)))* to_integer(unsigned(matrix_height(7 downto 1))));
process(clk) is begin 
if clk'event and clk='1' then
    if reset= '1' then
        state <= idle; 
    else
        if enable = '1' then 
            case state is 
                when idle =>
                    delay_cnt <= 0;
                    addr_for_read <= 0;
                    addr_for_write <= 0; 
                    en_for_read <= '0';
                    en_for_write <= '0';  
                    row_count <= 0;
                    if unified_buffer_2_start = '1' then 
                        row_count <= row_count + 1; 
                        state <= wait_for_send; 
                    else 
                        state <= idle; 
                    end if ; 
                when wait_for_send =>
                    addr_for_read <= 0;
                    addr_for_write <= 0; 
                    en_for_read <= '0';
                    en_for_write <= '0'; 
                    
                    if row_count < to_integer(unsigned(matrix_width(7 downto 2))) * to_integer(unsigned(matrix_height(7 downto 2)))  then
                        if unified_buffer_2_start = '1' then 
                            row_count <= row_count + 1; 
                            state <= wait_for_send;
                        else 
                            row_count <= row_count; 
                            state <= wait_for_send; 
                        end if; 
                    else 
                        en_for_read <= '0';
                        en_for_write <= '0'; 
                        row_count <= 0;
                        state <= delay; 
                    end if;
                when delay => 
                    if delay_cnt < 5 then
                        delay_cnt <= delay_cnt + 1;
                        state <= delay ;
                    else 
                        delay_cnt <= 0;
                        en_for_read <= '1';
                        en_for_write <= '1'; 
                        state <= send;   
                    end if;  
                    
                when send => 
                    if addr_for_read < matrix_size - 1  then
                        addr_for_read <= addr_for_read + 1;
                        addr_for_write <= addr_for_write + 1;
                        
                        en_for_read <= '1';
                        en_for_write <= '1'; 
                        
                        state <= send; 
                    else 
                        addr_for_read <= 0;
                        addr_for_write <= 0; 
                        
                        en_for_read <= '0';
                        en_for_write <= '0'; 
                        state <= idle;
                    end if;  
                    
               when others =>
                    state <= idle; 
            end case;
         end if;      
end if;     
end if;                 
end process;                   
                            
process(clk) is 
begin 
    if clk'event and clk='1' then
        addr_for_write_delay <= addr_for_write; 
        addr_for_write_delay2 <= addr_for_write_delay;
        addr_for_write_delay3 <= addr_for_write_delay2;
        addr_for_write_delay4 <= addr_for_write_delay3;
        
        en_for_write_delay <= en_for_write;
        en_for_write_delay2 <= en_for_write_delay; 
        en_for_write_delay3 <= en_for_write_delay2; 
        en_for_write_delay4 <= en_for_write_delay3; 
    end if; 
end process; 
        
                           
WRITE_ADDRESS_tmp <= std_logic_vector(to_unsigned(addr_for_write_delay2, WRITE_ADDRESS'length));
WRITE_EN_tmp <= en_for_write_delay2; 

ACTIVATION_ADDRESS_tmp <= std_logic_vector(to_unsigned(addr_for_read, ACTIVATION_ADDRESS'length)); 
ACTIVATION_EN_tmp <= en_for_read; 

finish_one_layer <= (not en_for_write_delay3) and en_for_write_delay4;

process(clk) is 
begin 
    if clk'event and clk='1' then
        WRITE_ADDRESS_tmp2 <= WRITE_ADDRESS_tmp ;
        WRITE_ADDRESS <= WRITE_ADDRESS_tmp2 ;
        
        ACTIVATION_ADDRESS_tmp2 <= ACTIVATION_ADDRESS_tmp; 
        ACTIVATION_ADDRESS <= ACTIVATION_ADDRESS_tmp2; 
        
        ACTIVATION_EN_tmp2 <= ACTIVATION_EN_tmp; 
        ACTIVATION_EN <= ACTIVATION_EN_tmp2; 
        
        WRITE_EN_tmp2 <= WRITE_EN_tmp; 
        WRITE_EN <= WRITE_EN_tmp2; 
    end if; 
end process; 

end Behavioral;
