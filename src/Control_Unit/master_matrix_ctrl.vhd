use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- The role of this block design is to generate 

-- base_addr is the base address for input matix 
-- weight_base_addr is the base address for weight matrix 
-- base_addr_2 is the base address for saving temporary matrix 

-- The reason for generate this is because we have limit processing element, (now we has 4*4 PE)
-- so, we need to schedule the these data 

-- THe example computation is here 
        -- To perfrom AxB which A and B is 8x8 matrix, so we need to separate the matrix
-- Note that in this case, A is think as weight and B is input matrix 
-- A and B will be separate to 
-- | A1 A2 | and | B1 B2 |
-- | A3 A4 |     | B3 B4 |
-- The result should be 
-- | A1xB1 + A2xB3 A1xB2 + A2xB4 |
-- | A3xB1 + A4xB3 A3xB2 + A4xB4 |

-- so when we store the data 
-- A1 -> 0x00, B1 -> 0x00
-- A2 -> 0x04, B2 -> 0x04
-- A3 -> 0x08, B3 -> 0x08
-- A4 -> 0x0C, B4 -> 0x0C
-- Therefore, when compute 
-- 1. perfrom A1xB1 => weight_base_addr <= 0 and base_addr <= 0 
-- 2. perfrom A2xB3 => weight_base_addr <= 4 and base_addr <= 8 

-- 3. perfrom A1xB2 => weight_base_addr <= 0 and base_addr <= 4 
-- 4. perfrom A2xB4 => weight_base_addr <= 4 and base_addr <= 12 

-- 5. perfrom A3xB1 => weight_base_addr <= 8 and base_addr <= 0 
-- 6. perfrom A4xB3 => weight_base_addr <= 12 and base_addr <= 8 

-- 7. perfrom A3xB2 => weight_base_addr <= 8 and base_addr <= 4 
-- 8. perfrom A4xB4 => weight_base_addr <= 12 and base_addr <= 12 

-- This is the example testbench data which we need to send the data base on this reference
-- We need to wait for 30 clk cycle for compute in each portion
-- The first portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(0, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(0, 15));
--base_addr_2 <= std_logic_vector(to_unsigned(0,12));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

---- second portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(8, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(4, 15));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

---- third portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(4, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(0, 15));
--base_addr_2 <= std_logic_vector(to_unsigned(4,12));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

---- fourth portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(12, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(4, 15));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';


---- 5th portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(0, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(8, 15));
--base_addr_2 <= std_logic_vector(to_unsigned(8,12));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

---- 6th portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(8, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(12, 15));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

---- 7th portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(4, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(8, 15));
--base_addr_2 <= std_logic_vector(to_unsigned(12,12));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

---- 8th portion
--wait for 300 ns; 
--base_addr <= std_logic_vector(to_unsigned(12, 12));
--weight_base_addr <= std_logic_vector(to_unsigned(12, 15));
--START_TMP <='1';
--wait until '1'=CLK and CLK'event;
--START_TMP <='0';

entity master_matrix_ctrl is
    Port ( clk, reset : in STD_LOGIC;
           matrix_start : in std_logic; 
           matrix_base_addr : in WORD_TYPE; 
           input_matrix_width : in WORD_TYPE;
           input_matrix_height : in WORD_TYPE;
           weight_matrix_width : in WORD_TYPE;
           weight_matrix_height : in WORD_TYPE;
           start : out STD_LOGIC;
           base_addr : out BUFFER_ADDRESS_TYPE;
           weight_base_addr : out WEIGHT_ADDRESS_TYPE;
           base_addr_2 : out BUFFER_ADDRESS_TYPE);
end master_matrix_ctrl;

-- To generate base_addr, weight_base_addr and base_addr_2, we need to know the size of matrix 
architecture Behavioral of master_matrix_ctrl is

type state_type is (idle, send, send2,send3, w8);
signal state : state_type; 

signal cnt : integer; 

signal round_cnt : integer range 0 to 1000; 

signal weight_row_cnt : integer range 0 to 63; 
signal weight_col_cnt : integer range 0 to 63; 
signal weight_addr_int : integer range 0 to 511; 
 
signal input_row_cnt : integer range 0 to 63; 
signal input_col_cnt : integer range 0 to 63; 
signal input_addr_int : integer range 0 to 511;


signal weight_temp_cnt : integer range 0 to 511; 


signal weight_high_address : integer range 0 to 511;
signal input_high_address : integer range 0 to 511; 

signal base_addr2_cnt : integer range 0 to 511;
signal base_addr2_int : integer range 0 to 511; 

attribute USE_DSP48 : string;
attribute USE_DSP48 of input_addr_int : signal is "YES";
attribute USE_DSP48 of weight_addr_int : signal is "YES";

SIGNAL  base_addr_2_delay, base_addr_2_delay2, base_addr_2_delay3, base_addr_2_delay4 : BUFFER_ADDRESS_TYPE;
SIGNAL  base_addr_2_delay5, base_addr_2_delay6, base_addr_2_delay7, base_addr_2_delay8 : BUFFER_ADDRESS_TYPE;

signal weight_temp_constant : integer; 
signal start_signal : std_logic; 
begin

weight_high_address <= ((to_integer(unsigned(weight_matrix_width))/4)*(to_integer(unsigned(weight_matrix_height))/4))*4-4;
input_high_address <= ((to_integer(unsigned(input_matrix_width))/4)*(to_integer(unsigned(input_matrix_height))/4))*4-4;

weight_temp_constant <= to_integer(unsigned(weight_matrix_width(7 downto 2)))* to_integer(unsigned(input_matrix_width(7 downto 2))) ;

base_addr <= std_logic_vector(to_unsigned(input_addr_int, base_addr'length)); 
weight_base_addr <= std_logic_vector(to_unsigned(weight_addr_int, weight_base_addr'length));
--base_addr_2 <= std_logic_vector(to_unsigned(base_addr2_int, base_addr_2'length));

process(clk) is begin 
    if clk'event and clk='1' then
        base_addr_2_delay <= std_logic_vector(to_unsigned(base_addr2_int, base_addr_2'length)); 
        base_addr_2_delay2 <= base_addr_2_delay;
        base_addr_2_delay3 <= base_addr_2_delay2;
        base_addr_2_delay4 <= base_addr_2_delay3;
        base_addr_2_delay5 <= base_addr_2_delay4;
        base_addr_2_delay6 <= base_addr_2_delay5;
        base_addr_2_delay7 <= base_addr_2_delay6;
        base_addr_2 <= base_addr_2_delay7;
    end if;
end process; 
process(clk) is begin 
if clk'event and clk='1' then 
    case state is 
        when idle =>
            cnt <= 0;
            start_signal <= '0';
             
            round_cnt <= 0;
            weight_row_cnt <= 0;
            weight_col_cnt <= 0;
            input_row_cnt <= 0;
            input_col_cnt <= 0; 
            
--            weight_addr_int <= 0;
--            input_addr_int <= 0; 


            weight_temp_cnt <= 0;
            base_addr2_cnt <= 0;
            base_addr2_int <= 0;
            
            if matrix_start = '1' then 
                state <= w8 ;
            else 
                state <= idle; 
            end if ; 
            
        when w8 => 
            start_signal <= '0';
            if cnt < 19-1 then 
                cnt <= cnt + 1; 
                state <= w8; 
            else 
                cnt <= 0; 
                start_signal <= '1';
--                round_cnt <= round_cnt + 1; 
                state <= send; 
            end if; 
        
        when send => 
            -- send base_addr, weight_base_addr, and base_addr 
            
            round_cnt <= round_cnt + 1; 
--            weight_row_cnt <= weight_row_cnt + 1; -- posible value : 0, 1, 2, ... , weiht_matrix_width/4 - 1
--            weight_col_cnt <= weight_col_cnt + 1; -- posible value : 0, 1, 2, ... , weight_mtrix_height/4 - 1
            
            --input_row_cnt <= input_row_cnt + 1; 
            
            if input_row_cnt < to_integer(unsigned(input_matrix_height))/4-1 then 
                input_row_cnt <= input_row_cnt + 1; 
            else 
                input_row_cnt <= 0;
            end if; 
            
            if input_row_cnt = to_integer(unsigned(input_matrix_height))/4-1 then 
                if input_col_cnt < to_integer(unsigned(input_matrix_width))/4-1 then
                    input_col_cnt <= input_col_cnt + 1; 
                else 
                    input_col_cnt <= 0;
                end if;
            end if; 
--            weight_addr_int <= weight_col_cnt*to_integer(unsigned(weight_matrix_width)) + 4; 
            
            if weight_row_cnt < to_integer(unsigned(weight_matrix_height))/4-1 then
                weight_row_cnt <= weight_row_cnt + 1;
            else 
                weight_row_cnt <= 0 ;
            end if; 
            
            if weight_temp_cnt < weight_temp_constant-1 then
                weight_temp_cnt <= weight_temp_cnt + 1;
            else 
                weight_temp_cnt <= 0; 
            end if ;
            
            if weight_temp_cnt = weight_temp_constant-1 and weight_temp_cnt /= 0 then
                weight_col_cnt <= (weight_col_cnt + 1);
            end if; 
--            state <= send2;
            
--       when send2 => 
       
            input_addr_int <= input_row_cnt*to_integer(unsigned(input_matrix_width)) + 4*input_col_cnt;
--            state <= send3; 
            
--       when send3 =>
--            start <= '1'; 
            weight_addr_int <= weight_col_cnt*to_integer(unsigned(weight_matrix_width)) + 4*weight_row_cnt ; 

            if input_row_cnt = to_integer(unsigned(input_matrix_height))/4-1 then 
                base_addr2_cnt <= base_addr2_cnt + 1; 
            end if; 
            
            base_addr2_int <= base_addr2_cnt*4;
            
            if input_addr_int = input_high_address and weight_addr_int = weight_high_address then 
                state <= idle;
            else
                state <= w8; 
            end if; 
--            state <= w8; 
            
        when others =>
            state <= idle; 
            
      end case; 
end if; 
end process; 
start <= start_signal when state <= send else '0';
--input_addr_int <= input_row_cnt*to_integer(unsigned(input_matrix_width)) + 4*input_col_cnt;
--weight_addr_int <= weight_row_cnt*4 + weight_col_cnt*to_integer(unsigned(weight_matrix_width));     

end Behavioral;
