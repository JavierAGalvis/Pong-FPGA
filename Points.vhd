---------<<------------------------<<------------------------<<------------------------<<------------------------
library IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ENTITY Points IS
GENERIC(	ADDRESS_SIZE	:	INTEGER	:= 4;
         PosiLX	      :	INTEGER	:= 10;
			PosiLY         : INTEGER   :=10);
	PORT(	clk				:	IN	STD_LOGIC;
			rst				:	IN STD_LOGIC;
			Win				:	IN STD_LOGIC;
			Point          :	IN STD_LOGIC;
			rdx_add        :  IN	STD_LOGIC_VECTOR (9 DOWNTO 0);
			rdy_add        :  IN	STD_LOGIC_VECTOR (9 DOWNTO 0);
			Lose           : OUT STD_LOGIC;
			Print_Point    : OUT STD_LOGIC
			);
END ENTITY Points;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ARCHITECTURE Points_arch OF Points IS

	
	
	SIGNAL D_L, Q_L	     :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL Seg_L,P_S_L 	           :	STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL rdx_add_I	              :	INTEGER;
	SIGNAL rdy_add_I	              :	INTEGER;
	SIGNAL PoL	                    :	INTEGER;
	SIGNAL QL_I                     :	INTEGER;
	SIGNAL LoseS 	                 :	STD_LOGIC;

BEGIN

   rdx_add_I <= to_integer(unsigned(rdx_add));
   rdy_add_I <= to_integer(unsigned(rdy_add));
	Lose<=LoseS;

	Points_L: entity work.my_reg
	GENERIC MAP (	MAX_WIDTH	=> ADDRESS_SIZE)
		PORT MAP(	clk		=> clk,
						rst		=> rst OR LoseS OR Win,
						en 		=> Point,
						d			=> D_L,
						q			=> Q_L
						);
						
	D_L  <= std_logic_vector(to_signed(PoL, D_L'length));
	QL_I <= to_integer(unsigned(Q_L));
   PoL <= QL_I+1 WHEN Point='1' ELSE QL_I;
	LoseS <= '1' WHEN (PoL=11) ELSE '0';
	
	WITH Q_L SELECT 
  Seg_L <=
  "1000000" WHEN "0000",--0
  "1111001" WHEN "0001",--1
  "0100100" WHEN "0010",--2
  "0110000" WHEN "0011",--3
  "0011001" WHEN "0100",--4
  "0010010" WHEN "0101",--5
  "0000010" WHEN "0110",--6
  "1111000" WHEN "0111",--7
  "0000000" WHEN "1000",--8
  "0010000" WHEN "1001",--9
  "0001000" WHEN "1010",--A
  "0000110" WHEN "1011",--E
  "0100100" WHEN "1100",--12
  "0110000" WHEN "1101",--13
  "0011001" WHEN "1110",--14
  "1000110" WHEN "1111";--C
							
-- Segmento Izquierda
 -- Seg0
 P_S_L(0) <= '1' WHEN ((rdx_add_I > PosiLX) AND (rdx_add_I < PosiLX+12) 
  AND (rdy_add_I > PosiLY) AND (rdy_add_I < PosiLY+2)) AND (Seg_L(0) = '0')  
  ELSE '0';
 -- Seg1
 P_S_L(1) <= '1' WHEN ((rdx_add_I > PosiLX+10) AND (rdx_add_I < PosiLX+12) AND 
  (rdy_add_I > PosiLY) AND (rdy_add_I < PosiLY+12)) AND (Seg_L(1) = '0') 
  ELSE '0';
   -- Seg2
 P_S_L(2) <= '1' WHEN ((rdx_add_I > PosiLX+10) AND (rdx_add_I < PosiLX+12) AND
  (rdy_add_I > PosiLY+11) AND (rdy_add_I < PosiLY+22)) AND (Seg_L(2) = '0')
  ELSE '0';
   -- Seg3
 P_S_L(3) <= '1' WHEN ((rdx_add_I > PosiLX) AND (rdx_add_I < PosiLX+12) AND
  (rdy_add_I > PosiLY+20) AND (rdy_add_I < PosiLY+22)) AND (Seg_L(3) = '0')
  ELSE '0';
 P_S_L(4) <= -- Seg4
  '1' WHEN ((rdx_add_I > PosiLX) AND (rdx_add_I < PosiLX+2) AND 
  (rdy_add_I > PosiLY+11) AND (rdy_add_I < PosiLY+22)) AND (Seg_L(4) = '0')
  ELSE '0';
   -- Seg5
 P_S_L(5) <='1' WHEN ((rdx_add_I > PosiLX) AND (rdx_add_I < PosiLX+2) AND 
  (rdy_add_I > PosiLY) AND (rdy_add_I < PosiLY+12)) AND (Seg_L(5) = '0') 
  ELSE '0';
   -- Seg6
 P_S_L(6) <='1' WHEN ((rdx_add_I > PosiLX) AND (rdx_add_I < PosiLX+12) AND
  (rdy_add_I > PosiLY+10) AND (rdy_add_I < PosiLY+12)) AND (Seg_L(6) = '0')
  ELSE '0';
													
Print_Point <= P_S_L(0) OR P_S_L(1) OR P_S_L(2) OR P_S_L(3) OR P_S_L(4) OR P_S_L(5) OR P_S_L(6);


END ARCHITECTURE Points_arch;