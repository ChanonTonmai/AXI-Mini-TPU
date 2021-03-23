LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY TPU_v1_0_S_AXI IS
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
        
        activation_fcn : out std_logic_Vector(3 downto 0 ); 
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
END TPU_v1_0_S_AXI;

ARCHITECTURE beh OF TPU_v1_0_S_AXI IS

	-- AXI4LITE signals
	SIGNAL axi_awaddr : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
	SIGNAL axi_awready : std_logic;
	SIGNAL axi_wready : std_logic;
	SIGNAL axi_bresp : std_logic_vector(1 DOWNTO 0);
	SIGNAL axi_bvalid : std_logic;
	SIGNAL axi_araddr : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
	SIGNAL axi_arready : std_logic;
	SIGNAL axi_rdata : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL axi_rresp : std_logic_vector(1 DOWNTO 0);
	SIGNAL axi_rvalid : std_logic;
	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	CONSTANT ADDR_LSB : INTEGER := 2;
	CONSTANT OPT_MEM_ADDR_BITS : INTEGER := 2;

	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers
	SIGNAL slv_reg0 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg1 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg2 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg3 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg4 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg5 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg6 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg7 : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL slv_reg_rden : std_logic;
	SIGNAL slv_reg_wren : std_logic;
	SIGNAL reg_data_out : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL byte_index : INTEGER RANGE 0 TO 5;
	SIGNAL asynchFIFO_AlmostFullR : std_logic;

	SIGNAL r0_input : std_logic;
	SIGNAL r1_input : std_logic;

	SIGNAL r2_input : std_logic;
	SIGNAL r3_input : std_logic;
	
	signal start : std_logic;
	
	signal reg1 :std_logic;
    signal reg2 :std_logic;

BEGIN
	-- I/O Connections assignments
	S_AXI_AWREADY <= axi_awready;
	S_AXI_WREADY <= axi_wready;
	S_AXI_BRESP <= axi_bresp;
	S_AXI_BVALID <= axi_bvalid;
	S_AXI_ARREADY <= axi_arready;
	S_AXI_RDATA <= axi_rdata;
	S_AXI_RRESP <= axi_rresp;
	S_AXI_RVALID <= axi_rvalid;

	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	PROCESS (S_AXI_ACLK)
	BEGIN
		IF rising_edge(S_AXI_ACLK) THEN
			IF S_AXI_ARESETN = '0' THEN
				axi_awready <= '0';
			ELSE
				IF ((NOT axi_awready) AND S_AXI_AWVALID AND S_AXI_WVALID) = '1' THEN
					-- slave is ready to accept write address when
					-- there is a valid write address and write data
					-- on the write address and data bus. This design
					-- expects no outstanding transactions.
					axi_awready <= '1';
				ELSE
					axi_awready <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;
	-- Implement axi_awaddr latching
    -- This process is used to latch the address when both
    -- S_AXI_AWVALID and S_AXI_WVALID are valid.
    PROCESS (S_AXI_ACLK)
    BEGIN
        IF rising_edge(S_AXI_ACLK) THEN
            IF S_AXI_ARESETN = '0' THEN
                axi_awaddr <= (OTHERS => '0');
            ELSE
                IF ((NOT axi_awready) AND S_AXI_AWVALID AND S_AXI_WVALID) = '1' THEN
                    -- Write Address latching
                    axi_awaddr <= S_AXI_AWADDR;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- Implement axi_wready generation
    -- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
    -- de-asserted when reset is low.
    
    PROCESS (S_AXI_ACLK)
    BEGIN
        IF rising_edge(S_AXI_ACLK) THEN
            IF S_AXI_ARESETN = '0' THEN
                axi_wready <= '0';
            ELSE
                IF ((NOT axi_awready) AND S_AXI_AWVALID AND S_AXI_WVALID) = '1' THEN
                    -- slave is ready to accept write data when
                    -- there is a valid write address and write data
                    -- on the write address and data bus. This design
                    -- expects no outstanding transactions.
                    axi_wready <= '1';
                ELSE
                    axi_wready <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    -- Implement memory mapped register select and write logic generation
    -- The write data is accepted and written to memory mapped registers when
    -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    -- select byte enables of slave registers while writing.
    -- These registers are cleared when reset (active low) is applied.
    -- Slave register write enable is asserted when valid address and data are available
    -- and the slave is ready to accept the write address and write data.
    slv_reg_wren <= axi_wready AND S_AXI_WVALID AND axi_awready AND S_AXI_AWVALID;
    
    PROCESS (S_AXI_ACLK)
        BEGIN
            IF rising_edge(S_AXI_ACLK) THEN
                IF S_AXI_ARESETN = '0' THEN
                    slv_reg0 <= (OTHERS => '0');
                    slv_reg1 <= (OTHERS => '0');
                    slv_reg2 <= (OTHERS => '0');
                    slv_reg3 <= (OTHERS => '0');
                    slv_reg4 <= (OTHERS => '0');
                    slv_reg5 <= (OTHERS => '0');
                    slv_reg6 <= (OTHERS => '0');
                    slv_reg7 <= (OTHERS => '0');
                ELSE
                    IF (slv_reg_wren) = '1' THEN
                        CASE axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS DOWNTO ADDR_LSB) IS
                            WHEN "000" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg0((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "001" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg1((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "010" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg2((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "011" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg3((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "100" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg4((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "101" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg5((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "110" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg6((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
                            WHEN "111" => 
                                FOR byte_index IN 0 TO (C_S_AXI_DATA_WIDTH/8) - 1 LOOP
                                    IF (S_AXI_WSTRB(byte_index) = '1') THEN
                                        slv_reg7((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8) <= 
                                            S_AXI_WDATA((byte_index + 1) * 8 - 1 DOWNTO byte_index * 8);
                                    END IF;
                                END LOOP;
    
                            WHEN OTHERS => 
                                slv_reg0 <= slv_reg0;
                                slv_reg1 <= slv_reg1;
                                slv_reg2 <= slv_reg2;
                                slv_reg3 <= slv_reg3;
                                slv_reg4 <= slv_reg4;
                                slv_reg5 <= slv_reg5;
                                slv_reg6 <= slv_reg6;
                                slv_reg7 <= slv_reg7;
                        END CASE;
                    END IF;
                END IF;
            END IF;
        END PROCESS;
        -- Implement write response logic generation
        -- The write response and response valid signals are asserted by the slave
        -- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
        -- This marks the acceptance of address and indicates the status of
        -- write transaction.
        PROCESS (S_AXI_ACLK)
            BEGIN
                IF rising_edge(S_AXI_ACLK) THEN
                    IF S_AXI_ARESETN = '0' THEN
                        axi_bvalid <= '0';
                        axi_bresp <= (OTHERS => '0');
                    ELSE
                        IF ((NOT axi_bvalid) AND S_AXI_AWVALID AND axi_awready AND axi_wready AND S_AXI_WVALID) = '1' THEN
                            axi_bvalid <= '1';
                            axi_bresp <= (OTHERS => '0');
                        ELSE
                            IF (S_AXI_BREADY AND axi_bvalid) = '1' THEN
                                --check if bready is asserted while bvalid is high)
                                --(there is a possibility that bready is always asserted high)
                                axi_bvalid <= '0';
                            END IF;
                        END IF;
                    END IF;
                END IF;
    END PROCESS;

    -- Implement axi_arready generation
    -- axi_arready is asserted for one S_AXI_ACLK clock cycle when
    -- S_AXI_ARVALID is asserted. axi_awready is
    -- de-asserted when reset (active low) is asserted.
    -- The read address is also latched when S_AXI_ARVALID is
    -- asserted. axi_araddr is reset to zero on reset assertion.

    PROCESS (S_AXI_ACLK)
        BEGIN
            IF rising_edge(S_AXI_ACLK) THEN
                IF S_AXI_ARESETN = '0' THEN
                    axi_arready <= '0';
                    axi_araddr <= (OTHERS => '0');
                ELSE
                    IF ((NOT axi_arready) AND S_AXI_ARVALID) = '1' THEN
                        axi_arready <= '1';
                        axi_araddr <= S_AXI_ARADDR;
                    ELSE
                        axi_arready <= '0';
                    END IF;
                END IF;
            END IF;
    END PROCESS;

    -- Implement axi_arvalid generation
    -- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    -- S_AXI_ARVALID and axi_arready are asserted. The slave registers
    -- data are available on the axi_rdata bus at this instance. The
    -- assertion of axi_rvalid marks the validity of read data on the
    -- bus and axi_rresp indicates the status of read transaction.axi_rvalid
    -- is deasserted on reset (active low). axi_rresp and axi_rdata are
    -- cleared to zero on reset (active low).
    PROCESS (S_AXI_ACLK)
        BEGIN
            IF rising_edge(S_AXI_ACLK) THEN
                IF S_AXI_ARESETN = '0' THEN
                    axi_rvalid <= '0';
                    axi_rresp <= "00";
                ELSE
                    IF ((NOT axi_rvalid) AND S_AXI_ARVALID AND axi_arready) = '1' THEN
                        axi_rvalid <= '1';
                        axi_rresp <= "00";
                    ELSIF (axi_rvalid AND S_AXI_RREADY) = '1' THEN
                        axi_rvalid <= '0';
                    END IF;
                END IF;
            END IF;
    END PROCESS;
        -- Implement memory mapped register select and read logic generation
        -- Slave register read enable is asserted when valid address is available
        -- and the slave is ready to accept the read address.

    slv_reg_rden <= axi_arready AND S_AXI_ARVALID AND (NOT axi_rvalid);

    PROCESS (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr) IS
        BEGIN
            CASE (axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS DOWNTO ADDR_LSB)) IS
                WHEN "000" => reg_data_out <= slv_reg0; -- control sequence | BUFFER_ENABLE | WEIGHT_ENABLE | en |
                WHEN "001" => reg_data_out <= slv_reg1; -- |up or low|<- Addr(15) ->|<- D1(8) ->|<- D0(8) ->| for Weight 
                WHEN "010" => reg_data_out <= slv_reg2; -- |up or low|<- Addr(14) ->|<- D1(8) ->|<- D0(8) ->| for Input
                WHEN "011" => reg_data_out <= slv_reg3; -- matrix size
                WHEN "100" => reg_data_out <= x"DEADBEAF"; -- unused
                WHEN "101" => reg_data_out <= x"DEADBEAF"; -- unused
                WHEN "110" => reg_data_out <= x"DEADBEAF"; -- unused
                WHEN "111" => reg_data_out <= x"DEADBEAF"; -- unused
                WHEN OTHERS => reg_data_out <= (OTHERS => '0');
            END CASE;
    END PROCESS;

            -- Output register or memory read data
    PROCESS (S_AXI_ACLK)
        BEGIN
            IF rising_edge(S_AXI_ACLK) THEN
                IF S_AXI_ARESETN = '0' THEN
                    axi_rdata <= (OTHERS => '0');
                ELSE
                    IF (slv_reg_rden) = '1' THEN
                        axi_rdata <= reg_data_out;
                    END IF;
                END IF;
            END IF;
        END PROCESS;

    -- Add user logic here
    enable <= slv_reg0(0);
    
--    weight_write_port <= slv_reg1(31 downto 0); 
    process(S_AXI_ACLK, S_AXI_ARESETN) is begin
        if S_AXI_ARESETN = '0' then 
            weight_write_port <= (others=>'0');
        elsif rising_edge(S_AXI_ACLK) then
            if slv_reg1(31) = '1' then -- low 
                weight_write_port(15 downto 0) <= slv_reg1(15 downto 0);
            else 
                weight_write_port(31 downto 16) <= slv_reg1(15 downto 0);
            end if; 
        end if ;
    end process;   
     

    weight_address <= slv_reg1(30 downto 16);
    weight_enable <= slv_reg0(1); -- need to tick down
    weight_write_enable <= "1111" when slv_reg0(1) = '1' else "0000";
    
    activation_fcn <= slv_reg0(7 downto 4);
--    input_write_port <= slv_reg2(31 downto 0); 
    process(S_AXI_ACLK, S_AXI_ARESETN) is begin
        if S_AXI_ARESETN = '0' then 
            input_write_port <= (others=>'0');
        elsif rising_edge(S_AXI_ACLK) then
            if slv_reg2(31) = '1' then -- low 
                input_write_port(15 downto 0) <= slv_reg2(15 downto 0);
            else 
                input_write_port(31 downto 16) <= slv_reg2(15 downto 0);
            end if; 
        end if ;
    end process;    
    input_address <= slv_reg2(27 downto 16);
    input_enable <= slv_reg0(2); -- need to tick down
    input_write_enable <= "1111" when slv_reg0(2) = '1' else "0000";
    
    input_matrix_width <= x"000000" & slv_reg3(31 downto 24);
    input_matrix_height <= x"000000" & slv_reg3(23 downto 16);
    weight_matrix_width <= x"000000" & slv_reg3(15 downto 8);
    weight_matrix_height <= x"000000" & slv_reg3(7 downto 0);
    
    start <= slv_reg0(3); -- need to edge detect; 
    process(S_AXI_ACLK, S_AXI_ARESETN) is begin
        if S_AXI_ARESETN = '0' then 
            reg1 <= '0';
            reg2 <= '0';
        elsif rising_edge(S_AXI_ACLK) then
            reg1 <= start; 
            reg2 <= reg1; 
         end if; 
     end process; 
    matrix_start <= reg1 and (not reg2); 
    -- end user logic
END beh;