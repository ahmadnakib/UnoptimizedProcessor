library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is
    port(
	 reg_rs_ex : in std_logic_vector (4 downto 0);
    reg_rt_ex : in std_logic_vector (4 downto 0);
    reg_rd_mem: in std_logic_vector (4 downto 0);
    reg_rd_wb: in std_logic_vector (4 downto 0);
    reg_wb_mem: in std_logic;
    reg_wb_wb: in std_logic;
    data_A_forward_mem_en: out std_logic;
    data_B_forward_mem_en: out std_logic;
    data_A_forward_wb_en: out std_logic;
    data_B_forward_wb_en: out std_logic
   );
end forwarding_unit;

architecture Behavioral of forwarding_unit is
signal data_A_forward_mem_en_i: std_logic;
signal data_B_forward_mem_en_i: std_logic;

begin
	forwarding_logic: process ( reg_rs_ex, reg_rt_ex, reg_rd_mem, reg_wb_wb, reg_rd_wb, reg_wb_mem, data_A_forward_mem_en_i, data_B_forward_mem_en_i)
	begin
		data_A_forward_mem_en_i <= '0';
		data_A_forward_wb_en <= '0';
		data_B_forward_mem_en_i <= '0';
		data_B_forward_wb_en <= '0';
		
		
		--MEM hazard detection
		if (reg_wb_wb = '1') and (reg_rd_wb /= "00000")and (reg_rd_wb = reg_rt_ex)then
		  data_B_forward_wb_en <= '1';
		end if;
		
		if (reg_wb_wb = '1') and (reg_rd_wb /= "00000") and (reg_rd_wb = reg_rs_ex)then
		  data_A_forward_wb_en <= '1';
		end if;

		--EX hazard detection
		if (reg_wb_mem = '1')and (reg_rd_mem /= "00000") and (reg_rd_mem = reg_rt_ex)then 
		  data_B_forward_mem_en_i <= '1';
		end if;
		
		if (reg_wb_mem = '1') and (reg_rd_mem /= "00000")and (reg_rd_mem = reg_rs_ex) then 
		  data_A_forward_mem_en_i <= '1';
		end if;
end process;

  data_A_forward_mem_en <= data_A_forward_mem_en_i;
  data_B_forward_mem_en <= data_B_forward_mem_en_i;

end Behavioral;
