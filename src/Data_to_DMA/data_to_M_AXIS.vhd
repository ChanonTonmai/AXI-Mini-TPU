LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE IEEE.NUMERIC_STD.ALL;

ENTITY DP_to_DMA_M_AXIS IS
	GENERIC (

		--Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		C_M_AXIS_TDATA_WIDTH : INTEGER := 32;
		--Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.
		C_M_START_COUNT : INTEGER := 32
	);
	PORT (
		-- Users to add ports here
		--PacketSize : in std_logic_vector(31 downto 0);
		enable : IN std_logic; -- tell this block to start

		rd_address : OUT std_logic_vector(12 DOWNTO 0);
		rd_enable : out std_logic; 
		DP_Din : IN std_logic_vector(31 DOWNTO 0);
		
		
        input_matrix_height  : in std_logic_vector(31 DOWNTO 0); --<= x"00000008";          
        weight_matrix_width  : in std_logic_vector(31 DOWNTO 0); --<= x"00000008";     
       
		
		--User ports ends
		--Do not modify the ports beyond this line
 
		--Global ports
		M_AXIS_ACLK : IN std_logic;
		M_AXIS_ARESETN : IN std_logic;
		M_AXIS_TVALID : OUT std_logic;
		M_AXIS_TDATA : OUT std_logic_vector(C_M_AXIS_TDATA_WIDTH - 1 DOWNTO 0);
		M_AXIS_TSTRB : OUT std_logic_vector((C_M_AXIS_TDATA_WIDTH/8) - 1 DOWNTO 0);
		M_AXIS_TLAST : OUT std_logic;
		M_AXIS_TREADY : IN std_logic;
		M_AXIS_TKEEP : OUT std_logic_vector((C_M_AXIS_TDATA_WIDTH/8) - 1 DOWNTO 0);
		M_AXIS_TUSER : OUT std_logic
	);
END DP_to_DMA_M_AXIS;

ARCHITECTURE Behavioral OF DP_to_DMA_M_AXIS IS
    signal matrix_size : integer range 0 to 1023; 
	SIGNAL Clk : std_logic := '0';
	SIGNAL ResetL : std_logic := '0';

	SIGNAL enableSampleGenerationR : std_logic := '0';
	SIGNAL enableSampleGenerationD1 : std_logic := '0';
	SIGNAL enableSampleGenerationD2 : std_logic := '0';
	--signal enableSampleGenerationD3 : std_logic := '0';

	SIGNAL enableSampleGenerationPosEdge : std_logic := '0';
	SIGNAL enableSampleGenerationNegEdge : std_logic := '0';

	TYPE state IS (FSM_STATE_IDLE, FSM_STATE_ACTIVE, FSM_STATE_WAIT_END);
	SIGNAL fsm_currentState, fsm_prevState : state := FSM_STATE_IDLE;

	SIGNAL dataIsBeingTransferred : std_logic := '0';
	SIGNAL lastDataIsBeingTransferred : std_logic := '0'; 

	SIGNAL packetSizeInDwords : std_logic_vector(C_M_AXIS_TDATA_WIDTH - 1 - 2 DOWNTO 0) := (OTHERS => '0');
	SIGNAL validBytesInLastChunk : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0'); 

	SIGNAL addrCounter : std_logic_vector(13 - 1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL packetDWORDCounter : std_logic_vector(29 DOWNTO 0) := (OTHERS => '0');

	SIGNAL packetRate_Counter : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0'); 
	SIGNAL packetRate_allowData : std_logic := '0';

	SIGNAL sentPacketCounter : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');

	SIGNAL M_AXIS_TVALID_signal : std_logic := '0';
	SIGNAL M_AXIS_TSTRB_signal : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8) - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL M_AXIS_TLAST_signal : std_logic := '0';

	SIGNAL M_AXIS_TVALID_signal_delay1 : std_logic := '0';
	SIGNAL M_AXIS_TSTRB_signal_delay1 : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8) - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL M_AXIS_TLAST_signal_delay1 : std_logic := '0';

	SIGNAL M_AXIS_TVALID_signal_delay2 : std_logic := '0';
	SIGNAL M_AXIS_TSTRB_signal_delay2 : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8) - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL M_AXIS_TLAST_signal_delay2 : std_logic := '0';

	SIGNAL M_AXIS_TVALID_signal_delay3 : std_logic := '0';
	SIGNAL M_AXIS_TSTRB_signal_delay3 : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8) - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL M_AXIS_TLAST_signal_delay3 : std_logic := '0';

	SIGNAL a : std_logic_vector(59 DOWNTO 0) := (OTHERS => '0');

	SIGNAL PacketSize_signal : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL PacketRate : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL NumberOfPacketsToSend : std_logic_vector(31 DOWNTO 0) := x"00000001";
	SIGNAL PacketSize : std_logic_vector(31 DOWNTO 0);
	
	SIGNAL PacketSize_signal_addr : std_logic_vector(C_M_AXIS_TDATA_WIDTH - 1 - 2 DOWNTO 0) := (OTHERS => '0');
	
	signal en_delay, en_delay2, en_delay3, en_delay4, en_delay5 : std_logic;
BEGIN
	PacketSize <= x"00000800"; -- the quantity of data in byte : 2048 word * 4 = 8192 byte = 100000000_2 = 0x800 
	Clk <= M_AXIS_ACLK;
	ResetL <= M_AXIS_ARESETN;
 
    matrix_size <= to_integer(unsigned(input_matrix_height(7 downto 0))) * to_integer(unsigned(weight_matrix_width(7 downto 0)));
 
	PacketSize_signal <= std_logic_vector(to_unsigned(matrix_size, PacketSize_signal'length)); -- packetsize * 4 will be the number of byte
	PacketSize_signal_addr <= PacketSize_signal(31 DOWNTO 2);
	
	process(clk) is 
    begin 
        if clk'event and clk='1' then
            en_delay <= enable; 
            en_delay2 <= en_delay;
            en_delay3 <= en_delay2;
            en_delay4 <= en_delay3;
            en_delay5 <= en_delay4;
        end if; 
    end process; 
	
	-- detect edges of EnableSampleGeneration
	PROCESS (Clk)
	BEGIN
		IF (ResetL = '0') THEN
			enableSampleGenerationR <= '0';
		ELSIF (rising_edge(clk)) THEN
			enableSampleGenerationR <= en_delay5;
			enableSampleGenerationD1 <= enableSampleGenerationR;
			enableSampleGenerationD2 <= enableSampleGenerationD1;
			--enableSampleGenerationD3 <= enableSampleGenerationD2;
		END IF;
	END PROCESS;
 
	enableSampleGenerationPosEdge <= enableSampleGenerationD1 AND (NOT enableSampleGenerationD2);
	enableSampleGenerationNegEdge <= (NOT enableSampleGenerationD1) AND enableSampleGenerationD2;
 
	-- fsm to enable / disable sample generation
	-- simple fsm to control the sate of sample generator module
	-- when EnableSampleGeneration arrives, the module begins producing samples
	-- when EnableSampleGeneration goes down, the module waits until is sends up to the end of the current packet and then stops.
	PROCESS (Clk)
		BEGIN
			IF (ResetL = '0') THEN
				fsm_currentState <= FSM_STATE_IDLE;
				fsm_prevState <= FSM_STATE_IDLE;
			ELSIF (rising_edge(clk)) THEN 
 
				CASE fsm_currentState IS
					WHEN FSM_STATE_IDLE => 
						IF (enableSampleGenerationPosEdge = '1') THEN
							fsm_currentState <= FSM_STATE_ACTIVE;
							fsm_prevState <= FSM_STATE_IDLE;
						ELSE
							fsm_currentState <= FSM_STATE_IDLE;
							fsm_prevState <= FSM_STATE_IDLE;
						END IF;
 
					WHEN FSM_STATE_ACTIVE => 
						IF enableSampleGenerationNegEdge = '1' OR (sentPacketCounter = std_logic_vector(unsigned(NumberOfPacketsToSend) - 1)) THEN
							fsm_currentState <= FSM_STATE_WAIT_END;
							fsm_prevState <= FSM_STATE_ACTIVE;
						ELSE
							fsm_currentState <= FSM_STATE_ACTIVE;
							fsm_prevState <= FSM_STATE_ACTIVE;
						END IF;
 
					WHEN FSM_STATE_WAIT_END => 
						IF (lastDataIsBeingTransferred = '1') THEN
							fsm_currentState <= FSM_STATE_IDLE;
							fsm_prevState <= FSM_STATE_WAIT_END;
						ELSE
							fsm_currentState <= FSM_STATE_WAIT_END;
							fsm_prevState <= FSM_STATE_WAIT_END;
						END IF;

					WHEN OTHERS => 
						fsm_currentState <= FSM_STATE_IDLE;
						fsm_prevState <= FSM_STATE_IDLE;
 
            END CASE;
        END IF;
    END PROCESS;

		--data transfer qualifiers
    dataIsBeingTransferred <= M_AXIS_TVALID_signal AND M_AXIS_TREADY;
    lastDataIsBeingTransferred <= dataIsBeingTransferred AND M_AXIS_TLAST_signal;
 
    -- packet size 
    PROCESS (Clk)
    BEGIN
        IF (ResetL = '0') THEN
            packetSizeInDwords <= (OTHERS => '0');
            validBytesInLastChunk <= (OTHERS => '0'); 
        ELSIF (rising_edge(clk)) THEN 
            IF (enableSampleGenerationPosEdge = '1') THEN 
                packetSizeInDwords <= PacketSize_signal(31 DOWNTO 2); -- packetsize in word mean the packetsize in byte divided by 4
                a <= std_logic_vector(unsigned(PacketSize_signal) - unsigned(packetSizeInDwords) * 4);
                validBytesInLastChunk <= a(1 DOWNTO 0);
                --validBytesInLastChunk <= PacketSize - packetSizeInDwords * 4;
            END IF;
        END IF;
    END PROCESS; 

    --this is a C_M_AXIS_TDATA_WIDTH bits counter which counts up with every successful data transfer. this creates the body of the packets.

    PROCESS (Clk)
        BEGIN
            IF (ResetL = '0') THEN
                addrCounter <= (OTHERS => '0'); 
--                rd_enable <= '0';
            ELSIF (rising_edge(clk)) THEN 
                IF (to_integer(unsigned(addrCounter)) > to_integer(unsigned(PacketSize_signal_addr)-1)) THEN
                    addrCounter <= (OTHERS => '0'); 
--                    rd_enable <= '0';
                ELSIF (dataIsBeingTransferred = '1') THEN
                    addrCounter <= std_logic_vector(unsigned(addrCounter) + 1);
--                    rd_enable <= '1';
                ELSE
--                    addrCounter <= (OTHERS => '0');
--                    rd_enable <= '0';
                    addrCounter <= addrCounter;
                END IF;
            END IF;
        END PROCESS;

    -- --M_AXIS_TDATA <= globalCounter; 
    rd_address <= std_logic_vector(unsigned(addrCounter));
    M_AXIS_TDATA <= DP_Din; 
    rd_enable <= dataIsBeingTransferred;

    --packet counter 
    PROCESS (Clk)
        BEGIN
            IF (ResetL = '0') THEN
                packetDWORDCounter <= (OTHERS => '0');
            ELSIF (rising_edge(clk)) THEN 
                IF (lastDataIsBeingTransferred = '1') THEN
                    packetDWORDCounter <= (OTHERS => '0');
                ELSIF (dataIsBeingTransferred = '1') THEN
                    packetDWORDCounter <= std_logic_vector(unsigned(packetDWORDCounter) + 1);
                ELSE
                    packetDWORDCounter <= packetDWORDCounter;
                END IF;
            END IF;
        END PROCESS;

        --Packet rate counter
        -- with this logic, we can tune the speed of data production
        --PacketRate is an 8 bits number. this number indicates, within each 256 cycles of packet generation
        --for how many clock cycles we do not want to produce any data.
        --if PacketRate == 0 , then we produce data in all of the 256 clock cycles
        --if PacketRate == 1 , then we produce data for 255 clock cycles, and then for one clock cycle we do not produce any packet
        -- if PacketRate == 255,the we produce data for 1 clock cycle and we do not produce data for the rest 255 clock cycles.

        PROCESS (Clk)
            BEGIN
                IF (ResetL = '0') THEN
                    packetRate_Counter <= (OTHERS => '0'); 
                ELSIF (rising_edge(clk)) THEN
                    packetRate_Counter <= std_logic_vector(unsigned(packetRate_Counter) + 1);
                END IF;
            END PROCESS;

        packetRate_allowData <= '1' WHEN packetRate_Counter >= PacketRate ELSE '0';

        --Sent packet Counter
        --this counts total number of packets which are being sent up to this point

        PROCESS (Clk)
            BEGIN
                IF (ResetL = '0') THEN
                    sentPacketCounter <= (OTHERS => '0');
                ELSIF (rising_edge(clk)) THEN 
                    IF (fsm_currentState = FSM_STATE_IDLE) THEN
                        sentPacketCounter <= (OTHERS => '0');
                    ELSIF (lastDataIsBeingTransferred = '1') THEN
                        sentPacketCounter <= std_logic_vector(unsigned(sentPacketCounter) + 1);
                    END IF;
                END IF;
            END PROCESS; 

            --TVALID
            --generation of TVALID signal
            --if the fsm is in active state, then we generate packets
            M_AXIS_TVALID_signal <= '1' WHEN packetRate_allowData = '1' AND ((fsm_currentState = FSM_STATE_ACTIVE) OR (fsm_currentState = FSM_STATE_WAIT_END)) ELSE
                                    '0';
            --TLAST
            M_AXIS_TLAST_signal <= '1' WHEN validBytesInLastChunk = "00" AND packetDWORDCounter = std_logic_vector(unsigned(packetSizeInDwords) - 1) ELSE
                                   '1' WHEN packetDWORDCounter = packetSizeInDwords ELSE
                                   '0';

            M_AXIS_TSTRB_signal <= x"F" WHEN (NOT lastDataIsBeingTransferred) = '1' AND dataIsBeingTransferred = '1' ELSE
                                   x"7" WHEN lastDataIsBeingTransferred = '1' AND validBytesInLastChunk = "11" ELSE
                                   x"3" WHEN lastDataIsBeingTransferred = '1' AND validBytesInLastChunk = "10" ELSE
                                   x"1" WHEN lastDataIsBeingTransferred = '1' AND validBytesInLastChunk = "01" ELSE
                                   x"F";

            --TKEEP and TUSER
            M_AXIS_TKEEP <= M_AXIS_TSTRB_signal_delay3; --4'hf;
            M_AXIS_TUSER <= '0'; 

            M_AXIS_TVALID <= M_AXIS_TVALID_signal_delay3;
            M_AXIS_TSTRB <= M_AXIS_TSTRB_signal_delay3;
            M_AXIS_TLAST <= M_AXIS_TLAST_signal_delay3;
           
            process(clk) is 
            begin 
                if clk'event and clk='1' then
                    M_AXIS_TVALID_signal_delay1 <= M_AXIS_TVALID_signal;
                    M_AXIS_TVALID_signal_delay2 <= M_AXIS_TVALID_signal_delay1;
                    M_AXIS_TVALID_signal_delay3 <= M_AXIS_TVALID_signal_delay2;
--                    M_AXIS_TVALID_signal_delay4 <= M_AXIS_TVALID_signal_delay3;
                    
                    M_AXIS_TSTRB_signal_delay1 <= M_AXIS_TSTRB_signal; 
                    M_AXIS_TSTRB_signal_delay2 <= M_AXIS_TSTRB_signal_delay1; 
                    M_AXIS_TSTRB_signal_delay3 <= M_AXIS_TSTRB_signal_delay2; 
--                    M_AXIS_TSTRB_signal_delay4 <= M_AXIS_TSTRB_signal_delay3;
                    
                    M_AXIS_TLAST_signal_delay1 <= M_AXIS_TLAST_signal; 
                    M_AXIS_TLAST_signal_delay2 <= M_AXIS_TLAST_signal_delay1; 
                    M_AXIS_TLAST_signal_delay3 <= M_AXIS_TLAST_signal_delay2; 
--                    M_AXIS_TLAST_signal_delay4 <= M_AXIS_TLAST_signal_delay3; 
                    
                end if; 
            end process;  
            
 
 
							-- dataTransfering <= dataIsBeingTransferred;
 
END Behavioral;