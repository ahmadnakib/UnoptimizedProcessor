library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity EX is
        
	PORT( 
		  clk: in  std_logic;
		  inputBranch: in std_logic;
		
		  instructionAddr: in std_logic_vector(31 downto 0);
		  jumpAddr : in std_logic_vector( 25 downto 0);
		  registerSrc:  in std_logic_vector(31 downto 0);
		  registerTarg:  in  std_logic_vector(31 downto 0);  
		  destAddr: in std_logic_vector(4 downto 0);
		  signExtImm: in  std_logic_vector(31 downto 0);
		  exCtlBuff: in std_logic_vector(10 downto 0); 
		  memCtlBuff: in std_logic_vector(5 downto 0);
		  wbCtlBuff: in std_logic_vector(5 downto 0);
		  op: in  std_logic_vector(5 downto 0);
		  functt: in std_logic_vector(5 downto 0) ;
		  
		  memCtlBuffOld: in std_logic_vector(5 downto 0);
 		  wbCtlBuffOld: in std_logic_vector(5 downto 0);
		  wbData: in std_logic_vector(31 downto 0);
		  
		  branchAddress: out std_logic_vector(31 downto 0);
		  takenBranch: out std_logic;
		  opOut: out std_logic_vector(5 downto 0);
		  destAddrOut: out std_logic_vector(4 downto 0);
		  ALU_result: out std_logic_vector(31 downto 0);
		  rt_data: out std_logic_vector(31 downto 0);
		  memCtlBuffOut: out std_logic_vector(5 downto 0);
		  wbCtlBuffOut: out std_logic_vector(5 downto 0);

		  exCtlBuffOut: out std_logic_vector(10 downto 0)
	      
	);
end EX;

architecture behaviour of EX is 
       
      signal opcode: std_logic_vector(5 downto 0):= (others =>'0');
		signal ALU_opcode: std_logic_vector(3 downto 0):= (others =>'0');
		signal rs_content: integer:=0;
      signal rt_content: integer:=0;
      signal imm_content: integer:=0;
      signal funct: std_logic_vector(5 downto 0):= (others =>'0');
      signal branTaken: std_logic:= '0';
      signal branch_address: std_logic_vector(31 downto 0):= (others =>'0');
      signal pcPlus: std_logic_vector(31 downto 0):= (others =>'0');
      signal b_rs: std_logic_vector(31 downto 0):= (others =>'0');
      signal b_rt: std_logic_vector(31 downto 0):= (others =>'0');
      signal resultTemp: std_logic_vector(31 downto 0):= (others =>'0');
		signal hiloTemp: std_logic_vector(63 downto 0):= (others =>'0');
		signal data0: std_logic_vector(31 downto 0):= (others =>'0');
      signal data1: std_logic_vector(31 downto 0):= (others =>'0');
      signal ex_rsreg: std_logic_vector (4 downto 0):= (others =>'0'); 
		signal ex_rtreg: std_logic_vector (4 downto 0):= (others =>'0');
		signal mem_destReg: std_logic_vector (4 downto 0):= (others =>'0'); 
		signal wb_destReg: std_logic_vector (4 downto 0):= (others =>'0');
		signal reg_wb_mem: std_logic:='0'; 
		signal reg_wb_wb: std_logic:='0';   
		signal rt_flag: std_logic:='0';
		signal rs_flag: std_logic:='0';
		signal SWfwd: std_logic:= '0';
		signal data_rs_forward_mem_en : std_logic:='0'; 
		signal data_rt_forward_mem_en : std_logic:='0'; 
		signal data_rs_forward_wb_en : std_logic:='0'; 
		signal data_rt_forward_wb_en : std_logic:='0';
 
  
     
begin  
	
	ALU_result <= resultTemp; 
	pcPlus <= std_logic_vector((unsigned(instructionAddr))+ 4);
	exCtlBuffOut <= exCtlBuff;
	opcode <= op;
	funct <= functt;
	ex_rsreg <= exCtlBuff(4 downto 0);
	ex_rtreg <= exCtlBuff(9 downto 5);
	mem_destReg <= memCtlBuffOld(4 downto 0);
	wb_destReg <= wbCtlBuffOld(4 downto 0);
	reg_wb_mem <= memCtlBuffOld(5);
	reg_wb_wb <= wbCtlBuffOld(5);

	--Implementing forward detection
	forward_detection: process(opcode,data_rs_forward_mem_en,data_rt_forward_mem_en ,data_rs_forward_wb_en ,data_rt_forward_wb_en )
	begin
		rs_flag <= '1';
		rt_flag <= '1';
		SWfwd <= '0';
		--If read function
		if(opcode = "000000" and (funct = "000011" or funct = "000010" or funct = "000000")) then 
		  rs_flag <= '0';
		--If LW, bitwise XOR, immediate bitwise OR, SLTI, immediate add, or a read and add
		elsif(opcode = "100011" or opcode = "001110" or opcode = "001101" or  opcode = "001100" or opcode = "001010" or opcode = "001000" or (opcode = "000000" and funct = "001000") ) then
		  rt_flag <= '0';
		 --If load upper immediate or jump and link
		elsif(opcode = "001111" or opcode = "000011") then 
		  rs_flag <= '0';
		  rt_flag <= '0';
		elsif(opcode = "101011") then 
		  rt_flag <= '0';
		  SWfwd <= '1';
		end if;
	 
		b_rs <= registerSrc;
		b_rt <= registerTarg;
		
		--Based on whether the forward is enabled, place data in rt or rs respectively
		if(data_rs_forward_mem_en = '1')then 
			b_rs <= resultTemp;
		end if;    
		if(data_rt_forward_mem_en = '1')then 
			b_rt <= resultTemp;
		end if;    
		if(data_rs_forward_wb_en = '1')then 
			b_rs <= wbData;
		end if;    
		if(data_rt_forward_wb_en = '1')then 
			b_rt <= wbData;
		end if;    
	end process;


	
forwarding_logic: process (ex_rsreg, ex_rtreg, wb_destReg, reg_wb_mem, reg_wb_wb, mem_destReg)
begin
	data_rs_forward_mem_en <= '0';
	data_rs_forward_wb_en <= '0';
	data_rt_forward_mem_en <= '0';
	data_rt_forward_wb_en <= '0';

	if (reg_wb_mem = '1') and (mem_destReg /= "00000")and (mem_destReg = ex_rsreg) then 
	  data_rs_forward_mem_en <= '1';
	end if;
	
	if (reg_wb_mem = '1')and (mem_destReg /= "00000") and (mem_destReg = ex_rtreg) then 
	  data_rt_forward_mem_en <= '1';
	end if;

	if (reg_wb_wb = '1') and (wb_destReg /= "00000") and (wb_destReg = ex_rsreg) then
	  data_rs_forward_wb_en <= '1';
	end if;
	
	if (reg_wb_wb = '1') and (wb_destReg /= "00000")and (wb_destReg = ex_rtreg) then
	  data_rt_forward_wb_en <= '1';
	end if;

end process;


--Fit forwarding acc. to opcode
--All cases considered involve a branch, set branch taken to 1 if branch will be taken/works nad update branch addrss accordingly
branch_detect_process: process(clk)
begin 
	if(rising_edge(clk))then 
		if(inputBranch = '0') then 
       case opcode is
        -- beq         
			when "000100" => 
          branch_address <= pcPlus + std_logic_vector(unsigned(signExtImm)sll  2);      
         if(b_rs = b_rt) then 
          branTaken <= '1';
         else 
          branTaken <= '0';
			end if;
        
			-- bne
         when "000101" =>
          branch_address <= pcPlus +std_logic_vector(unsigned(signExtImm)sll  2); 
         if(b_rs = b_rt) then 
          branTaken <= '0';
         else 
          branTaken <= '1';
         end if;
			
         -- jump
          when "000010" => 
           branch_address (31 downto 28) <= pcPlus(31 downto 28);
           branch_address (27 downto 2) <= jumpAddr; 
           branch_address(1 downto 0) <= "00";
           branTaken <= '1';
         
			-- jump and link 
           when "000011" => 
           branch_address (31 downto 28) <= pcPlus(31 downto 28);
           branch_address (27 downto 2) <= jumpAddr; 
           branch_address(1 downto 0) <= "00";
           branTaken <= '1';
          
			-- jump read
          when "000000" =>
         
			-- replace registerSrc or registerTarg if they are forwarded     
            if(funct = "001000")then 
              branch_address <= b_rs;
              branTaken <= '1';
            end if;
          when others =>
             branTaken <= '0'; 
             branch_address <=(others => '0');
      end case;
      
		else 
			branTaken <= '0';
			branch_address <=(others => '0');
      end if;
	end if; 
end process;


--ALU process, will look at both R and I type instructions
alu_process: process(clk,wbData)
begin
   if(rising_edge(clk) and clk'event )then 
    case opcode is
	-- R type instruction
		when "000000" =>
			case funct is                                
						
			-- add
			when "100000" =>
				ALU_opcode <= "0000";
				data0 <= registerSrc;
				data1 <= registerTarg;
											
			-- sub
			when "100010" =>
				ALU_opcode <= "0001";
				data0 <= registerSrc;
				data1 <= registerTarg;

			-- mult
			when "011000" =>
				ALU_opcode <= "0010";
				data0 <= registerSrc;
				data1 <= registerTarg;

			-- div
			when "011010" =>
				ALU_opcode <= "0011";
				data0 <= registerSrc;
				data1 <= registerTarg;

			-- slt
			when "101010" =>
				ALU_opcode <= "0100";	
				data0 <= registerSrc;
				data1 <= registerTarg;				

			-- and
			when "100100" =>
				ALU_opcode <= "0101";
				data0 <= registerSrc;
				data1 <= registerTarg;

			-- or
			when "100101" =>
				ALU_opcode <= "0110";
				data0 <= registerSrc;
				data1 <= registerTarg;

			-- nor
			when "100111" =>
				ALU_opcode <= "0111";
				data0 <= registerSrc;
				 data1 <= registerTarg;

			-- xor
			when "100110" =>
				ALU_opcode <= "1000";
				data0 <= registerSrc;
				data1 <= registerTarg;
			
			-- sll
			when "000000" =>
				ALU_opcode <= "1100";
				data0 <= registerTarg;
				data1 <= signExtImm ;

			-- srl
			when "000010" =>
				ALU_opcode <= "1101";
				data0 <= registerTarg;
				data1 <= signExtImm ;

			-- sra
			when "000011" =>
				ALU_opcode <= "1110";
				data0 <= registerTarg;
				data1 <= signExtImm ;    

			-- mfhi
			when "010000" =>
				ALU_opcode <= "1001";
				data0 <=(others =>'0');
				data1 <=(others =>'0');

			-- mflo
			when "010010" =>
				ALU_opcode <= "1010";
				data0 <=(others =>'0');
				data1 <=(others =>'0');
			                
			when others =>
				null;

			end case; -- end R type

			
			
			
			-- I type
         -- addi
         when "001000"  =>
				ALU_opcode <= "0000";
				data0 <= registerSrc;
				data1 <= signExtImm ;   
			-- andi
			when "001100" =>
				ALU_opcode <= "0101";
            data0 <= registerSrc;
            data1 <= signExtImm ;

			-- ori
			when "001101" =>
				ALU_opcode <= "0110";
            data0 <= registerSrc;
            data1 <= signExtImm ;

			-- xori
			when "001110" =>
				ALU_opcode <= "1000";
            data0 <= registerSrc;
            data1 <= signExtImm ;

			-- lui
			when "001111" =>
				ALU_opcode <= "1011";
            data0 <= (others =>'0');
            data1 <= signExtImm ;
			-- sw 
			when "101011" =>
				ALU_opcode <= "0000";
            data0 <= registerSrc;
            data1 <= signExtImm ;
				
			-- lw 
			when "100011" =>
				ALU_opcode <= "0000";
            data0 <= registerSrc;
            data1 <= signExtImm ;
			
			-- slti
			when "001010" =>
				ALU_opcode <= "0100";
            data0 <= registerSrc;
            data1 <= signExtImm ;
                        
			-- jal 
         when "000011" =>
            ALU_opcode <= "0000";  
            data0 <= instructionAddr;
            data1 <= x"00000008"; 

			when others =>
				ALU_opcode <= "1111";
            data0 <=(others =>'0');
            data1 <=(others =>'0');

		end case;
		
		 -- replace data0 and data1 when forward happend for last intruction 
		 if(data_rs_forward_mem_en = '1' and rs_flag = '1') then 
				data0 <= resultTemp; 
		 end if;    
		 if(data_rt_forward_mem_en = '1' and rt_flag = '1') then 
				data1 <= resultTemp;
		 end if;    
    end if;
        
	 if(wbData' event) then   
	--Replace data when forward occurs with result from last inst.
	 if(data_rs_forward_wb_en = '1' and  rs_flag = '1')then 
		data0 <= wbData;
	 end if;    
	 if(data_rt_forward_wb_en = '1' and  rt_flag = '1')then 
		 data1 <= wbData;
	 end if;  
end if;
           
   

if(falling_edge(clk) and clk'event ) then 
	  if(inputBranch = '1') then 
			rt_data <= (others => '0');
		else
			if(SWfwd = '1' and (data_rt_forward_mem_en = '1')) then 
			  rt_data <= resultTemp;
			elsif(SWfwd = '1' and (data_rt_forward_wb_en = '1'))then
			  rt_data <= wbData;
			else
			  rt_data <= registerTarg;
		  end if;
	  end if;
          
	 if(inputBranch = '0') then 
	case ALU_opcode is
	
	--add, addi, sw,lw
	when "0000" =>
		resultTemp <= std_logic_vector(signed(data0) + signed(data1));

	--sub
	when "0001" =>
		resultTemp <= std_logic_vector(signed(data0) - signed(data1));

	--mult
	when "0010" =>
		hiloTemp <= std_logic_vector(signed(data0) * signed(data1));
		
	--div
	when "0011" =>
		hiloTemp <= std_logic_vector(signed(data0) mod signed(data1)) & std_logic_vector(signed(data0) / signed(data0));

	--slt, slti 
	when "0100" =>
		if (signed(data0) < signed(data1)) then
			resultTemp <= "00000000000000000000000000000001";
		else
			resultTemp <= "00000000000000000000000000000000";
		end if;

	--and, andi
	when "0101" =>
		resultTemp <= data0 AND data1;
		
	--or, ori
	when "0110" =>
		resultTemp <= data0 OR data1;

	--nor
	when "0111" =>
		resultTemp <= data0 NOR data1;

	--xor, xori
	when "1000" =>
		resultTemp <= data0 XOR data1;

	--mfhi
	when "1001" =>
		resultTemp <= hiloTemp(63 downto 32);

	--mflo
	when "1010" =>
		resultTemp <= hiloTemp(31 downto 0);

	--lui
	when "1011" =>  
		resultTemp <= to_stdlogicvector(to_bitvector(data1) sll 16);

	--sll
	when "1100" =>	-- sll: R[rd] = R[registerTarg] << shamt, shamt is data1(10 downto 6)
		resultTemp <= std_logic_vector(signed(data0) sll to_integer(signed(data1(10 downto 6))));

	--srl
	when "1101" =>	-- srl: R[rd] = R[registerTarg] >> shamt, shamt is data1(10 downto 6)
		resultTemp <= std_logic_vector(signed(data0) srl to_integer(signed(data1(10 downto 6))));

	--sra
	when "1110" =>	-- sra: R[rd] = R[registerTarg] >>> shamt, shamt is data1(10 downto 6)
		resultTemp <= std_logic_vector(shift_right(signed(data0) , to_integer(signed(data1(10 downto 6)))));
		
	-- j, jr, jal
			
	when others =>
		--temp_zero <= '0';
		resultTemp <= (others => '0');

	  end case;
			 else 
		  resultTemp <= (others => '0');
		  end if;
			  -- save others things to buffer 
			  
			  if(inputBranch = '1') then 
				  opOut <=  (others => '0');
				  destAddrOut <= (others => '0');
				  memCtlBuffOut <=  (others => '0');     
				  wbCtlBuffOut <= (others => '0');
				  takenBranch<= '0';
				  branchAddress <=  (others => '0');
			  else 
				  opOut <=  opcode;
				  destAddrOut <= destAddr; 
				  memCtlBuffOut <=   memCtlBuff;       
				  wbCtlBuffOut <= wbCtlBuff;
				  takenBranch<= branTaken;
				  branchAddress <= branch_address;
			  end if;

 end if;

end process;
end behaviour;
