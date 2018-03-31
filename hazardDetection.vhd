
library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection is
    port ( 
	 mem_read_ex: in std_logic;
	 reg_rt_ex: in std_logic_vector (4 downto 0);
	 reg_rs_id: in std_logic_vector (4 downto 0);
	 reg_rt_id: in std_logic_vector (4 downto 0);
	 insert_stall: out std_logic
   );
end hazard_detection;

architecture behavioral of hazard_detection is

begin
  process (reg_rt_ex, reg_rs_id, reg_rt_id, mem_read_ex) 
  begin 
    insert_stall <= '0';
    --Hazard check
    if mem_read_ex = '1' then
      if reg_rt_ex = reg_rt_id or reg_rt_ex = reg_rs_id then
        --Stall if hazard
        insert_stall <= '1';
      end if;
    end if;
  end process;
end behavioral;