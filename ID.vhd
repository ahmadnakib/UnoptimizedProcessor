library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;
use IEEE.std_logic_unsigned.all;

entity ID is
  GENERIC(
		  register_size: integer:=32
		  );
	PORT( 
	  clk: in  std_logic;
	  
	  input_branch: in std_logic;-- from mem
	  inputRegister: in  std_logic_vector(31 downto 0);
	  WBC: in  std_logic_vector(31 downto 0);
	  ExBuffer: in std_logic_vector(10 downto 0);
	  rs:  out std_logic_vector(31 downto 0);
	  rt:  out  std_logic_vector(31 downto 0);  
	  
	  instructionAddress: in  std_logic_vector(31 downto 0);
	  WBR_Address: in  std_Logic_vector(4 downto 0);
	  output_instruction_address: out std_logic_vector(31 downto 0);
	  jump_Address: out std_logic_vector(25 downto 0);
	  destinationAddress: out std_logic_vector(4 downto 0);
	  
	  --Provide info for forward and hazard deecion, other bits fo signals and targe/source
	  controlBuffer_EX: out std_logic_vector(10 downto 0);
	  controlBuffer_MEM: out std_logic_vector(5 downto 0);
	  controlBuffer_WB: out std_logic_vector(5 downto 0);
	  
	  signExtImm: out  std_logic_vector(31 downto 0);
	  insert_stall: out std_logic;
	  funct_out: out std_logic_vector(5 downto 0);
	  opcode_out: out  std_logic_vector(5 downto 0);
	  write_reg_txt: in std_logic:='0'
);
end ID;

architecture behaviour of ID is
	 TYPE registerarray is ARRAY(register_size-1 downto 0) OF std_logic_vector(31 downto 0); 
	 SIGNAL register_block: registerarray;
	 SIGNAL rs_pos: std_logic_vector(4 downto 0):="00000";
	 SIGNAL rt_pos: std_logic_vector(4 downto 0):="00000";
	 SIGNAL IR: std_logic_vector(31 downto 0):= (others => '0');
	 
	 SIGNAL tempControlBuffer_MEM: std_logic_vector(5 downto 0);
	 SIGNAL tempControlBuffer_WB: std_logic_vector(5 downto 0);
	 SIGNAL immediate: std_logic_vector(15 downto 0):="0000000000000000";
	 SIGNAL rd_pos: std_logic_vector(4 downto 0):="00000";
	 SIGNAL dest_address: std_logic_vector(4 downto 0):="00000";
	 
	 SIGNAL opcode: std_logic_vector(5 downto 0):="000000";
	 SIGNAL funct: std_logic_vector(5 downto 0):="000000";
	 SIGNAL hazard_detect: std_logic:= '0';
	 signal test1: std_logic_vector(31 downto 0 );
	 signal test: std_logic_vector(31 downto 0 );
		 
begin
	--Getting information from the input register
	 rs_pos<= IR(25 downto 21);
	 rd_pos<= IR(15 downto 11);
	 rt_pos<= IR (20 downto 16);
	 immediate<= IR(15 downto 0); 
	 insert_stall <= hazard_detect; 
	 opcode <= IR(31 downto 26);
	 funct  <= IR(5 downto 0);
	 test <= register_block(2);
	 test1 <= register_block(2);

--Check for hazards 
hazard_process: process(ExBuffer,clk)
begin
	hazard_detect<= '0'; 
	if(ExBuffer(10) = '1' and input_branch = '0' ) then 
	 if(ExBuffer(9 downto 5) = rs_pos or ExBuffer(4 downto 0) = rt_pos)then
		 IR <= inputRegister;             
		 hazard_detect <= '1';
	  else
		IR<= x"00000020"; 
		hazard_detect<= '0'; 
	  end if;
	else
       IR <= inputRegister; 
 end if;
     
end process;

--This process is the write back process
wb_process: process(clk, WBC, WBR_Address)
begin
    --Go through all registers and initialize them 
   IF( now < 1 ps )THEN
		For i in 0 to register_size-1 LOOP
		  register_block(i) <= std_logic_vector(to_unsigned(0,32));
	END LOOP;
 end if;
	 
  --Writes the register content to the register block as long as  the address is not 00000
	if (WBR_Address /= "00000" and now > 4 ns ) then
		register_block(to_integer(unsigned(WBR_Address))) <= WBC;
	end if;    
end process;


reg_process:process(clk)
begin
   if(clk'event and clk = '1') then

--Gets the destination address based on certain cases
 case opcode is 
          -- R type instruction 
          when "000000" =>
             if(funct = "011010" or funct = "011000" or funct = "001000") then 
					dest_address <="00000";
             else 
					dest_address <= rd_pos;
             end if;
           
			  -- Immediate & Jump type instructions
			  -- Load word
				when "100011" => 
						dest_address <= rt_pos;
				-- Load upper immediate
				when "001111" => 
						dest_address <= rt_pos;
				-- Bitwise XOR immediate
				-- slti
				when "001010" => 
						dest_address <= rt_pos;
				-- Immediate add
				when "001000" => 
						dest_address <= rt_pos;
				-- Jump and link
				when "000011" => 
						dest_address <= "11111";
				when "001110" => 
						dest_address <= rd_pos;
				-- Immediate bitwise or
				when "001101" => 
						dest_address <= rt_pos;
				-- Immediate biwise and
				when "001100" => 
						dest_address <= rt_pos;
				 when others =>
						dest_address <="00000";
			 end case;
    
	 
	 --If no branch, put the data into decode and execution buffers
	 --Get the rs and rt from the register block, the opcode, function and the instruction address
   elsif(falling_edge(clk)) then
		if(input_branch = '0') then
		  rs<= register_block(to_integer(unsigned(rs_pos)));
		  rt<= register_block(to_integer(unsigned(rt_pos)));
		  destinationAddress<= dest_address;
		  output_instruction_address<=instructionAddress;	
		  jump_Address <= IR(25 downto 0);
		  opcode_out<=IR(31 downto 26);
		  funct_out <= funct;
		  
		  signExtImm(15 downto 0) <= immediate;
		  if(IR(31 downto 27) = "00110") then
			 signExtImm(31 downto 16)<=(31 downto 16 => '0');     
			else
			 signExtImm(31 downto 16)<=(31 downto 16 => immediate(15));
		  end if;
		  
      else
			rs<= (others => '0');
			rt<= (others => '0');
			destinationAddress<= (others => '0');
			output_instruction_address<=(others => '0');	
			jump_Address <= (others => '0');
			funct_out <= (others => '0');
			opcode_out<=(others => '0');
			signExtImm(31 downto 0) <= (others => '0');  
		end if;
	end if;
end process;


--Saves control signal to the buffer
control_process: process(clk)
begin 
 -- execution control buffer, 0 or 1 in buffer based on the opcode and if a branch wasn't taken
 --If a branch was taken, set the temporary buffers to 0
     if(falling_edge(clk)) then 
      if(input_branch = '0') then
		 if(opcode = "100011") then 
           controlBuffer_EX(10) <= '1';
        else 
           controlBuffer_EX(10) <= '0';
       end if;
	 
	 --Place target and source positions into the buffer
	 controlBuffer_EX(4 downto 0) <= rs_pos; 
	 controlBuffer_EX(9 downto 5) <= rt_pos;
	 
	 --Based on opcode, store certain values in the buffers
		case opcode is 
			-- R type
			when "000000" =>
				 if(funct = "011010" or funct = "011000" or funct = "001000") then 
					tempControlBuffer_WB(5) <= '0';
					tempControlBuffer_MEM(5) <= '0';  
				  else 
					  tempControlBuffer_WB(5) <= '1';
					  tempControlBuffer_MEM(5) <= '1';
				  end if;
			-- Jump and Immediate type instructions
			
			-- lw
			when "100011" => 
					tempControlBuffer_WB(5) <= '1';
					tempControlBuffer_MEM(5) <= '0';
			-- andi
			when "001100" => 
				  tempControlBuffer_WB(5) <= '1';
				  tempControlBuffer_MEM(5) <= '1';
			-- slti
			when "001010" => 
				  tempControlBuffer_WB(5) <= '1';
				  tempControlBuffer_MEM(5) <= '1';
			-- addi
			when "001000" => 
				  tempControlBuffer_WB(5) <= '1';
				  tempControlBuffer_MEM(5) <= '1';
			-- lui
			when "001111" => 
				  tempControlBuffer_WB(5) <= '1';
				  tempControlBuffer_MEM(5) <= '1';
			-- xori
			when "001110" => 
				 tempControlBuffer_WB(5) <= '1';
				 tempControlBuffer_MEM(5) <= '1';  
			-- ori
			when "001101" => 
				  tempControlBuffer_WB(5) <= '1';
				  tempControlBuffer_MEM(5) <= '1';
			-- jal
			when "000011" => 
				  tempControlBuffer_WB(5) <= '1';
				  tempControlBuffer_MEM(5) <= '1';
			when others =>
					tempControlBuffer_WB(5) <= '0';
					tempControlBuffer_MEM(5) <= '0'; 
		end case;
		
	 --Store destination address in buffers
	 tempControlBuffer_MEM(4 downto 0) <= dest_address;
	 tempControlBuffer_WB(4 downto 0) <= dest_address;
	 
	 --If branch was taken, set to 0
	 else
		 tempControlBuffer_MEM <= (others=> '0');
		 controlBuffer_EX <=(others => '0');
		 tempControlBuffer_WB <= (others=> '0');
	 end if;
 end if; 
end process;

--Place temporary buffers into final buffers as they are now updated
controlBuffer_WB <=tempControlBuffer_WB;
controlBuffer_MEM <= tempControlBuffer_MEM;


--Write the register value to the file, similar to read in IF
file_handler_process: process(write_reg_txt)
   file registerfile : text;
	variable line_num : line;
	variable status: file_open_status;
	variable reg_value : std_logic_vector(31 downto 0);
	begin
	-- When the program ends
	if(write_reg_txt = '1')then
		--Write to the register file
        	file_open(status,registerfile, "register_file.txt", WRITE_MODE);
		-- convert each bit value of reg_value to character for writing 
			for i in 0 to 31 loop
				reg_value := register_block(i);
				--Write the line and write the contents into the txt file
				write(line_num, reg_value); 
				writeline(registerfile, line_num); 
        	end loop;
			--Close the file
        	file_close(registerfile);
      	end if;
    end process;

end behaviour;

