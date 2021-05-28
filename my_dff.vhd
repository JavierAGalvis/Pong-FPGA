LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
-------------------------------------
ENTITY my_dff IS
	PORT (clk	:	IN		STD_LOGIC;
			rst	:	IN		STD_LOGIC;
			en 	:	IN		STD_LOGIC;
			d 		: 	IN		STD_LOGIC;
			q 		:	OUT	STD_LOGIC);
END ENTITY my_dff;
-------------------------------------
ARCHITECTURE rtl OF my_dff IS
BEGIN
	PROCESS(clk, rst,en,d)
	BEGIN
		IF(rst = '1') THEN
			q <= '0';
		ELSIF (en = '1') THEN
			IF (rising_edge(clk)) THEN
				q <= d;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;