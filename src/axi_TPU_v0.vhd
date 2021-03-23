use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity axi_TPU_v0 is
GENERIC (
    -- width of s_axi data bus
    C_S_AXI_DATA_WIDTH : INTEGER := 32;
    -- width of s_axi address bus
    C_S_AXI_ADDR_WIDTH : INTEGER := 5
    );
  Port ( 
  
  sel : in std_logic; -- To select which read_port, read_enable and read_address 
  buffer_read_port : out std_logic_vector(31 downto 0); 
  buffer_read_enable : in std_logic; 
  buffer_read_address : in std_logic_vector(12-1 downto 0);
  finish_one_layer : out std_logic;
  
  input_matrix_width_out  : out std_logic_vector(31 downto 0); --<= x"00000008";          
  input_matrix_height_out  : out std_logic_vector(31 downto 0); --<= x"00000008"; 
    
  weight_matrix_width_out  : out std_logic_vector(31 downto 0); --<= x"00000008";     
  weight_matrix_height_out : out std_logic_vector(31 downto 0); --<= x"00000008"; 
  
  -- Do not modify the port beyond this line
  -- Global Clock Signal
  S_AXI_ACLK : IN std_logic;
  -- Global Reset Signal. This Signal is Active LOW
  S_AXI_ARESETN : IN std_logic;
  -- Write address (issued by master; acceped by Slave)
  S_AXI_AWADDR : IN std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
  -- Write channel Protection type. This signal indicates the
  -- privilege and security level of the transaction; and whether
  -- the transaction is a data access or an instruction access.
  S_AXI_AWPROT : IN std_logic_vector(2 DOWNTO 0);
  -- Write address valid. This signal indicates that the master signaling
  -- valid write address and control information.
  S_AXI_AWVALID : IN std_logic;
  -- Write address ready. This signal indicates that the slave is ready
  -- to accept an address and associated control signals.
  S_AXI_AWREADY : OUT std_logic;
  -- Write data (issued by master; acceped by Slave)
  S_AXI_WDATA : IN std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  -- Write strobes. This signal indicates which byte lanes hold
  -- valid data. There is one write strobe bit for each eight
  -- bits of the write data bus. 
  S_AXI_WSTRB : IN std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 DOWNTO 0);
  -- Write valid. This signal indicates that valid write
  -- data and strobes are available.
  S_AXI_WVALID : IN std_logic;
  -- Write ready. This signal indicates that the slave
  -- can accept the write data.
  S_AXI_WREADY : OUT std_logic;
  -- Write response. This signal indicates the status
  -- of the write transaction.
  S_AXI_BRESP : OUT std_logic_vector(1 DOWNTO 0);
  -- Write response valid. This signal indicates that the channel
  -- is signaling a valid write response.
  S_AXI_BVALID : OUT std_logic;
  -- Response ready. This signal indicates that the master
  -- can accept a write response.
  S_AXI_BREADY : IN std_logic;
  -- Read address (issued by master; acceped by Slave)
  S_AXI_ARADDR : IN std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
  -- Protection type. This signal indicates the privilege
  -- and security level of the transaction; and whether the
  -- transaction is a data access or an instruction access.
  S_AXI_ARPROT : IN std_logic_vector(2 DOWNTO 0);
  -- Read address valid. This signal indicates that the channel
  -- is signaling valid read address and control information.
  S_AXI_ARVALID : IN std_logic;
  -- Read address ready. This signal indicates that the slave is
  -- ready to accept an address and associated control signals.
  S_AXI_ARREADY : OUT std_logic;
  -- Read data (issued by slave)
  S_AXI_RDATA : OUT std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  -- Read response. This signal indicates the status of the
  -- read transfer.
  S_AXI_RRESP : OUT std_logic_vector(1 DOWNTO 0);
  -- Read valid. This signal indicates that the channel is
  -- signaling the required read data.
  S_AXI_RVALID : OUT std_logic;
  -- Read ready. This signal indicates that the master can
  -- accept the read data and response information.
  S_AXI_RREADY : IN std_logic 
  
  );
end axi_TPU_v0;

architecture Behavioral of axi_TPU_v0 is
component TPU_v1_0_S_AXI IS
	GENERIC (
		-- width of s_axi data bus
		C_S_AXI_DATA_WIDTH : INTEGER := 32;
		-- width of s_axi address bus
		C_S_AXI_ADDR_WIDTH : INTEGER := 5
	);
	PORT (
		-- users ports add here
		enable : out std_logic; 
		
        weight_write_port : out std_logic_vector(32-1 downto 0);
        weight_address : out std_logic_vector(15-1 downto 0); 
        input_write_port : out std_logic_vector(32-1 downto 0);
        input_address : out std_logic_vector(12-1 downto 0); 
        
        weight_enable : out std_logic; 
        input_enable : out std_logic;
        
        weight_write_enable : out std_logic_vector(0 to 4-1); 
        input_write_enable : out std_logic_vector(0 to 4-1);  
        
        input_matrix_width  : out std_logic_vector(31 downto 0); --<= x"00000008";          
        input_matrix_height  : out std_logic_vector(31 downto 0); --<= x"00000008"; 
          
        weight_matrix_width  : out std_logic_vector(31 downto 0); --<= x"00000008";     
        weight_matrix_height : out std_logic_vector(31 downto 0); --<= x"00000008"; 
        
        matrix_start : out std_logic; -- need to set to be 0 in the reset
        activation_fcn : out std_logic_vector(3 downto 0); 
		-- users ports end

		-- Do not modify the port beyond this line
		-- Global Clock Signal
		S_AXI_ACLK : IN std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN : IN std_logic;
		-- Write address (issued by master; acceped by Slave)
		S_AXI_AWADDR : IN std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
		-- Write channel Protection type. This signal indicates the
		-- privilege and security level of the transaction; and whether
		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT : IN std_logic_vector(2 DOWNTO 0);
		-- Write address valid. This signal indicates that the master signaling
		-- valid write address and control information.
		S_AXI_AWVALID : IN std_logic;
		-- Write address ready. This signal indicates that the slave is ready
		-- to accept an address and associated control signals.
		S_AXI_AWREADY : OUT std_logic;
		-- Write data (issued by master; acceped by Slave)
		S_AXI_WDATA : IN std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
		-- Write strobes. This signal indicates which byte lanes hold
		-- valid data. There is one write strobe bit for each eight
		-- bits of the write data bus. 
		S_AXI_WSTRB : IN std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 DOWNTO 0);
		-- Write valid. This signal indicates that valid write
		-- data and strobes are available.
		S_AXI_WVALID : IN std_logic;
		-- Write ready. This signal indicates that the slave
		-- can accept the write data.
		S_AXI_WREADY : OUT std_logic;
		-- Write response. This signal indicates the status
		-- of the write transaction.
		S_AXI_BRESP : OUT std_logic_vector(1 DOWNTO 0);
		-- Write response valid. This signal indicates that the channel
		-- is signaling a valid write response.
		S_AXI_BVALID : OUT std_logic;
		-- Response ready. This signal indicates that the master
		-- can accept a write response.
		S_AXI_BREADY : IN std_logic;
		-- Read address (issued by master; acceped by Slave)
		S_AXI_ARADDR : IN std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
		-- Protection type. This signal indicates the privilege
		-- and security level of the transaction; and whether the
		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT : IN std_logic_vector(2 DOWNTO 0);
		-- Read address valid. This signal indicates that the channel
		-- is signaling valid read address and control information.
		S_AXI_ARVALID : IN std_logic;
		-- Read address ready. This signal indicates that the slave is
		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY : OUT std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA : OUT std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
		-- Read response. This signal indicates the status of the
		-- read transfer.
		S_AXI_RRESP : OUT std_logic_vector(1 DOWNTO 0);
		-- Read valid. This signal indicates that the channel is
		-- signaling the required read data.
		S_AXI_RVALID : OUT std_logic;
		-- Read ready. This signal indicates that the master can
		-- accept the read data and response information.
		S_AXI_RREADY : IN std_logic 
	);
END component;

component TPU_CORE_top is
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
end component;

-- AXI Donot modified this 
--signal S_AXI_ACLK : std_logic;
--signal S_AXI_ARESETN :  std_logic;
--signal S_AXI_AWADDR : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
--signal S_AXI_AWPROT : std_logic_vector(2 DOWNTO 0);
--signal S_AXI_AWVALID : std_logic;
--signal S_AXI_AWREADY : std_logic;
--signal S_AXI_WDATA :  std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
--signal S_AXI_WSTRB :  std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 DOWNTO 0);
--signal S_AXI_WVALID :  std_logic;
--signal S_AXI_WREADY : std_logic;
--signal S_AXI_BRESP :  std_logic_vector(1 DOWNTO 0);
--signal S_AXI_BVALID : std_logic;
--signal S_AXI_BREADY :  std_logic;
--signal S_AXI_ARADDR : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
--signal S_AXI_ARPROT :  std_logic_vector(2 DOWNTO 0);
--signal S_AXI_ARVALID :  std_logic;
--signal S_AXI_ARREADY :  std_logic;
--signal S_AXI_RDATA :  std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
--signal S_AXI_RRESP : std_logic_vector(1 DOWNTO 0);
--signal S_AXI_RVALID :  std_logic;
--signal S_AXI_RREADY :  std_logic 
signal weight_write_port : std_logic_vector(32-1 downto 0);
signal weight_address : std_logic_vector(15-1 downto 0); 
signal input_write_port : std_logic_vector(32-1 downto 0);
signal input_address : std_logic_vector(12-1 downto 0); 

signal weight_enable : std_logic; 
signal input_enable : std_logic;

signal weight_write_enable : std_logic_vector(0 to 4-1); 
signal input_write_enable : std_logic_vector(0 to 4-1);  

--signal buffer_enable : std_logic_vector( 0 to 4-1); 


signal input_matrix_width  : std_logic_vector(31 downto 0); --<= x"00000008";          
signal input_matrix_height  :  std_logic_vector(31 downto 0); --<= x"00000008"; 
  
signal weight_matrix_width  : std_logic_vector(31 downto 0); --<= x"00000008";     
signal weight_matrix_height : std_logic_vector(31 downto 0); --<= x"00000008"; 

signal matrix_start : std_logic; 
signal enable : std_logic; 
signal ACTIVATION_FUNCTION : std_logic_vector(3 downto 0); 

signal buffer_read_port_array : std_logic_vector(31 downto 0);
signal buffer_address, input_read_address : std_logic_vector(12-1 downto 0);
signal buffer_enable : std_logic; 

signal not_reset : std_logic; 
signal activation_fcn : std_logic_vector(3 downto 0); 

begin

input_matrix_width_out  <=  input_matrix_width;     
input_matrix_height_out  <= input_matrix_height;
  
weight_matrix_width_out  <= weight_matrix_width;
weight_matrix_height_out <= weight_matrix_height;
ACTIVATION_FUNCTION <= "0001"; -- Unused

axi_tpu: TPU_v1_0_S_AXI 
	GENERIC map (
		-- width of s_axi data bus
		C_S_AXI_DATA_WIDTH => 32,
		-- width of s_axi address bus
		C_S_AXI_ADDR_WIDTH => 5
	)
	port map (
		-- users ports add here
		enable => enable, 
		
        weight_write_port => weight_write_port,-- out std_logic_vector(32-1 downto 0);
        weight_address => weight_address,-- out std_logic_vector(15-1 downto 0); 
        input_write_port => input_write_port,-- out std_logic_vector(32-1 downto 0);
        input_address => input_address,-- out std_logic_vector(12-1 downto 0); 
        
        weight_enable => weight_enable,-- out std_logic; 
        input_enable => input_enable,-- out std_logic;
        
        weight_write_enable => weight_write_enable,-- out std_logic_vector(0 to 4-1); 
        input_write_enable => input_write_enable, -- out std_logic_vector(0 to 4-1);  
        
        input_matrix_width  => input_matrix_width,-- out std_logic_vector(31 downto 0); --<= x"00000008";          
        input_matrix_height  => input_matrix_height,-- out std_logic_vector(31 downto 0); --<= x"00000008"; 
          
        weight_matrix_width  => weight_matrix_width,-- out std_logic_vector(31 downto 0); --<= x"00000008";     
        weight_matrix_height => weight_matrix_height, -- out std_logic_vector(31 downto 0); --<= x"00000008"; 
        
        matrix_start => matrix_start,-- out std_logic; -- need to set to be 0 in the reset
        activation_fcn => activation_fcn, 
		-- users ports end

		-- Do not modify the port beyond this line
		-- Global Clock Signal
		S_AXI_ACLK => S_AXI_ACLK, -- IN std_logic;
		S_AXI_ARESETN => S_AXI_ARESETN,-- IN std_logic;
		S_AXI_AWADDR => S_AXI_AWADDR,-- IN std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
		S_AXI_AWPROT => S_AXI_AWPROT,-- IN std_logic_vector(2 DOWNTO 0);
		S_AXI_AWVALID => S_AXI_AWVALID,-- IN std_logic;
		S_AXI_AWREADY => S_AXI_AWREADY,-- OUT std_logic;
		S_AXI_WDATA => S_AXI_WDATA,-- IN std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
		S_AXI_WSTRB => S_AXI_WSTRB,-- IN std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 DOWNTO 0);
		S_AXI_WVALID => S_AXI_WVALID,-- IN std_logic;
		S_AXI_WREADY => S_AXI_WREADY, -- OUT std_logic;
		S_AXI_BRESP => S_AXI_BRESP,-- OUT std_logic_vector(1 DOWNTO 0);
		S_AXI_BVALID => S_AXI_BVALID,-- OUT std_logic;
		S_AXI_BREADY => S_AXI_BREADY,-- IN std_logic;
		S_AXI_ARADDR => S_AXI_ARADDR,-- IN std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
		S_AXI_ARPROT => S_AXI_ARPROT,-- IN std_logic_vector(2 DOWNTO 0);
		S_AXI_ARVALID => S_AXI_ARVALID,-- IN std_logic;
		S_AXI_ARREADY => S_AXI_ARREADY,-- OUT std_logic;
		S_AXI_RDATA => S_AXI_RDATA,-- OUT std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
		S_AXI_RRESP => S_AXI_RRESP, -- OUT std_logic_vector(1 DOWNTO 0);
		S_AXI_RVALID => S_AXI_RVALID, -- OUT std_logic;
		S_AXI_RREADY => S_AXI_RREADY-- IN std_logic 
);

buffer_enable <= input_enable when sel = '0' else buffer_read_enable; 

buffer_address <= input_address when sel = '0' else buffer_read_address; 

not_reset <= NOT S_AXI_ARESETN; 

tpu_core:  TPU_CORE_top 
Port map ( 
        CLK => S_AXI_ACLK,--
        RESET => not_reset,-- in  std_logic;
        ENABLE  => enable,          
            
        matrix_start        => matrix_start,-- in std_logic; 
        input_matrix_width  => input_matrix_width,-- in std_logic_vector(31 downto 0); --<= x"00000008";          
        input_matrix_height  => input_matrix_height,-- in std_logic_vector(31 downto 0); --<= x"00000008"; 
          
        weight_matrix_width  => weight_matrix_width,-- in std_logic_vector(31 downto 0); --<= x"00000008";     
        weight_matrix_height => weight_matrix_height,-- in std_logic_vector(31 downto 0); --<= x"00000008"; 
        ACTIVATION_FUNCTION => activation_fcn,-- in std_logic_vector(3 downto 0);
        finish_one_layer => finish_one_layer, 
        
    
        WEIGHT_WRITE_PORT   => weight_write_port,-- in  std_logic_vector(31 downto 0); --!< Host write port for the weight buffer
        WEIGHT_ADDRESS      => weight_address, -- in  std_logic_vector(15-1 downto 0); --!< Host address for the weight buffer.
        WEIGHT_ENABLE       => weight_enable, -- in  std_logic; --!< Host enable for the weight buffer.
        WEIGHT_WRITE_ENABLE => weight_write_enable, -- in  std_logic_vector(0 to 4-1); --!< Host write enable for the weight buffer.
        
        BUFFER_WRITE_PORT   => input_write_port, -- in  std_logic_vector(31 downto 0); --!< Host write port for the unified buffer.
        BUFFER_READ_PORT    => buffer_read_port_array,-- out std_logic_vector(31 downto 0); --!< Host read port for the unified buffer.
        BUFFER_ADDRESS      => buffer_address,-- in  std_logic_vector(12-1 downto 0); --!< Host address for the unified buffer.
        BUFFER_ENABLE       => buffer_enable,-- in  std_logic; --!< Host enable for the unified buffer.
        BUFFER_WRITE_ENABLE => input_write_enable-- in  std_logic_vector(0 to 4-1) --!< Host write enable for the unified buffer.
);

buffer_read_port <= buffer_read_port_array;

end Behavioral;
