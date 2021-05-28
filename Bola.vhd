---------<<------------------------<<------------------------<<------------------------<<------------------------
library IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ENTITY Bola IS
GENERIC(	ADDRESS_SIZE	:	INTEGER	:= 10;
         Count_Size	   :	INTEGER	:= 20);
	PORT(	clk				:	IN	STD_LOGIC;
			rst				:	IN STD_LOGIC;
			start				:	IN STD_LOGIC;
			Vid_On   		:	IN STD_LOGIC;
			ball_ra        :	IN STD_LOGIC;
			ball_eff       :  IN	STD_LOGIC_VECTOR (2 DOWNTO 0);
			rdx_add        :  IN	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
			rdy_add        :  IN	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
			bola_xPos      :  OUT STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
			bola_yPos      :  OUT STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
			Point          : OUT STD_LOGIC_VECTOR (1 DOWNTO 0):="00";
			Print_ball     : OUT STD_LOGIC
			);
END ENTITY Bola;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ARCHITECTURE Bola_arch OF Bola IS

	TYPE state IS ( Iniciar, Move_Up_R, W25ms_Up_R, Border_Up_R, Move_Up_L, W25ms_Up_L, Border_Up_L,
	                Move_Dw_R, W25ms_Dw_R, Border_Dw_R, Move_Dw_L, W25ms_Dw_L, Border_Dw_L, 
						 Move_R, W25ms_R, Border_R, Move_L, W25ms_L, Border_L);
	SIGNAL pr_state, nx_state: state;
	
	
	SIGNAL D_X, D_Y, Q_X, Q_Y	     :	STD_LOGIC_VECTOR (ADDRESS_SIZE DOWNTO 0);
	SIGNAL Max_tick, Max_rand	     :	STD_LOGIC;
	SIGNAL ena_REG			           :	STD_LOGIC;
	SIGNAL Ena_ct,clear_ct	        :	STD_LOGIC;
	SIGNAL printx,printy 	        :	STD_LOGIC;
	SIGNAL ZEROS,count_WT           :   STD_LOGIC_VECTOR (Count_Size-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL count_rand               :   STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL rdx_add_I	              :	INTEGER;
	SIGNAL rdy_add_I	              :	INTEGER;
	SIGNAL Posx	                    :	INTEGER;
	SIGNAL PosY	                    :	INTEGER;
	SIGNAL Qx_I                     :	INTEGER;
	SIGNAL QY_I	                    :	INTEGER;
--	CONSTANT wait_time              :   INTEGER:=625000;--25ms --25000 equivale a 1ms
	--testbench
	CONSTANT wait_time              :   INTEGER:=125000;--25ms --25000 equivale a 1ms
	CONSTANT Limit_x_screen         :   INTEGER:=639;--640 pixeles
	CONSTANT Limit_y_screen         :   INTEGER:=461;--460 pixeles

BEGIN

    
	rdx_add_I <= to_integer(unsigned(rdx_add));
	rdy_add_I <= to_integer(unsigned(rdy_add));
	
	
	Counter_random: entity work.Univ_counter
	GENERIC MAP(	N	=> ADDRESS_SIZE-7)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> start,
						syn_clr	=> Max_rand,
						load		=> '0',
						up			=> '1',
						d			=> "000",
						Counter	=> count_rand
						);
   Max_rand	<= '1' WHEN count_rand = "111" ELSE 
             '0';
	
						
	Counter_wait_time: entity work.Univ_counter
	GENERIC MAP(	N	=> Count_Size)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_ct,
						syn_clr	=> clear_ct,
						load		=> '0',
						up			=> '1',
						d			=> ZEROS,
						Counter	=> count_WT
						);
							
	Max_tick <= '1' WHEN count_WT = std_logic_vector(to_unsigned(wait_time, count_WT'length)) ELSE 
               '0';	
					
	reg_x: entity work.my_reg
	GENERIC MAP (	MAX_WIDTH	=> ADDRESS_SIZE+1)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						en 		=> ena_REG AND start,
						d			=> D_X,
						q			=> Q_X
						);
						
	D_X  <= std_logic_vector(to_signed(Posx, D_X'length));
	Qx_I <= to_integer(unsigned(Q_X));
	bola_xPos <= Q_X(9 DOWNTO 0);
						
	reg_y: entity work.my_reg
	GENERIC MAP (	MAX_WIDTH	=> ADDRESS_SIZE+1)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						en 		=> ena_REG AND start,
						d			=> D_Y,
						q			=> Q_Y
						);
		
	D_Y <= std_logic_vector(to_signed(Posy, D_Y'length));
	Qy_I <= to_integer(signed(Q_Y));
	bola_yPos <= Q_Y(9 DOWNTO 0);
		
-- SECCION SECUENCIAL--
	PROCESS (rst, clk)
	BEGIN 
		IF (rst='1') THEN 
			pr_state <= Iniciar;
		ELSIF (rising_edge(clk)) THEN 
			pr_state <= nx_state;
		END IF;
	END PROCESS;
--SECCION COMBINACIONAL--
	PROCESS( pr_state, Qx_I, Qy_I, count_rand, Max_tick, Vid_On,ball_eff,ball_ra)
	BEGIN
		CASE pr_state IS
			WHEN Iniciar =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			--Mitad pantalla
			Posx	<=300;
         PosY	<=240;
			
				IF (count_rand = "000") THEN 
					nx_state <= Move_Dw_L;
				ELSIF (count_rand = "001") THEN  
					nx_state <= Move_Dw_R;
				ELSIF (count_rand = "100") THEN  
					nx_state <= Move_R;
				ELSIF (count_rand = "010") THEN  
					nx_state <= Move_L;
				ELSIF (count_rand = "111") THEN  
					nx_state <= Move_Up_R;
			   ELSE
				   nx_state <= Move_Up_L;
				END IF;
				
--testbench
--			Posx	<=500;
--			PosY	<=80;
--			nx_state <= Move_R;

				
			WHEN Move_Up_R =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			Posx	<=Qx_I +1 ;
         PosY	<=Qy_I -1 ;
			
			nx_state  <= W25ms_Up_R;
				
			WHEN W25ms_Up_R =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
				IF (Max_tick = '1') THEN 
					nx_state <= Border_Up_R;
					Ena_Ct    <= '1';
					Clear_Ct  <= '1';
			   ELSE
				   nx_state <= W25ms_Up_R;
				END IF;
			
			WHEN Border_Up_R =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			IF (ball_ra = '1') THEN
				IF (ball_eff = "000") THEN
					nx_state <= Move_L;
				ELSIF (ball_eff = "001") THEN
					nx_state <=  Move_Up_L;
				ELSIF (ball_eff = "010") THEN
					nx_state <=  Move_Dw_L;
				ELSIF (ball_eff = "101") THEN
					nx_state <=  Move_Dw_R;
				ELSIF (ball_eff = "110") THEN
					nx_state <=  Move_Up_R;	
				ELSIF (ball_eff = "111") THEN
					nx_state <=  Move_R;
				ELSE
				nx_state <=  Move_Up_L;
				END IF;			
			ELSE
				IF (Qx_I >= Limit_x_screen AND Qy_I > 0) THEN 
					nx_state <= Iniciar;
					Point(0) <= '1';
				ELSIF (Qx_I >= Limit_x_screen AND Qy_I <= 0) THEN  
					nx_state <= Iniciar;
					Point(0) <= '1';
				ELSIF (Qx_I < Limit_x_screen AND Qy_I <= 0) THEN  
					nx_state <= Move_Dw_R;
					ena_REG   <= '1';
					Posx	<=Qx_I ;
               PosY	<=Qy_I+1 ;
					Point <= "00";
			   ELSE
				   nx_state <= Move_Up_R;
					Point <= "00";
				END IF;
				END IF;
			
			WHEN Move_Up_L =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			Posx	<=Qx_I -1 ;
         PosY	<=Qy_I -1 ;
			
			nx_state  <= W25ms_Up_L;
				
			WHEN W25ms_Up_L =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
				IF (Max_tick = '1') THEN 
					nx_state <= Border_Up_L;
					Ena_Ct    <= '1';
					Clear_Ct  <= '1';
			   ELSE
				   nx_state <= W25ms_Up_L;
				END IF;
			
			WHEN Border_Up_L =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			IF (ball_ra = '1') THEN
			IF (ball_eff = "000") THEN
				nx_state <= Move_L;
			ELSIF (ball_eff = "001") THEN
				nx_state <=  Move_Up_L;
			ELSIF (ball_eff = "010") THEN
				nx_state <=  Move_Dw_L;
			ELSIF (ball_eff = "101") THEN
				nx_state <=  Move_Dw_R;
			ELSIF (ball_eff = "110") THEN
				nx_state <=  Move_Up_R;	
			ELSIF (ball_eff = "111") THEN
				nx_state <=  Move_R;
		   ELSE
			nx_state <=  Move_Dw_R;
	      END IF;			
			ELSE
				IF (Qx_I <= 0 AND Qy_I > 0) THEN 
					nx_state <= Iniciar;
					Point(1) <= '1';
					ena_REG   <= '1';
				ELSIF (Qx_I <= 0 AND Qy_I <= 0) THEN  
					nx_state <= Iniciar;
					Point(1) <= '1';
				ELSIF (Qx_I > 0 AND Qy_I <= 0) THEN  
					nx_state <= Move_Dw_L;
					ena_REG   <= '1';
					Posx	<=Qx_I ;
               PosY	<=Qy_I+1 ;
					Point <= "00";
			   ELSE
				   nx_state <= Move_Up_L;
					Point <= "00";
				END IF;
				END IF;

			WHEN Move_Dw_L =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			Posx	<=Qx_I -1 ;
         PosY	<=Qy_I +1 ;
			
			nx_state  <= W25ms_Dw_L;
				
			WHEN W25ms_Dw_L =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
				IF (Max_tick = '1') THEN 
					nx_state <= Border_Dw_L;
					Ena_Ct    <= '1';
					Clear_Ct  <= '1';
			   ELSE
				   nx_state <= W25ms_Dw_L;
				END IF;
			
			WHEN Border_Dw_L =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
			IF (ball_ra = '1') THEN
			IF (ball_eff = "000") THEN
				nx_state <= Move_L;
			ELSIF (ball_eff = "001") THEN
				nx_state <=  Move_Up_L;
			ELSIF (ball_eff = "010") THEN
				nx_state <=  Move_Dw_L;
			ELSIF (ball_eff = "101") THEN
				nx_state <=  Move_Dw_R;
			ELSIF (ball_eff = "110") THEN
				nx_state <=  Move_Up_R;	
			ELSIF (ball_eff = "111") THEN
				nx_state <=  Move_R;
		   ELSE
			nx_state <=  Move_Up_L;
	      END IF;			
			ELSE
				IF (Qx_I <= 0 AND Qy_I < Limit_y_screen) THEN 
					nx_state <= Iniciar;
					Point(1) <= '1';
				ELSIF (Qx_I <= 0 AND Qy_I >= Limit_y_screen) THEN  
					nx_state <= Iniciar;
					Point(1) <= '1';
				ELSIF (Qx_I > 0 AND Qy_I >= Limit_y_screen) THEN  
					nx_state <= Move_Up_L;
					ena_REG   <= '1';
					Posx	<=Qx_I+1 ;
               PosY	<=Qy_I; 
					Point <= "00";
			   ELSE
				   nx_state <= Move_Dw_L;
					Point <= "00";
				END IF;
				END IF;
			
			WHEN Move_Dw_R =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			Posx	<=Qx_I +1 ;
         PosY	<=Qy_I +1 ;
			
			nx_state  <= W25ms_Dw_R;
				
			WHEN W25ms_Dw_R =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
				IF (Max_tick = '1') THEN 
					nx_state <= Border_Dw_R;
					Ena_Ct    <= '1';
					Clear_Ct  <= '1';
			   ELSE
				   nx_state <= W25ms_Dw_R;
				END IF;
			
			WHEN Border_Dw_R =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
			IF (ball_ra = '1') THEN
				IF (ball_eff = "000") THEN
					nx_state <= Move_L;
				ELSIF (ball_eff = "001") THEN
					nx_state <=  Move_Up_L;
				ELSIF (ball_eff = "010") THEN
					nx_state <=  Move_R;
				ELSIF (ball_eff = "101") THEN
					nx_state <=  Move_Dw_R;
				ELSIF (ball_eff = "110") THEN
					nx_state <=  Move_Up_R;	
				ELSIF (ball_eff = "111") THEN
					nx_state <=  Move_Dw_L;
				ELSE
				nx_state <= Move_L;
				END IF;			
			ELSE
				IF (Qx_I >= Limit_x_screen AND Qy_I < Limit_y_screen) THEN 
					nx_state <= Iniciar;
					Point(0) <= '1';
				ELSIF (Qx_I >= Limit_x_screen AND Qy_I >= Limit_y_screen) THEN  
					nx_state <= Iniciar;
					Point(0) <= '1';
				ELSIF (Qx_I < Limit_x_screen AND Qy_I >= Limit_y_screen) THEN  
					nx_state <= Move_Up_R;
					Point <= "00";
			   ELSE
				   nx_state <= Move_Dw_R;
					Point <= "00";
				END IF;
				END IF;
				
			WHEN Move_R =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			Posx	<=Qx_I +1 ;
         PosY	<=Qy_I ;
			
			nx_state  <= W25ms_R;
				
			WHEN W25ms_R =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
				IF (Max_tick = '1') THEN 
					nx_state <= Border_R;
					Ena_Ct    <= '1';
					Clear_Ct  <= '1';
			   ELSE
				   nx_state <= W25ms_R;
				END IF;
			
			WHEN Border_R =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;			
			
			IF (ball_ra = '1') THEN
				IF (ball_eff = "000") THEN
					nx_state <= Move_L;
				ELSIF (ball_eff = "001") THEN
					nx_state <=  Move_Up_L;
				ELSIF (ball_eff = "010") THEN
					nx_state <=  Move_Dw_L;
				ELSIF (ball_eff = "101") THEN
					nx_state <=  Move_Dw_R;
				ELSIF (ball_eff = "110") THEN
					nx_state <=  Move_Up_R;	
				ELSIF (ball_eff = "111") THEN
					nx_state <=  Move_L;
		   ELSE
			nx_state <= Move_L;
	      END IF;			
			ELSE
				IF (Qx_I >= Limit_x_screen AND Qy_I > 0) THEN 
					nx_state <= Iniciar;
					Point(0) <= '1';
				ELSIF (Qx_I >= Limit_x_screen AND Qy_I <= 0) THEN  
					nx_state <= Iniciar;
					Point(0) <= '1';
				ELSIF (Qx_I < Limit_x_screen AND Qy_I <= 0) THEN  
					nx_state <= Iniciar;
					Point <= "00";
					
			   ELSE
				   nx_state <= Move_R;
					Point <= "00";
				END IF;
				END IF;
				
			WHEN Move_L =>
			Point <= "00";
			Ena_Ct    <= '0';
			ena_REG   <= '1';
			Clear_Ct  <= '0';
			Posx	<=Qx_I -1 ;
         PosY	<=Qy_I ;
			
			nx_state  <= W25ms_L;
				
			WHEN W25ms_L =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
				IF (Max_tick = '1') THEN 
					nx_state <= Border_L;
					Ena_Ct    <= '1';
					Clear_Ct  <= '1';
			   ELSE
				   nx_state <= W25ms_L;
				END IF;
			
			WHEN Border_L =>
			Point <= "00";
			Ena_Ct    <= '1';
			ena_REG   <= '0';
			Clear_Ct  <= '0';
			Posx	<=Qx_I ;
			Posy	<=Qy_I ;
			
			IF (ball_ra = '1') THEN
				IF (ball_eff = "000") THEN
					nx_state <= Move_R;
				ELSIF (ball_eff = "001") THEN
					nx_state <=  Move_Up_L;
				ELSIF (ball_eff = "010") THEN
					nx_state <=  Move_Dw_L;
				ELSIF (ball_eff = "101") THEN
					nx_state <=  Move_Dw_R;
				ELSIF (ball_eff = "110") THEN
					nx_state <=  Move_Up_R;	
				ELSIF (ball_eff = "111") THEN
					nx_state <=  Move_R;
				ELSE
				nx_state <=  Move_R;
				END IF;			
					ELSE
				IF (Qx_I <= 0 AND Qy_I > 0) THEN 
					nx_state <= Iniciar;
					Point(1) <= '1';
					ena_REG   <= '1';
				ELSIF (Qx_I <= 0 AND Qy_I <= 0) THEN  
					nx_state <= Iniciar;
					Point(1) <= '1';
				ELSIF (Qx_I > 0 AND Qy_I <= 0) THEN  
					nx_state <= Iniciar;
					Point <= "00";
					
			   ELSE
				   nx_state <= Move_L;
					Point <= "00";
				END IF;
			END IF;
			
			END CASE;

		END PROCESS;
 

		--Mapeo Bola
		printx <= '1' WHEN (rdx_add_I > Qx_I) AND (rdx_add_I < Qx_I+18) ELSE
							'0';	
		printy <= '1' WHEN (rdy_add_I > Qy_I) AND (rdy_add_I < Qy_I+18)  ELSE
							'0';	
		Print_ball <=printx AND printy;
			
END ARCHITECTURE Bola_arch;