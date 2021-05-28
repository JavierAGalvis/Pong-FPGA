LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
-------------------------------------
ENTITY my_reg IS
   GENERIC (MAX_WIDTH : INTEGER := 10);
	PORT (clk	:	IN		STD_LOGIC;
			rst	:	IN		STD_LOGIC;
			en 	:	IN		STD_LOGIC;
			d 		: 	IN		STD_LOGIC_VECTOR(MAX_WIDTH-1 DOWNTO 0);
			q 		:	OUT	STD_LOGIC_VECTOR(MAX_WIDTH-1 DOWNTO 0)
			);
END ENTITY my_reg;
-------------------------------------
ARCHITECTURE rtl OF my_reg IS
BEGIN
	reg_process: PROCESS(clk, rst, en, d)
	BEGIN
		IF(rst = '1') THEN
			q <= (OTHERS => '0');
		ELSIF (en = '1') THEN
			IF (rising_edge(clk)) THEN
				q <= d;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE rtl;