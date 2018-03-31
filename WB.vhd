library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WB is
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
end WB;

architecture behaviour of WB is
signal mux: std_logic:= '0';

begin
	--Place WB buffer into the output buffer
	output_WB_ControlBuffer <= controlBuffer_WB;  
	wb_process:process(clk)
	begin
	--If code is load word, memory data will be written back, otherwise,the alu result is going to be written
	--The WB address is the output WB address
   if (clk'event and clk = '1') then 
      if(opcode = "100011") then 
          WB_OutData <= memory_data;
       else 
         WB_OutData <= ALU_output;
       end if;
      output_WB_address <= WB_address;
    end if;
end process;
end behaviour;
