use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TPU_CORE is
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
end entity TPU_CORE;


architecture Behavioral of TPU_CORE is
component WEIGHT_BUFFER is
        generic(
            MATRIX_WIDTH    : natural := 14;
            -- How many tiles can be saved
            TILE_WIDTH      : natural := 32768
        );
        port(
            CLK, RESET      : in  std_logic;
            ENABLE          : in  std_logic;
            
            -- Port0
            ADDRESS0        : in  WEIGHT_ADDRESS_TYPE;
            EN0             : in  std_logic;
            WRITE_EN0       : in  std_logic;
            WRITE_PORT0     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            READ_PORT0      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            -- Port1
            ADDRESS1        : in  WEIGHT_ADDRESS_TYPE;
            EN1             : in  std_logic;
            WRITE_EN1       : in  std_logic_vector(0 to MATRIX_WIDTH-1);
            WRITE_PORT1     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            READ_PORT1      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
        );
    end component WEIGHT_BUFFER;
    for all : WEIGHT_BUFFER use entity WORK.WEIGHT_BUFFER(BEH);
    
   signal WEIGHT_ADDRESS0      : WEIGHT_ADDRESS_TYPE;
   signal WEIGHT_EN0           : std_logic;
   signal WEIGHT_READ_PORT0    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
       
   component UNIFIED_BUFFER is
       generic(
           MATRIX_WIDTH    : natural := 14;
           -- How many tiles can be saved
           TILE_WIDTH      : natural := 4096
       );
       port(
           CLK, RESET      : in  std_logic;
           ENABLE          : in  std_logic;
           
           -- Master port - overrides other ports
           MASTER_ADDRESS      : in  BUFFER_ADDRESS_TYPE;
           MASTER_EN           : in  std_logic;
           MASTER_WRITE_EN     : in  std_logic_vector(0 to MATRIX_WIDTH-1);
           MASTER_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           MASTER_READ_PORT    : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           -- Port0
           ADDRESS0        : in  BUFFER_ADDRESS_TYPE;
           EN0             : in  std_logic;
           READ_PORT0      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           -- Port1
           ADDRESS1        : in  BUFFER_ADDRESS_TYPE;
           EN1             : in  std_logic;
           WRITE_EN1       : in  std_logic;
           WRITE_PORT1     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
       );
   end component UNIFIED_BUFFER;
   for all : UNIFIED_BUFFER use entity WORK.UNIFIED_BUFFER(BEH);
   
      component UNIFIED_BUFFER_2 is
       generic(
           MATRIX_WIDTH    : natural := 14;
           -- How many tiles can be saved
           TILE_WIDTH      : natural := 4096
       );
       port(
           CLK, RESET      : in  std_logic;
           ENABLE          : in  std_logic;
           
           -- Master port - overrides other ports
           MASTER_ADDRESS      : in  BUFFER_ADDRESS_TYPE;
           MASTER_EN           : in  std_logic;
           MASTER_WRITE_EN     : in  std_logic_vector(0 to MATRIX_WIDTH-1);
           MASTER_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           MASTER_READ_PORT    : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           -- Port0
           ADDRESS0        : in  BUFFER_ADDRESS_TYPE;
           EN0             : in  std_logic;
           READ_PORT0      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           -- Port1
           ADDRESS1        : in  BUFFER_ADDRESS_TYPE;
           EN1             : in  std_logic;
           WRITE_EN1       : in  std_logic;
           WRITE_PORT1     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
       );
   end component UNIFIED_BUFFER_2;
   
   
   signal BUFFER_ADDRESS0      : BUFFER_ADDRESS_TYPE;
   signal BUFFER_EN0           : std_logic;
   signal BUFFER_READ_PORT0    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   signal BUFFER_ADDRESS1      : BUFFER_ADDRESS_TYPE;
   signal BUFFER_WRITE_EN1     : std_logic;
   signal BUFFER_WRITE_PORT1   : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   signal ACTIVATION_ADDRESS0      : BUFFER_ADDRESS_TYPE;
   signal ACTIVATION_EN0           : std_logic;
   signal ACTIVATION_READ_PORT0    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   signal ACTIVATION_ADDRESS1      : BUFFER_ADDRESS_TYPE;
   signal ACTIVATION_WRITE_EN1     : std_logic;
   signal ACTIVATION_WRITE_PORT1   : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   
   component SYSTOLIC_DATA_SETUP is
       generic(
           MATRIX_WIDTH  : natural := 14
       );
       port(
           CLK, RESET      : in  std_logic;
           ENABLE          : in  std_logic;
           DATA_INPUT      : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           SYSTOLIC_OUTPUT : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
       );
   end component SYSTOLIC_DATA_SETUP;
   for all : SYSTOLIC_DATA_SETUP use entity WORK.SYSTOLIC_DATA_SETUP(BEH);
   
   signal SDS_SYSTOLIC_OUTPUT  : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   component MATRIX_MULTIPLY_UNIT is
       generic(
           MATRIX_WIDTH    : natural := 14
       );
       port(
           CLK, RESET      : in  std_logic;
           ENABLE          : in  std_logic;
           
           WEIGHT_DATA     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           WEIGHT_SIGNED   : in  std_logic;
           SYSTOLIC_DATA   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           SYSTOLIC_SIGNED : in  std_logic;
           
           ACTIVATE_WEIGHT : in  std_logic; -- Activates the loaded weights sequentially
           LOAD_WEIGHT     : in  std_logic; -- Preloads one column of weights with WEIGHT_DATA
           WEIGHT_ADDRESS  : in  BYTE_TYPE; -- Addresses up to 256 columns of preweights
           
           RESULT_DATA     : out WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
       );
   end component MATRIX_MULTIPLY_UNIT;
   for all : MATRIX_MULTIPLY_UNIT use entity WORK.MATRIX_MULTIPLY_UNIT(BEH);
   
   signal MMU_WEIGHT_SIGNED    : std_logic;
   signal MMU_SYSTOLIC_SIGNED  : std_logic;
   
   signal MMU_ACTIVATE_WEIGHT  : std_logic;
   signal MMU_LOAD_WEIGHT      : std_logic;
   signal MMU_WEIGHT_ADDRESS   : BYTE_TYPE;
   
   signal MMU_RESULT_DATA      : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   component ACTIVATION is
       generic(
           MATRIX_WIDTH        : natural := 14
       );
       port(
           CLK, RESET          : in  std_logic;
           ENABLE              : in  std_logic;
           
           ACTIVATION_FUNCTION : in  ACTIVATION_BIT_TYPE;
           SIGNED_NOT_UNSIGNED : in  std_logic;
           
           ACTIVATION_INPUT    : in  WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           ACTIVATION_OUTPUT   : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
       );
   end component ACTIVATION;
   for all : ACTIVATION use entity WORK.ACTIVATION(BEH);
   
   signal ACTIVATION_SIGNED    : std_logic;
    
   component unified_buffer_ctrl is
       Port ( clk, reset : in STD_LOGIC;
              enable : in STD_LOGIC;
              start : in STD_LOGIC;
              
              base_addr : in BUFFER_ADDRESS_TYPE;
              addr : out BUFFER_ADDRESS_TYPE;
              en0 : out std_logic; 
              load_finish : out std_logic; 
              
              load_weight : out STD_LOGIC;
              weight_addr : out BYTE_TYPE);
   end component;
   
   
   component weight_ctrl is
       Port ( clk, reset : in STD_LOGIC;
              enable : in STD_LOGIC;
              start : in STD_LOGIC;
              en0 : out std_logic;
              base_addr : in WEIGHT_ADDRESS_TYPE;
              addr : out WEIGHT_ADDRESS_TYPE;
              valid : out std_logic;
              activate_weight : out STD_LOGIC);
   end component;
   
   
   component matrix_add is
       generic (
           MATRIX_WIDTH            : natural := 4 --!< The width of the Matrix Multiply Unit and busses.
       ); 
     Port ( clk, reset : in STD_LOGIC;
            matrix_result : in WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            valid : in std_logic;
            matrix_for_activation : out WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            data_added_o : out std_logic; 
            unified_buffer_2_start : out std_logic; 
            matrix_width_for_compute : in WORD_TYPE 
     
     );
     end component; 

component unified_2_to_1_ctrl is
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
           matrix_width : in WORD_TYPE ); 
end component;


component master_matrix_ctrl is
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
end component;

signal START : std_logic; 
signal ACTIVATION_ADDRESS_2 : BUFFER_ADDRESS_TYPE; 
signal ACTIVATION_EN_2 : std_logic; 

signal WRITE_ADDRESS_2 : BUFFER_ADDRESS_TYPE; 
signal WRITE_EN_2 : std_logic; 

signal load_finish : std_logic; 
signal valid, data_added : std_logic; 
signal matrix_for_activation : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
--signal ACTIVATION_FUNCTION_AS_TYPE  : ACTIVATION_TYPE;
signal ACTIVATION_FUNCTION  : ACTIVATION_BIT_TYPE;

signal ACTIVATION_WRITE_PORT   :   BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the unified buffer.
signal ACTIVATION_READ_PORT    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host read port for the unified buffer.
signal ACTIVATION_ADDRESS      :  BUFFER_ADDRESS_TYPE; --!< Host address for the unified buffer.
signal ACTIVATION_ENABLE       :  std_logic; --!< Host enable for the unified buffer.
signal ACTIVATION_WRITE_ENABLE : std_logic_vector(0 to MATRIX_WIDTH-1); --!< Host write enable for the unified buffer.

signal unified_buffer_2_start : std_logic; 
--signal matrix_start : std_logic; 
signal matrix_base_addr : WORD_TYPE; 
--signal input_matrix_width : WORD_TYPE;
--signal input_matrix_height : WORD_TYPE;
--signal weight_matrix_width : WORD_TYPE;
--signal weight_matrix_height : WORD_TYPE;

signal    base_addr           :  BUFFER_ADDRESS_TYPE; 
signal    weight_base_addr    :  WEIGHT_ADDRESS_TYPE;
signal    base_addr_2         :  BUFFER_ADDRESS_TYPE; 

signal finish_one_layer_temp : std_logic;

begin

WEIGHT_BUFFER_i : WEIGHT_BUFFER
    generic map(
        MATRIX_WIDTH    => MATRIX_WIDTH,
        TILE_WIDTH      => WEIGHT_BUFFER_DEPTH
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,
        ENABLE          => ENABLE,
            
        -- Port0    
        ADDRESS0        => WEIGHT_ADDRESS0,
        EN0             => WEIGHT_EN0,
        WRITE_EN0       => '0',
        WRITE_PORT0     => (others => (others => '0')),
        READ_PORT0      => WEIGHT_READ_PORT0,
        -- Port1    
        ADDRESS1        => WEIGHT_ADDRESS,
        EN1             => WEIGHT_ENABLE,
        WRITE_EN1       => WEIGHT_WRITE_ENABLE,
        WRITE_PORT1     => WEIGHT_WRITE_PORT,
        READ_PORT1      => open
    );
    
    UNIFIED_BUFFER_i : UNIFIED_BUFFER
    generic map(
        MATRIX_WIDTH    => MATRIX_WIDTH,
        TILE_WIDTH      => UNIFIED_BUFFER_DEPTH
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,
        ENABLE          => ENABLE,
        
        -- Master port - overrides other ports
        MASTER_ADDRESS      => BUFFER_ADDRESS,
        MASTER_EN           => BUFFER_ENABLE,
        MASTER_WRITE_EN     => BUFFER_WRITE_ENABLE,
        MASTER_WRITE_PORT   => BUFFER_WRITE_PORT,
        MASTER_READ_PORT    => BUFFER_READ_PORT,
        -- Port0
        ADDRESS0        => BUFFER_ADDRESS0,
        EN0             => BUFFER_EN0,
        READ_PORT0      => BUFFER_READ_PORT0,
        -- Port1
        ADDRESS1        => WRITE_ADDRESS_2,
        EN1             => WRITE_EN_2, -- WRITE_EN_2
        WRITE_EN1       => WRITE_EN_2,
        WRITE_PORT1     => ACTIVATION_READ_PORT0 --
    );

    SYSTOLIC_DATA_SETUP_i : SYSTOLIC_DATA_SETUP
    generic map(
        MATRIX_WIDTH
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,      
        ENABLE          => ENABLE,
        DATA_INPUT      => WEIGHT_READ_PORT0,
        SYSTOLIC_OUTPUT => SDS_SYSTOLIC_OUTPUT 
    );
    
    MATRIX_MULTIPLY_UNIT_i : MATRIX_MULTIPLY_UNIT
    generic map(
        MATRIX_WIDTH   
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,
        ENABLE          => ENABLE,         
        
        WEIGHT_DATA     => BUFFER_READ_PORT0,
        WEIGHT_SIGNED   => MMU_WEIGHT_SIGNED,
        SYSTOLIC_DATA   => SDS_SYSTOLIC_OUTPUT,
        SYSTOLIC_SIGNED => MMU_SYSTOLIC_SIGNED,
        
        ACTIVATE_WEIGHT => MMU_ACTIVATE_WEIGHT,
        LOAD_WEIGHT     => MMU_LOAD_WEIGHT,
        WEIGHT_ADDRESS  => MMU_WEIGHT_ADDRESS,
        
        RESULT_DATA     => MMU_RESULT_DATA
    );
    
--    ACTIVATION_FUNCTION_AS_TYPE <= RELU;
    ACTIVATION_FUNCTION <= ACTIVATION_TO_BITS(ACTIVATION_FUNCTION_AS_TYPE);
    
    ACTIVATION_i : ACTIVATION
    generic map(
        MATRIX_WIDTH        => MATRIX_WIDTH
    )
    port map(
        CLK                 => CLK,
        RESET               => RESET,
        ENABLE              => ENABLE,      
        
        ACTIVATION_FUNCTION => ACTIVATION_FUNCTION,
        SIGNED_NOT_UNSIGNED => '0',
        
        ACTIVATION_INPUT    => matrix_for_activation,
        ACTIVATION_OUTPUT   => ACTIVATION_WRITE_PORT
    );


    UNIFIED_BUFFER_CTRL_i: unified_buffer_ctrl 
        Port map ( clk => CLK,
                   reset => RESET, 
                   enable => ENABLE, 
                   start => START,
               
                   base_addr => base_addr,
                   addr => BUFFER_ADDRESS0,
                   en0 => BUFFER_EN0,
               
                   load_finish => load_finish,
               
                   load_weight => MMU_LOAD_WEIGHT,
                   weight_addr => MMU_WEIGHT_ADDRESS
         );

   WEIGHT_CTRL_i : weight_ctrl
           Port map ( clk => CLK,
              reset => RESET, 
              enable => ENABLE, 
              start => load_finish,
              
              en0 => WEIGHT_EN0, 
              base_addr => weight_base_addr,
              addr => WEIGHT_ADDRESS0,
              valid => valid, 
              activate_weight => MMU_ACTIVATE_WEIGHT
              );
    
    
    MATRIX_ADD_i: matrix_add 
    generic map(
        MATRIX_WIDTH   
    )
    Port map 
         ( clk => CLK,
           reset => finish_one_layer_temp, 
           matrix_result => MMU_RESULT_DATA, 
           valid => valid,
           matrix_for_activation => matrix_for_activation,
           data_added_o => data_added,
           unified_buffer_2_start => unified_buffer_2_start,-- : out std_logic;  
           matrix_width_for_compute => input_matrix_width 
        );          

    UNIFIED_BUFFER_2_i : UNIFIED_BUFFER
        generic map(
            MATRIX_WIDTH    => MATRIX_WIDTH,
            TILE_WIDTH      => UNIFIED_BUFFER_DEPTH
        )
        port map(
            CLK             => CLK,
            RESET           => RESET,
            ENABLE          => ENABLE,
            
            -- Master port - overrides other ports
            MASTER_ADDRESS      => ACTIVATION_ADDRESS,
            MASTER_EN           => ACTIVATION_ENABLE,
            MASTER_WRITE_EN     => ACTIVATION_WRITE_ENABLE,
            MASTER_WRITE_PORT   => ACTIVATION_WRITE_PORT,
            MASTER_READ_PORT    => ACTIVATION_READ_PORT,
            -- Port0
            ADDRESS0        => ACTIVATION_ADDRESS_2,
            EN0             => ACTIVATION_EN_2,
            READ_PORT0      => ACTIVATION_READ_PORT0,
            -- Port1
            ADDRESS1        => ACTIVATION_ADDRESS1,
            EN1             => ACTIVATION_WRITE_EN1,
            WRITE_EN1       => ACTIVATION_WRITE_EN1,
            WRITE_PORT1     => ACTIVATION_WRITE_PORT1
        );
    ACTIVATION_WRITE_ENABLE <= "1111" when ACTIVATION_ENABLE='1' else "0000";   
    

    UNIFIED_BUFFER_CTRL_2_i: unified_buffer_ctrl 
            Port map ( clk => CLK,
                       reset => RESET, 
                       enable => ENABLE, 
                       start => unified_buffer_2_start,
                   
                       base_addr => base_addr_2,
                       addr => ACTIVATION_ADDRESS,
                       en0 => ACTIVATION_ENABLE,
                   
                       load_finish => open,
                   
                       load_weight => open,
                       weight_addr => open
             );
             
             
    UNIFIED_2_TO_1 :  unified_2_to_1_ctrl 
     Port map (  clk => CLK,
             reset => RESET, 
             enable => ENABLE, 
             
             unified_buffer_2_start => unified_buffer_2_start, 
             --unified_buffer_2_start : in STD_LOGIC;
            
            -- for unified buffer 2 => READ
            ACTIVATION_ADDRESS => ACTIVATION_ADDRESS_2, --: OUT BUFFER_ADDRESS_TYPE; 
            ACTIVATION_EN => ACTIVATION_EN_2, -- : OUT STD_LOGIC; 
            
            -- for unified buffer 1 => WRITE
            WRITE_ADDRESS => WRITE_ADDRESS_2, --: OUT BUFFER_ADDRESS_TYPE; 
            WRITE_EN => WRITE_EN_2, -- : OUT STD_LOGIC;
            finish_one_layer => finish_one_layer_temp,             
            matrix_height => input_matrix_height, 
            matrix_width => input_matrix_width -- : in BYTE_TYPE 
          ); 
finish_one_layer <= finish_one_layer_temp;            
      
              
MASTER_CTRL : master_matrix_ctrl 
  Port map(  clk => CLK,
             reset => RESET,
             matrix_start => matrix_start, -- : in std_logic; 
             matrix_base_addr => matrix_base_addr, -- : in WORD_TYPE; 
             input_matrix_width => input_matrix_width, -- : in WORD_TYPE;
             input_matrix_height => input_matrix_height, -- : in WORD_TYPE;
             weight_matrix_width => weight_matrix_width, -- : in WORD_TYPE;
             weight_matrix_height => weight_matrix_height, -- : in WORD_TYPE;
             start => START, -- : out STD_LOGIC;
             base_addr => base_addr, -- : out BUFFER_ADDRESS_TYPE;
             weight_base_addr => weight_base_addr, -- : out WEIGHT_ADDRESS_TYPE;
             base_addr_2 => base_addr_2 --: out BUFFER_ADDRESS_TYPE
);





end Behavioral;
