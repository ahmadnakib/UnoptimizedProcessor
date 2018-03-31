LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity DataMem is
    GENERIC(
		ram_size : INTEGER := 32768
	);
    port(
		 clock: in std_logic;
		 opcode: in std_logic_vector(5 downto 0):=(others => '0');
		 ALU_result: in std_logic_vector(31 downto 0):=(others => '0');
		 rt_Data: in std_logic_vector(31 downto 0):=(others => '0');
		 memoryData: out std_logic_vector(31 downto 0):=(others => '0');
		 ALU_data: out std_logic_vector(31 downto 0):=(others => '0');
		 
		 control_buffer_MEM: in std_logic_vector(5 downto 0):=(others => '0');
		 control_buffer_WB : in std_logic_vector(5 downto 0):=(others => '0');
		 MEM_control_buffer_out: out std_logic_vector(5 downto 0):=(others => '0'); 
		 WB_control_buffer_out : out std_logic_vector(5 downto 0):=(others => '0');
		 
		 
		 branchTaken: in std_logic;  -- from mem
		 input_branch_address: in std_logic_vector(31 downto 0):=(others => '0');
		 output_destination_address: out std_logic_vector(4 downto 0):=(others => '0');
		 input_destination_address: in std_logic_vector(4 downto 0):=(others => '0');
		 --For if Statements
		 branchAddress: out std_logic_vector(31 downto 0):=(others => '0');  
		 output_branch_taken: out std_logic:= '0';                 
		 write_reg_txt: in std_logic := '0' -- indicate program ends-- from testbench
		);
end DataMem;

architecture behavior of DataMem is
   TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
    
begin
 MEM_control_buffer_out<= control_buffer_MEM;
 process(clock)
 begin
	--Initialize SRAM in simulation
	if(now < 1 ps)THEN
	For i in 0 to ram_size-1 LOOP
		ram_block(i) <= std_logic_vector(to_signed(0,8));
	END LOOP;
	end if;
	
	--On every rising edge, place the input branch and destination addresses
	if(rising_edge(clock))then
		output_destination_address <= input_destination_address;
		branchAddress <= input_branch_address;
		output_branch_taken<= branchTaken;
		-- If the opcode is to store the word, we place it into the ram_block, if it is to load, we place it into memory 
		-- If neither store or load word, we update the ALU data with the current result
		
		if(opcode = "101011")then
			for i in 1 to 4 loop
				ram_block((to_integer(signed(ALU_result))) + i - 1) <= rt_Data(8*i - 1 downto 8*i - 8);
			end loop;
			
		-- the opcode is lw 
		elsif(opcode = "100011")then
			for i in 0 to 3 loop
				memoryData(8*i+7 downto 8*i) <= ram_block(to_integer(signed(ALU_result))+i);
			end loop;
		else
			ALU_data <= ALU_result;
		end if;
			
	--Set output buffer to current control buffer
	elsif(falling_edge(clock))then
		WB_control_buffer_out<= control_buffer_WB;
       	end if;
    end process;
	 
--Writing register to memory text, similar to how we read values in IF
    output: process (write_reg_txt)
		file memoryfile : text;
		variable memoryLine : line;
		variable status: file_open_status;
      variable reg_value  : std_logic_vector(31 downto 0);
		
	--When program ends, write to memory
	begin
	if(write_reg_txt = '1') then
		file_open(status, memoryfile, "memory.txt", write_mode);
		for i in 1 to 8192 loop
			for j in 1 to 4 loop
				reg_value(8*j - 1 downto 8*j-8) := ram_block(i*4+j-5);
			end loop;
			write(memoryLine, reg_value);
			writeline(memoryfile, memoryLine);
		end loop;
		--Close the file
		file_close(memoryfile);
	end if;
	end process;	
end behavior;
