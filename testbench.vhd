library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end testbench;

architecture behaviour of testbench is

	component ifprocess is
		generic(
			ram_size : integer := 4096
		);
   	port (
			clock: IN STD_LOGIC;
			reset: in std_logic := '0';
			insert_stall: in std_logic := '0';
			BranchAddress: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			takenBranch: IN STD_LOGIC := '0';
			nextAddress: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			instruction: out std_logic_vector(31 downto 0);
			readfinish : in std_logic := '0'
		);
  	end component;
  
  	component ID is
	
		GENERIC(
		  register_size: integer:=32
		);
		
		PORT( 
		  clk: in  std_logic;
		  input_branch: in std_logic;
		  
		  instructionAddress: in  std_logic_vector(31 downto 0);
		  inputRegister: in  std_logic_vector(31 downto 0);
		  WBR_Address: in  std_Logic_vector(4 downto 0);
		  WBC: in  std_logic_vector(31 downto 0);
		  ExBuffer: in std_logic_vector(10 downto 0);
		  output_instruction_address: out std_logic_vector(31 downto 0);
		  jump_Address: out std_logic_vector(25 downto 0);
		  rs:  out std_logic_vector(31 downto 0);
		  rt:  out  std_logic_vector(31 downto 0);  

		  destinationAddress: out std_logic_vector(4 downto 0);
		  signExtImm: out  std_logic_vector(31 downto 0);
		  insert_stall: out std_logic;
		  
		  controlBuffer_EX: out std_logic_vector(10 downto 0);
		  controlBuffer_MEM: out std_logic_vector(5 downto 0);
		  controlBuffer_WB: out std_logic_vector(5 downto 0);
		  funct_out: out std_logic_vector(5 downto 0);
		  opcode_out: out  std_logic_vector(5 downto 0);
		  write_reg_txt: in std_logic:='0'
		);
	end component;

	component EX is
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
	end component;
		
	component DataMem is
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
			 
			 
			 branchTaken: in std_logic;
			 input_branch_address: in std_logic_vector(31 downto 0):=(others => '0');  
			 output_destination_address: out std_logic_vector(4 downto 0):=(others => '0');
			 input_destination_address: in std_logic_vector(4 downto 0):=(others => '0');
			 
			 branchAddress: out std_logic_vector(31 downto 0):=(others => '0');  
			 output_branch_taken: out std_logic:= '0';                 
			 write_reg_txt: in std_logic := '0'
		 );
 end component;


	component WB is
		PORT( 
			clk: in  std_logic;
			memory_data: in std_logic_vector(31 downto 0);
			ALU_output: in std_logic_vector(31 downto 0);
			opcode : in std_logic_vector(5 downto 0);
			WB_address: in std_logic_vector(4 downto 0);
			
			controlBuffer_WB: in std_logic_vector(5 downto 0);
			output_WB_ControlBuffer: out std_logic_vector(5 downto 0);
			
			WB_OutData: out std_logic_vector(31 downto 0);
			output_WB_address: out std_logic_vector(4 downto 0)	  
		 );
    end component;




---------------------------------------------------------------------------------
	signal clock : std_logic;
   signal programend: std_logic := '0';
	constant clkPeriod: time := 1 ns;
	signal readDone: std_logic := '0';
	signal instAddr : std_logic_vector (31 downto 0):=(others => '0');
   signal inst : std_logic_vector (31 downto 0):=(others => '0');
	signal wbRegAddr: std_Logic_vector(4 downto 0):= (others => '0'); 
	signal wbData: std_logic_vector(31 downto 0):=(others => '0'); 
   signal exCtlBuffer: std_logic_vector(10 downto 0):=(others => '0');
   signal reset : std_logic;
	signal stall : std_logic := '0';
	signal bAddress : std_logic_vector (31 downto 0):=(others => '0');
	signal bTaken : std_logic := '0';
	signal funct_from_id: std_logic_vector(5 downto 0):=(others => '0');
	signal signExtImm: std_logic_vector(31 downto 0):=(others => '0');
   signal opcode_bt_IdnEx: std_logic_vector(5 downto 0):=(others => '0'); 
   signal exCtlBuffId: std_logic_vector(10 downto 0):=(others => '0');
	signal memCtlBuffId: std_logic_vector(5 downto 0):=(others => '0');
	signal wbCtlBuffId: std_logic_vector(5 downto 0):=(others => '0');
	signal jAddr: std_logic_vector (25 downto 0):=(others => '0');
	signal instAddrId : std_logic_vector (31 downto 0):=(others => '0');
	signal rs: std_logic_vector(31 downto 0):=(others => '0');
	signal rt: std_logic_vector(31 downto 0):=(others => '0');
	signal destAddressId: std_logic_vector(4 downto 0):=(others => '0');
   signal bran_taken_from_ex: std_logic:= '0';
	signal bran_addr_from_ex: std_logic_vector(31 downto 0):=(others => '0');
	signal MEM_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
	signal WB_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
   signal memCtlBuffMem: std_logic_vector(5 downto 0):=(others => '0'); 
	signal wbCtlBuffWb: std_logic_vector(5 downto 0):=(others => '0');
	signal opcode_bt_ExnMem: std_logic_vector(5 downto 0):=(others => '0'); 
	signal ALU_result_from_ex: std_logic_vector(31 downto 0):=(others => '0');
	signal des_addr_from_ex: std_logic_vector(4 downto 0):=(others => '0');
	signal rt_data_from_ex: std_logic_vector(31 downto 0):=(others => '0');
	signal des_addr_from_mem: std_logic_vector(4 downto 0):=(others => '0');
	signal WB_control_buffer_from_mem: std_logic_vector(5 downto 0):=(others => '0');
	signal opcode_bt_MemnWb: std_logic_vector(5 downto 0):=(others => '0') ;
	signal memory_data: std_logic_vector(31 downto 0):=(others => '0');
	signal alu_result_from_mem: std_logic_vector(31 downto 0):=(others => '0');
	
--------------------------------------------------------------------

begin
  
fetch : ifprocess
generic map (
	ram_size => 4096
)
port map (
			clock => clock,
			reset => reset,
			insert_stall => stall,
			BranchAddress => bAddress,
			takenBranch => bTaken,
			nextAddress => instAddr,
			instruction =>  inst,	
			readfinish => readDone
);
    
decode : ID
generic map (
			register_size => 32
) 
port map (
			clk => clock,
			input_branch =>bTaken,
			instructionAddress => instAddr,
			inputRegister => inst,
			WBR_Address => wbRegAddr,
       	WBC => wbData,
			ExBuffer => exCtlBuffer,
			output_instruction_address => instAddrId,
			jump_Address => jAddr,
			rs => rs,
			rt => rt,
			destinationAddress => destAddressId,
			signExtImm => signExtImm,
			insert_stall => stall,  
			controlBuffer_EX => exCtlBuffId,
			controlBuffer_MEM => memCtlBuffId,
			controlBuffer_WB => wbCtlBuffId,
			funct_out => funct_from_id,
			opcode_out => opcode_bt_IdnEx,
			write_reg_txt => programend
);	
	
execute: EX
port map (
		  
			clk => clock,
			inputBranch =>bTaken,
			instructionAddr => instAddrId,
			jumpAddr => jAddr,
			registerSrc => rs,
			registerTarg => rt,
			destAddr => destAddressId,
			signExtImm => signExtImm,
			exCtlBuff => exCtlBuffId,
			memCtlBuff => memCtlBuffId,
			wbCtlBuff => wbCtlBuffId,
			op => opcode_bt_IdnEx,
			functt => funct_from_id,
			memCtlBuffOld => memCtlBuffMem ,
			wbCtlBuffOld => wbCtlBuffWb,
			wbData => wbData,
			branchAddress => bran_addr_from_ex,
			takenBranch => bran_taken_from_ex,
			opOut => opcode_bt_ExnMem,
			destAddrOut => des_addr_from_ex,
			ALU_result => ALU_result_from_ex,
			rt_data => rt_data_from_ex,
			memCtlBuffOut => MEM_control_buffer_from_ex,		
			wbCtlBuffOut => WB_control_buffer_from_ex,				
			exCtlBuffOut => exCtlBuffer	
);

memory: DataMem
port map (
			clock => clock,
			opcode => opcode_bt_ExnMem,
			input_destination_address => des_addr_from_ex,
			ALU_result => ALU_result_from_ex,
			rt_Data => rt_data_from_ex,
			branchTaken => bran_taken_from_ex,
			input_branch_address =>  bran_addr_from_ex,
			control_buffer_MEM => MEM_control_buffer_from_ex,
			control_buffer_WB => WB_control_buffer_from_ex,
			write_reg_txt => programend,
			MEM_control_buffer_out => memCtlBuffMem,
			WB_control_buffer_out => WB_control_buffer_from_mem,
			memoryData => memory_data,
			ALU_data => ALU_result_from_mem,
			output_destination_address => des_addr_from_mem,
			branchAddress => bAddress,
			output_branch_taken => bTaken
);
	
writeback: WB
port map (
			clk => clock,
			memory_data => memory_data,
			ALU_output => alu_result_from_mem,
			opcode => opcode_bt_MEmnWb,
			WB_address => des_addr_from_mem,
			controlBuffer_WB => WB_control_buffer_from_mem,
			output_WB_ControlBuffer => wbCtlBuffWb,
			output_WB_address => wbRegAddr,
			WB_outData => wbData
);

clk_process : process
begin
	clock <= '0';
	wait for clkPeriod/2;
	clock <= '1';
	wait for clkPeriod/2;
end process;

	
test_process : process
begin
	wait for 10000* clkPeriod;
	programend <= '1';
	wait;
end process;
end behaviour;
