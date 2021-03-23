use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity matrix_add is
    generic (
        MATRIX_WIDTH            : natural := 4 --!< The width of the Matrix Multiply Unit and busses.
    ); 
  Port ( clk, reset : in STD_LOGIC;
         matrix_result : in WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
         valid : in std_logic;
         matrix_for_activation : out WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
         data_added_o : out std_logic; -- 
         unified_buffer_2_start : out std_logic; 
         matrix_width_for_compute : in WORD_TYPE
        
  );
end matrix_add;

architecture Behavioral of matrix_add is
type state_type is (idle, keep1,keep2, keep3, flag);
signal state : state_type; 

type state_type2 is (idle, keep);
signal state2 : state_type2; 

type state_type3 is (idle, send);
signal state3 : state_type3; 

signal first_row : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal second_row : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal third_row : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal fourth_row : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);

signal first_row_latch : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal second_row_latch : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal third_row_latch : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal fourth_row_latch : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);

signal first_row_reg_word : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal second_row_reg_word : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal third_row_reg_word : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal fourth_row_reg_word : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);

signal first_row_vector, first_row_reg, first_row_next : std_logic_vector(127 downto 0) := (others=>'0');
signal second_row_vector, second_row_reg, second_row_next : std_logic_vector(127 downto 0):= (others=>'0');
signal third_row_vector, third_row_reg, third_row_next : std_logic_vector(127 downto 0):= (others=>'0');
signal fourth_row_vector, fourth_row_reg, fourth_row_next : std_logic_vector(127 downto 0):= (others=>'0');

signal first_row_next2 : std_logic_vector(127 downto 0) := (others=>'0');
signal second_row_next2 : std_logic_vector(127 downto 0):= (others=>'0');
signal third_row_next2 : std_logic_vector(127 downto 0):= (others=>'0');
signal fourth_row_next2 : std_logic_vector(127 downto 0):= (others=>'0');



signal internal_start, real_start, data_added : std_logic; 

signal number_of_partition : BYTE_TYPE; 
signal cnt : integer := 0; 
signal cnt2 : integer := 0; 
signal data_valid, data_valid_delay1, data_valid_delay2, data_valid_edge : std_logic; 

signal data_valid_edge_tmp1 : std_logic;
signal data_valid_edge_tmp2 : std_logic;
signal data_valid_edge_tmp3 : std_logic;

signal data_added_delay : std_logic;
signal data_added_delay2 : std_logic;
signal data_added_delay3 : std_logic;
signal data_added_delay4 : std_logic;

signal rst : std_logic ;

begin
data_added_o <= data_added; 
unified_buffer_2_start <= data_added_delay4 when cnt = to_integer(unsigned(number_of_partition)) else '0'; 
process(clk) is begin 
if clk'event and clk='1' then
    data_added_delay <= data_added ;
    data_added_delay2 <= data_added_delay;
    data_added_delay3 <= data_added_delay2;
    data_added_delay4 <= data_added_delay3;
    
end if;
end process; 


process(clk, reset) is begin 
if reset = '1' then
    cnt2 <= 0;
    state3 <= idle; 
elsif clk'event and clk='1' then 
    case state3 is 
        when idle => 
            if data_added = '1' then 
                state3 <= send;
            else 
                state3 <= idle; 
            end if; 

    when send => 
      if cnt = to_integer(unsigned(number_of_partition)) then
        if cnt2 < 4 then 
            cnt2 <= cnt2 + 1;
            state3 <= send; 
        else 
            cnt2 <= 0; 
            state3 <= idle; 
        end if ;
        
        if cnt2 = 0 then 
            matrix_for_activation <= first_row_reg_word; 
        elsif cnt2 = 1 then 
            matrix_for_activation <= second_row_reg_word; 
        elsif cnt2 = 2 then 
            matrix_for_activation <= third_row_reg_word; 
        else
            matrix_for_activation <= fourth_row_reg_word; 
        end if;
        else 
            state3 <= idle;
        end if; 
    when others =>
        state3 <= idle; 
    end case;

end if; 
end process; 


number_of_partition <= "00" & matrix_width_for_compute(7 downto 2);

data_valid <= '1' when cnt = to_integer(unsigned(number_of_partition)) else '0';

process(clk) is begin 
if clk'event and clk='1' then 
    data_valid_delay1 <= data_valid;
    data_valid_delay2 <= data_valid_delay1;
end if; 
end process; 
data_valid_edge_tmp1 <= data_valid_delay1 and (not data_valid_delay2);

process(clk) is begin 
if clk'event and clk='1' then 
    data_valid_edge_tmp2 <= data_valid_edge_tmp1;
    data_valid_edge_tmp3 <= data_valid_edge_tmp2;
    data_valid_edge <= data_valid_edge_tmp3; 
end if; 
end process; 


process(clk, reset) is begin 
if clk'event and clk='1' then 
    if data_added = '1' then
        if cnt < to_integer(unsigned(number_of_partition)) then
            cnt <= cnt + 1; 
        else 
            if reset = '1' then 
                cnt <= 0;
            else
                cnt <= 1;
            end if; 
            
        end if;
    else 
        if reset = '1' then 
                cnt <= 0;
--            else
--                cnt <= 1;
            end if; 
end if;  
end if; 
end process; 


process(clk) is begin 
if clk'event and clk='1' then 
    data_added <= real_start;
end if; 
end process; 



process(clk) is begin 
    if clk'event and clk='1' then 
        if internal_start = '1' then
            real_start <= '1'; 
            first_row_latch <= first_row ;--when internal_start='1' else (others => (others => '0'));
            second_row_latch <= second_row;-- when internal_start='1' else (others => (others => '0'));
            third_row_latch <= third_row;-- when internal_start='1' else (others => (others => '0'));
            fourth_row_latch <= fourth_row;-- when internal_start='1' else (others => (others => '0'));
         else
            real_start <= '0';
    end if ;
    end if;
end process;


rst <='0';
process(clk) is begin 
    if clk'event and clk='1' then 
        case state is 
            when idle => 
                internal_start <= '0'; 
--                rst <= '0';
                if  valid = '1' then 
                    first_row <= matrix_result;
                    state <= keep1; 
--                    rst <= '0';
                else 
--                    rst <= '1';
                    state <= idle; 
                end if; 
                
             when keep1 => 
--                first_row <= matrix_result;
                if  valid = '1' then 
                    second_row <= matrix_result;
                    state <= keep2; 
                else 
                    state <= keep1; 
                end if; 
                
              when keep2 => 
--                second_row <= matrix_result;
                if  valid = '1' then 
                    third_row <= matrix_result;
                    state <= keep3; 
                else 
                    state <= keep2; 
                end if;  
              when keep3 => 
--               third_row <= matrix_result;
               if  valid = '1' then 
                   fourth_row <= matrix_result;
                   internal_start <= '1'; 
                   state <= flag; 
               else 
                   state <= keep3; 
               end if; 
               
             when flag => 
                internal_start <= '0'; 
                state <= idle;
--                rst <= '1';
             when others => 
                
               state <= idle;  
          end case;
      end if;
 end process;   
 
first_row_vector <= WORD_ARRAY_TO_BITS(first_row_latch); 
second_row_vector <= WORD_ARRAY_TO_BITS(second_row_latch); 
third_row_vector <= WORD_ARRAY_TO_BITS(third_row_latch); 
fourth_row_vector <= WORD_ARRAY_TO_BITS(fourth_row_latch); 


process(clk, reset) begin
if reset = '1' then
     first_row_reg <= (others=>'0'); 
     second_row_reg <= (others=>'0'); 
     third_row_reg <= (others=>'0'); 
     fourth_row_reg <= (others=>'0'); 
elsif clk'event and clk='1' then 
    if data_valid_edge = '1' then
         first_row_reg <= (others=>'0'); 
        second_row_reg <= (others=>'0'); 
        third_row_reg <= (others=>'0'); 
        fourth_row_reg <= (others=>'0'); 
    else
         first_row_reg <= first_row_next; 
         second_row_reg <= second_row_next; 
         third_row_reg <= third_row_next; 
         fourth_row_reg <= fourth_row_next;  
    end if;
end if;
end process;
first_row_next(31 downto 0) <= std_logic_vector(  signed(first_row_vector(31 downto 0))  + signed(first_row_reg(31 downto 0)))  when real_start='1' else first_row_reg(31 downto 0);
first_row_next(63 downto 32) <= std_logic_vector( signed(first_row_vector(63 downto 32)) + signed(first_row_reg(63 downto 32))) when real_start='1' else first_row_reg(63 downto 32);
first_row_next(95 downto 64) <= std_logic_vector( signed(first_row_vector(95 downto 64)) + signed(first_row_reg(95 downto 64))) when real_start='1' else first_row_reg(95 downto 64);
first_row_next(127 downto 96) <= std_logic_vector( signed(first_row_vector(127 downto 96)) + signed(first_row_reg(127 downto 96))) when real_start='1' else first_row_reg(127 downto 96);

second_row_next(31 downto 0) <= std_logic_vector( signed(second_row_vector(31 downto 0)) + signed(second_row_reg(31 downto 0))) when real_start='1' else second_row_reg(31 downto 0);
second_row_next(63 downto 32) <= std_logic_vector( signed(second_row_vector(63 downto 32)) + signed(second_row_reg(63 downto 32))) when real_start='1' else second_row_reg(63 downto 32);
second_row_next(95 downto 64) <= std_logic_vector( signed(second_row_vector(95 downto 64)) + signed(second_row_reg(95 downto 64))) when real_start='1' else second_row_reg(95 downto 64);
second_row_next(127 downto 96) <= std_logic_vector( signed(second_row_vector(127 downto 96)) + signed(second_row_reg(127 downto 96))) when real_start='1' else second_row_reg(127 downto 96);

third_row_next(31 downto 0) <= std_logic_vector( signed(third_row_vector(31 downto 0)) + signed(third_row_reg(31 downto 0))) when real_start='1' else third_row_reg(31 downto 0);
third_row_next(63 downto 32) <= std_logic_vector( signed(third_row_vector(63 downto 32)) + signed(third_row_reg(63 downto 32))) when real_start='1' else third_row_reg(63 downto 32);
third_row_next(95 downto 64) <= std_logic_vector( signed(third_row_vector(95 downto 64)) + signed(third_row_reg(95 downto 64))) when real_start='1' else third_row_reg(95 downto 64);
third_row_next(127 downto 96) <= std_logic_vector( signed(third_row_vector(127 downto 96)) + signed(third_row_reg(127 downto 96))) when real_start='1' else third_row_reg(127 downto 96);

fourth_row_next(31 downto 0) <= std_logic_vector( signed(fourth_row_vector(31 downto 0)) + signed(fourth_row_reg(31 downto 0))) when real_start='1' else fourth_row_reg(31 downto 0);
fourth_row_next(63 downto 32) <= std_logic_vector( signed(fourth_row_vector(63 downto 32)) + signed(fourth_row_reg(63 downto 32))) when real_start='1' else fourth_row_reg(63 downto 32);
fourth_row_next(95 downto 64) <= std_logic_vector( signed(fourth_row_vector(95 downto 64)) + signed(fourth_row_reg(95 downto 64))) when real_start='1' else fourth_row_reg(95 downto 64);
fourth_row_next(127 downto 96) <= std_logic_vector( signed(fourth_row_vector(127 downto 96)) + signed(fourth_row_reg(127 downto 96))) when real_start='1' else fourth_row_reg(127 downto 96);
 

 
 
first_row_reg_word <= BITS_TO_WORD_ARRAY(first_row_reg );
second_row_reg_word <= BITS_TO_WORD_ARRAY(second_row_reg );
third_row_reg_word <= BITS_TO_WORD_ARRAY(third_row_reg );
fourth_row_reg_word <= BITS_TO_WORD_ARRAY(fourth_row_reg );

end Behavioral;
