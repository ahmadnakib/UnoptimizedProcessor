library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end testbench;

architecture behaviour of testbench is

	component ifprocess is
		generic(
			ram_size : integer := 4096
             		--clock_period : time : 1 ns
		);
   		port (
			clock : in std_logic;
          		reset : in std_logic := '0';
          		insert_stall : in std_logic := '0';
          		BranchAddr : in std_logic_vector (31 downto 0);
          		Branch_taken : in std_logic := '0';
          		next_addr : out std_logic_vector (31 downto 0);
          		inst : out std_logic_vector (31 downto 0);		
			readfinish : in std_logic := '0'
		);
  	end component;
  
  	component ID is
    		generic(
			register_size : integer := 32
		);
   		port (
			clk: in  std_logic;
          		--hazard_detect: in std_logic;   -- stall the instruction when hazard_detect is 1 
          		instruction_addr: in  std_logic_vector(31 downto 0);
                bran_taken_in: in std_logic;-- from mem
          		IR_in: in  std_logic_vector(31 downto 0);
          		writeback_register_address: in  std_Logic_vector(4 downto 0);
          		writeback_register_content: in  std_logic_vector(31 downto 0);
          		ex_state_buffer: in std_logic_vector(10 downto 0);
          		instruction_addr_out: out std_logic_vector(31 downto 0);
          		jump_addr: out std_logic_vector(25 downto 0);
          		rs:  out std_logic_vector(31 downto 0);
          		rt:  out  std_logic_vector(31 downto 0);
          		--rd_addr: out std_logic_vector(4 downto 0);
          		des_addr: out std_logic_vector(4 downto 0);
          		signExtImm: out  std_logic_vector(31 downto 0);
          		insert_stall: out std_logic;
          		EX_control_buffer: out std_logic_vector(10 downto 0);
          		MEM_control_buffer: out std_logic_vector(5 downto 0);
          		WB_control_buffer: out std_logic_vector(5 downto 0);
          		funct_out: out std_logic_vector(5 downto 0);
          		opcode_out: out  std_logic_vector(5 downto 0);
          		write_reg_txt: in std_logic:='0'
		);
	end component;

	component EX is
		PORT( 
              		clk: in  std_logic;
                    
              		-- from id stage 
              		instruction_addr_in: in std_logic_vector(31 downto 0);
              		jump_addr : in std_logic_vector( 25 downto 0); -- changed from 31 dwonto 0 to 25 down to 0
              		rs:  in std_logic_vector(31 downto 0);
              		rt:  in  std_logic_vector(31 downto 0);  
              		des_addr: in std_logic_vector(4 downto 0);
              		signExtImm: in  std_logic_vector(31 downto 0);
              		EX_control_buffer: in std_logic_vector(10 downto 0); --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
              		MEM_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		WB_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		opcode_in: in  std_logic_vector(5 downto 0);
              		funct_in: in std_logic_vector(5 downto 0) ;
              
             		-- from mem stage
             		MEM_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from last instruction which is in mem stage now
                    bran_taken_in: in std_logic;-- from mem
             		-- MEM_result: in std_logic_vector(31 downto 0); -- if last inst is load word, its data from mem
             		-- last_opcode : in std_logic_vector(5 downto 0);  -- opcode of last instruction
           
              		-- from wb stage
              		WB_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from the one before last instruction which is in wb stage now
              		writeback_data: in std_logic_vector(31 downto 0); -- data for forwarding of last last instruction
       
              		-- for mem stage 
	      		branch_addr: out std_logic_vector(31 downto 0);
              		bran_taken: out std_logic;
              		opcode_out: out std_logic_vector(5 downto 0);
              		des_addr_out: out std_logic_vector(4 downto 0);
              		 ALU_result: out std_logic_vector(31 downto 0);
              		rt_data: out std_logic_vector(31 downto 0);
              		MEM_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		WB_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
             		-- for id stage 
	      		EX_control_buffer_out: out std_logic_vector(10 downto 0) --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		);
	end component;
		
  component DataMem is
         GENERIC(
		ram_size : INTEGER := 32768
	);
    port(
         clock: in std_logic;
         opcode: in std_logic_vector(5 downto 0):=(others => '0');
         dest_addr_in: in std_logic_vector(4 downto 0):=(others => '0');
         ALU_result: in std_logic_vector(31 downto 0):=(others => '0');
         rt_data: in std_logic_vector(31 downto 0):=(others => '0');
	     bran_taken: in std_logic;  -- from mem
	     bran_addr_in: in std_logic_vector(31 downto 0):=(others => '0');  -- new added 
	     MEM_control_buffer: in std_logic_vector(5 downto 0):=(others => '0');
	     WB_control_buffer : in std_logic_vector(5 downto 0):=(others => '0');
	    
	     MEM_control_buffer_out: out std_logic_vector(5 downto 0):=(others => '0'); --for ex forward 
	     WB_control_buffer_out : out std_logic_vector(5 downto 0):=(others => '0'); -- for wb stage 
         
	     mem_data: out std_logic_vector(31 downto 0):=(others => '0');
         ALU_data: out std_logic_vector(31 downto 0):=(others => '0');
         dest_addr_out: out std_logic_vector(4 downto 0):=(others => '0');
         bran_addr: out std_logic_vector(31 downto 0):=(others => '0'); -- for if 
	     bran_taken_out: out std_logic:= '0';                -- for if 
	     write_reg_txt: in std_logic := '0' -- indicate program ends-- from testbench
	    
         );
 end component;


     component WB is
	PORT( 
              clk: in  std_logic;
              memory_data: in std_logic_vector(31 downto 0);
              alu_result: in std_logic_vector(31 downto 0);
              opcode : in std_logic_vector(5 downto 0);
              writeback_addr: in std_logic_vector(4 downto 0);
	      WB_control_buffer: in std_logic_vector(5 downto 0);
              -- for ex stage forward
	      WB_control_buffer_out: out std_logic_vector(5 downto 0);
	      -- for id stage
	      writeback_data_out: out std_logic_vector(31 downto 0);
              writeback_addr_out: out std_logic_vector(4 downto 0)
	   );
    end component;




---------------------------------------------------------------------------------
	signal clock : std_logic;
        signal programend: std_logic := '0';
	constant clock_period: time := 1 ns;
	signal readfinish: std_logic := '0';
 	-- signal into if
        signal reset : std_logic;
	signal insert_stall : std_logic := '0';
	signal branch_addr : std_logic_vector (31 downto 0):=(others => '0');
	signal branch_taken : std_logic := '0';
	-- signal into id
        signal inst_addr : std_logic_vector (31 downto 0):=(others => '0');
        signal inst : std_logic_vector (31 downto 0):=(others => '0');
	signal writeback_register_address: std_Logic_vector(4 downto 0):= (others => '0'); 
	signal writeback_data: std_logic_vector(31 downto 0):=(others => '0');  -- also into ex, out of wb
        signal EX_control_buffer_from_ex: std_logic_vector(10 downto 0):=(others => '0');
       -- signal into ex 
	  -- from id 
        signal jump_addr: std_logic_vector (25 downto 0):=(others => '0');
        signal inst_addr_from_id : std_logic_vector (31 downto 0):=(others => '0');
        signal rs: std_logic_vector(31 downto 0):=(others => '0');
	    signal rt: std_logic_vector(31 downto 0):=(others => '0');
	    signal des_addr_from_id: std_logic_vector(4 downto 0):=(others => '0');
	    signal funct_from_id: std_logic_vector(5 downto 0):=(others => '0');
	    signal signExtImm: std_logic_vector(31 downto 0):=(others => '0');
        signal opcode_bt_IdnEx: std_logic_vector(5 downto 0):=(others => '0'); -- out of id 
        signal EX_control_buffer_from_id: std_logic_vector(10 downto 0):=(others => '0');
	signal MEM_control_buffer_from_id: std_logic_vector(5 downto 0):=(others => '0');
	signal WB_control_buffer_from_id: std_logic_vector(5 downto 0):=(others => '0');
           -- from mem and wb
        signal MEM_control_buffer_from_mem: std_logic_vector(5 downto 0):=(others => '0'); -- out of mem
	signal WB_control_buffer_from_wb: std_logic_vector(5 downto 0):=(others => '0');    -- out of wb
         -- singnal into ex end 
        -- signal into mem
        signal opcode_bt_ExnMem: std_logic_vector(5 downto 0):=(others => '0');  -- out of ex 
        signal ALU_result_from_ex: std_logic_vector(31 downto 0):=(others => '0');
        signal des_addr_from_ex: std_logic_vector(4 downto 0):=(others => '0');
        signal rt_data_from_ex: std_logic_vector(31 downto 0):=(others => '0');
        signal bran_taken_from_ex: std_logic:= '0';
        signal bran_addr_from_ex: std_logic_vector(31 downto 0):=(others => '0');
        signal MEM_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
	signal WB_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
         -- signal into writeback
        signal opcode_bt_MemnWb: std_logic_vector(5 downto 0):=(others => '0') ;  -- out of mem 
        signal memory_data: std_logic_vector(31 downto 0):=(others => '0');
        signal alu_result_from_mem: std_logic_vector(31 downto 0):=(others => '0');
        signal des_addr_from_mem: std_logic_vector(4 downto 0):=(others => '0'); -- writeback_addr in wb stage 
        signal WB_control_buffer_from_mem: std_logic_vector(5 downto 0):=(others => '0'); -- from 

	--signal EX_control_buffer: std_logic_vector(10 downto 0); -- not in use
	--signal MEM_control_buffer: std_logic_vector(5 downto 0);  -- not in use
	--signal WB_control_buffer: std_logic_vector(5 downto 0);     --not in use
	
--------------------------------------------------------------------

begin
  
fetch : ifprocess
generic map (
	ram_size => 4096
	)
port map (
	clock => clock,
        reset => reset,
        insert_stall => insert_stall,
        BranchAddr => branch_addr,
        Branch_taken => branch_taken,
        next_addr => inst_addr,
        inst =>  inst,	
	readfinish => readfinish
);
    
decode : ID
generic map (
	register_size => 32
	) 
port map (
	    clk => clock,
        bran_taken_in =>branch_taken,
        instruction_addr => inst_addr,
        IR_in => inst,
        writeback_register_address => writeback_register_address,
       	writeback_register_content => writeback_data, -- in
        ex_state_buffer => EX_control_buffer_from_ex,
	instruction_addr_out => inst_addr_from_id,
        jump_addr => jump_addr,
        rs => rs,
        rt => rt,
        des_addr => des_addr_from_id,
        signExtImm => signExtImm,
        insert_stall => insert_stall,  
        EX_control_buffer => EX_control_buffer_from_id,
        MEM_control_buffer => MEM_control_buffer_from_id,
        WB_control_buffer => WB_control_buffer_from_id,
        funct_out => funct_from_id,
        opcode_out => opcode_bt_IdnEx,
        write_reg_txt => programend
	);
	
execute: EX
port map (
	clk => clock,
    bran_taken_in =>branch_taken,
	instruction_addr_in => inst_addr_from_id,
	jump_addr => jump_addr,
	rs => rs,
	rt => rt,
	des_addr => des_addr_from_id,
	signExtImm => signExtImm,
	EX_control_buffer => EX_control_buffer_from_id,
	MEM_control_buffer => MEM_control_buffer_from_id,
	WB_control_buffer => WB_control_buffer_from_id,
	opcode_in => opcode_bt_IdnEx,
	funct_in => funct_from_id,
	MEM_control_buffer_before => MEM_control_buffer_from_mem , --in
	WB_control_buffer_before => WB_control_buffer_from_wb, --in
	writeback_data => writeback_data, --in
	branch_addr => bran_addr_from_ex, -- ?? -- added in mem (runze)
	bran_taken => bran_taken_from_ex,
	opcode_out => opcode_bt_ExnMem,
	des_addr_out => des_addr_from_ex,
	ALU_result => ALU_result_from_ex,
	rt_data => rt_data_from_ex,
	MEM_control_buffer_out => MEM_control_buffer_from_ex,		
	WB_control_buffer_out => WB_control_buffer_from_ex,				
	EX_control_buffer_out => EX_control_buffer_from_ex	
	);

memory: DataMem
port map (
        clock => clock,
        opcode => opcode_bt_ExnMem,
        dest_addr_in => des_addr_from_ex,
        ALU_result => ALU_result_from_ex,
        rt_data => rt_data_from_ex,
        bran_taken => bran_taken_from_ex,
	bran_addr_in =>  bran_addr_from_ex,
        MEM_control_buffer => MEM_control_buffer_from_ex,
        WB_control_buffer => WB_control_buffer_from_ex,
        write_reg_txt => programend,
        MEM_control_buffer_out => MEM_control_buffer_from_mem,
        WB_control_buffer_out => WB_control_buffer_from_mem,
        mem_data => memory_data,
        ALU_data => ALU_result_from_mem,
        dest_addr_out => des_addr_from_mem,
        bran_addr => branch_addr,
        bran_taken_out => branch_taken
        );
	
writeback: WB
port map (
        clk => clock,
        memory_data => memory_data,
        alu_result => alu_result_from_mem,
        opcode => opcode_bt_MEmnWb,
        writeback_addr => des_addr_from_mem,
        WB_control_buffer => WB_control_buffer_from_mem,
        WB_control_buffer_out => WB_control_buffer_from_wb,
        writeback_addr_out => writeback_register_address,
        writeback_data_out => writeback_data
        );

clk_process : process
begin
	clock <= '0';
	wait for clock_period/2;
	clock <= '1';
	wait for clock_period/2;
end process;

	
test_process : process
begin
	wait for 10000* clock_period;
	programend <= '1';
	wait;
end process;
end behaviour;
