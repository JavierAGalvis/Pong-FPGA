LIBRARY IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
-----------------------------------------------------------------
ENTITY Univ_counter IS
	GENERIC(	N			:	INTEGER	:= 5);
		PORT(	clk		:	IN		STD_LOGIC;
				rst		:	IN		STD_LOGIC;
				ena		:	IN		STD_LOGIC;
				syn_clr	:	IN		STD_LOGIC;
				load		:	IN		STD_LOGIC;
				up			:	IN		STD_LOGIC;
				d			:	IN		STD_LOGIC_VECTOR(N-1 DOWNTO 0);
				Counter	:	OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0));
				
END ENTITY Univ_counter;
-----------------------------------------------------------------
ARCHITECTURE circuit OF Univ_counter IS
	CONSTANT ONES		:	UNSIGNED (N-1 DOWNTO 0)	:=	(OTHERS	=>	'1');
	CONSTANT ZEROS		:	UNSIGNED (N-1 DOWNTO 0)	:=	(OTHERS	=>	'0');

	
	SIGNAL	cnt_s		:	UNSIGNED (N-1 DOWNTO 0);
	SIGNAL	cnt_nxt	:	UNSIGNED (N-1 DOWNTO 0);
	
BEGIN
	--------------------Count Next Process-----------------------
	cnt_nxt	<=		(OTHERS	=>	'0')	WHEN	syn_clr	= '1'					ELSE
						unsigned(d)			WHEN	load		= '1'					ELSE
						cnt_s + 1			WHEN	(ena = '1' and up = '1')	ELSE
						cnt_s - 1			WHEN	(ena = '1' and up = '0')	ELSE
						cnt_s;
						
	-------------------Counter DFF Process--------------------
	PROCESS (clk, rst)
		VARIABLE temp	:	UNSIGNED (N-1 DOWNTO 0);
	BEGIN
		IF(rst = '1') THEN
			temp	:=	(OTHERS	=>	'0');
		ELSIF (rising_edge(clk)) THEN
			IF (ena = '1') THEN
				temp	:=	cnt_nxt;
			END IF;
		END IF;
		Counter	<=	STD_LOGIC_VECTOR(temp);
		cnt_s		<=	temp;
	END PROCESS;
	
END ARCHITECTURE circuit;