----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/08/2021 08:38:16 PM
-- Design Name: 
-- Module Name: TPU_CORE_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.TPU_pack.all;
use IEEE.NUMERIC_STD.ALL;

entity TPU_CORE_top is
Port ( 
        CLK, RESET          : in  std_logic;
        ENABLE              : in  std_logic;
            
        matrix_start        : in std_logic; 
        input_matrix_width  : in std_logic_vector(31 downto 0); --<= x"00000008";          
        input_matrix_height  : in std_logic_vector(31 downto 0); --<= x"00000008"; 
          
        weight_matrix_width  : in std_logic_vector(31 downto 0); --<= x"00000008";     
        weight_matrix_height : in std_logic_vector(31 downto 0); --<= x"00000008"; 
        ACTIVATION_FUNCTION : in std_logic_vector(3 downto 0);
        finish_one_layer : out std_logic; 
    
        WEIGHT_WRITE_PORT   : in  std_logic_vector(31 downto 0); --!< Host write port for the weight buffer
        WEIGHT_ADDRESS      : in  std_logic_vector(15-1 downto 0); --!< Host address for the weight buffer.
        WEIGHT_ENABLE       : in  std_logic; --!< Host enable for the weight buffer.
        WEIGHT_WRITE_ENABLE : in  std_logic_vector(0 to 4-1); --!< Host write enable for the weight buffer.
        
        BUFFER_WRITE_PORT   : in  std_logic_vector(31 downto 0); --!< Host write port for the unified buffer.
        BUFFER_READ_PORT    : out std_logic_vector(31 downto 0); --!< Host read port for the unified buffer.
        BUFFER_ADDRESS      : in  std_logic_vector(12-1 downto 0); --!< Host address for the unified buffer.
        BUFFER_ENABLE       : in  std_logic; --!< Host enable for the unified buffer.
        BUFFER_WRITE_ENABLE : in  std_logic_vector(0 to 4-1) --!< Host write enable for the unified buffer.
);
end TPU_CORE_top;

architecture Behavioral of TPU_CORE_top is
constant MATRIX_WIDTH   : natural := 4;
component TPU_CORE is
generic(
    MATRIX_WIDTH            : natural := 4; --!< The width of the Matrix Multiply Unit and busses.
    WEIGHT_BUFFER_DEPTH     : natural := 32768; --!< The depth of the weight buffer.
    UNIFIED_BUFFER_DEPTH    : natural := 4096 --!< The depth of the unified buffer.
);
    port(
    CLK, RESET          : in  std_logic;
    ENABLE              : in  std_logic;
    
    matrix_start        : in std_logic; 
    input_matrix_width  : in WORD_TYPE; --<= x"00000008";          
    input_matrix_height  : in WORD_TYPE; --<= x"00000008"; 
      
    weight_matrix_width  : in WORD_TYPE; --<= x"00000008";     
    weight_matrix_height : in  WORD_TYPE; --<= x"00000008"; 
    ACTIVATION_FUNCTION_AS_TYPE : in ACTIVATION_TYPE;
    finish_one_layer : out std_logic; 
    

    WEIGHT_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the weight buffer
    WEIGHT_ADDRESS      : in  WEIGHT_ADDRESS_TYPE; --!< Host address for the weight buffer.
    WEIGHT_ENABLE       : in  std_logic; --!< Host enable for the weight buffer.
    WEIGHT_WRITE_ENABLE : in  std_logic_vector(0 to MATRIX_WIDTH-1); --!< Host write enable for the weight buffer.
    
    BUFFER_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the unified buffer.
    BUFFER_READ_PORT    : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host read port for the unified buffer.
    BUFFER_ADDRESS      : in  BUFFER_ADDRESS_TYPE; --!< Host address for the unified buffer.
    BUFFER_ENABLE       : in  std_logic; --!< Host enable for the unified buffer.
    BUFFER_WRITE_ENABLE : in  std_logic_vector(0 to MATRIX_WIDTH-1) --!< Host write enable for the unified buffer.
);
end component;

signal WEIGHT_WRITE_PORT_ARRAY : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal BUFFER_READ_PORT_ARRAY, BUFFER_WRITE_PORT_ARRAY : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
signal ACTIVATION_FUNCTION_AS_TYPE : ACTIVATION_TYPE;

begin

WEIGHT_WRITE_PORT_ARRAY <= BITS_TO_BYTE_ARRAY(WEIGHT_WRITE_PORT);
BUFFER_WRITE_PORT_ARRAY <= BITS_TO_BYTE_ARRAY(BUFFER_WRITE_PORT);
ACTIVATION_FUNCTION_AS_TYPE <= BITS_TO_ACTIVATION(ACTIVATION_FUNCTION);

    TPU_CORE_i : TPU_CORE
generic map(
    MATRIX_WIDTH => 4
)
port map(
    CLK => CLK,
    RESET => RESET,
    ENABLE => ENABLE,
    
    matrix_start => matrix_start, 
    input_matrix_width  => input_matrix_width, --<= x"00000008";          
    input_matrix_height  => input_matrix_height, --<= x"00000008"; 
      
    weight_matrix_width  => weight_matrix_width, --<= x"00000008";     
    weight_matrix_height => weight_matrix_height, --<= x"00000008"; 
    ACTIVATION_FUNCTION_AS_TYPE => ACTIVATION_FUNCTION_AS_TYPE,
    finish_one_layer => finish_one_layer, 
    
    
    WEIGHT_WRITE_PORT => WEIGHT_WRITE_PORT_ARRAY,
    WEIGHT_ADDRESS => WEIGHT_ADDRESS,
    WEIGHT_ENABLE => WEIGHT_ENABLE,
    WEIGHT_WRITE_ENABLE =>  WEIGHT_WRITE_ENABLE,
    
    BUFFER_WRITE_PORT => BUFFER_WRITE_PORT_ARRAY,
    BUFFER_READ_PORT => BUFFER_READ_PORT_ARRAY, 
    BUFFER_ADDRESS => BUFFER_ADDRESS,
    BUFFER_ENABLE => BUFFER_ENABLE,
    BUFFER_WRITE_ENABLE => BUFFER_WRITE_ENABLE
);
BUFFER_READ_PORT <= BYTE_ARRAY_TO_BITS(BUFFER_READ_PORT_ARRAY);

end Behavioral;
