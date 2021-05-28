---------<<------------------------<<------------------------<<------------------------<<------------------------
library IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ENTITY VGA_Controller IS
GENERIC(	ADDRESS_SIZE	:	INTEGER	:= 10);
	PORT(	clk				:	IN	STD_LOGIC;
			reset				:	IN STD_LOGIC;
			start				:	IN STD_LOGIC;
			bot_left			:	IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			bot_right		:	IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			Hsync				: OUT STD_LOGIC;
			VSync				: OUT STD_LOGIC;
--			Address_X      : OUT STD_LOGIC_VECTOR(ADDRESS_SIZE-1 DOWNTO 0);
--			Address_Y      : OUT STD_LOGIC_VECTOR(ADDRESS_SIZE-1 DOWNTO 0);
			VGA_R          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			VGA_G          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			VGA_B          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
END ENTITY VGA_Controller;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ARCHITECTURE Control OF VGA_Controller IS
	SIGNAL BALL_Posx	                                          :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL BALL_PosY	                                          :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL LRAQ_Posx, RRAQ_Posx	                              :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL LRAQ_PosY, RRAQ_PosY	                              :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL rdx_address	                                       :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL rdy_address	                                       :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL count_wry   	                                       :	STD_LOGIC_VECTOR (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL bola_eff, raq_eff_L, raq_eff_R,estadoB  	            :	STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL bot_left_N                                           :  STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL bot_right_N                                          :  STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL Points                                               :  STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL rd_en			                                       :	STD_LOGIC;
	SIGNAL Data_Out		                                       :	STD_LOGIC;
	SIGNAL wr_en_a			                                       :	STD_LOGIC;
	SIGNAL wr_en			                                       :	STD_LOGIC;
	SIGNAL c0			                                          :	STD_LOGIC;
	SIGNAL Print_ot			                                    :	STD_LOGIC;
	SIGNAL En_printX , En_printY                                :  STD_LOGIC;
	SIGNAL En_print_bola,En_print_Lraq, En_print_Rraq           :  STD_LOGIC;
	SIGNAL Print_PL, Print_PR                                   :  STD_LOGIC;
	SIGNAL rdx_add_I	                                          :	INTEGER;
	SIGNAL rdy_add_I	                                          :	INTEGER;
	SIGNAL Posicionx	                                          :	INTEGER;
	SIGNAL PosicionY	                                          :	INTEGER;
	SIGNAL rst			                                          :	STD_LOGIC;
	SIGNAL LRAQI_Posx, RRAQI_Posx	                              :	INTEGER ;
	SIGNAL LRAQI_PosY, RRAQI_PosY	                              :	INTEGER ;
	SIGNAL Print_LRAQX, Print_LRAQY, Print_RRAQX, Print_RRAQY	:	STD_LOGIC;
	SIGNAL RAQ_IZ_BALL, RAQ_DE_BALL, Col_RAQ_BALL	            :	STD_LOGIC;
	SIGNAL WinL,WinR,LoseL,LoseR                                :  STD_LOGIC;
BEGIN
	rst	<= NOT reset;
	bot_right_N <= NOT bot_right;
	bot_left_N <= NOT bot_left;
--	   Address_X <= rdx_address;
--		Address_Y <= rdy_address;
		
		FSM:	ENTITY work.VGA_Sync
				PORT MAP(	
				clk			=>	c0,
								rst			=>	rst,
								AddressX		=> rdx_address,
								AddressY		=> rdy_address,
								Video_On		=>	rd_en,
								HSync_Out	=>	HSync,
								VSync_Out	=>	VSync);
	--Pll
		Pll:	ENTITY work.my_pll
				PORT MAP(	inclk0			=>	clk,
								c0			      =>	c0);
	-- Bola
	
	Ball: entity work.Bola
	GENERIC MAP(	ADDRESS_SIZE	=> 10,
	               Count_Size     => 20)
		PORT MAP(	clk		=> c0,
						rst		=> rst,
						start    => start,
						Vid_On   => rd_en,
						ball_ra  => Col_RAQ_BALL,
						ball_eff => bola_eff, 
						rdx_add 	=> rdx_address,
						rdy_add 	=> rdy_address,
						bola_xPos => BALL_Posx,
						bola_yPos => BALL_Posy,
						Point => Points,
						Print_ball => En_print_bola 
						);
						
	Raqueta_izq : entity work.Raqueta
	GENERIC MAP(	Sentido   => '0') --0 : Izquierda, 1 : Derecha
	PORT MAP( rst         => rst,
			 clk            => c0,
			 start          => start,
			 Bola_Pos_X     => BALL_Posx,
			 Bola_Pos_Y     => BALL_Posy,
			 BT_up          => bot_left_N(1),
			 BT_down        => bot_left_N(0),
			 Bola_ra        => RAQ_IZ_BALL,
			 Raqueta_Pos_X  => LRAQ_Posx,
			 Raqueta_Pos_Y  => LRAQ_Posy,
			 Est_Act        => raq_eff_L			 
	);
	
	Raqueta_der : entity work.Raqueta
	GENERIC MAP(	Sentido   => '1') --0 : Izquierda, 1 : Derecha
	PORT MAP( rst         => rst,
			 clk            => c0,
			 start          => start,
			 Bola_Pos_X     => BALL_Posx,
			 Bola_Pos_Y     => BALL_Posy,
			 BT_up          => bot_right_N(1),
			 BT_down        => bot_right_N(0),
			 Bola_ra        => RAQ_DE_BALL,
			 Raqueta_Pos_X  => RRAQ_Posx,
			 Raqueta_Pos_Y  => RRAQ_Posy,
			 Est_Act        => raq_eff_R			 
	);
	
	WinL<=LoseR;
	WinR<=LoseL;
	
	Point_Left: entity work.Points
	GENERIC MAP(	ADDRESS_SIZE	=> 4,
	               PosiLX     => 10,
						PosiLY     => 10)
		PORT MAP(	clk		=> c0,
						rst		=> rst,
						Win      => WinL,
						Point    => Points(0),
						rdx_add 	=> rdx_address,
						rdy_add 	=> rdy_address,
						Lose     => LoseL,
						Print_Point => Print_PL 
						);
						
	Point_Right: entity work.Points
	GENERIC MAP(	ADDRESS_SIZE	=> 4,
	               PosiLX     => 620,
						PosiLY     => 10)
		PORT MAP(	clk		=> c0,
						rst		=> rst,
						Win      => WinR,
						Point    => Points(1),
						rdx_add 	=> rdx_address,
						rdy_add 	=> rdy_address,
						Lose     => LoseR,
						Print_Point => Print_PR 
						);
	
Col_RAQ_BALL <= RAQ_IZ_BALL OR RAQ_DE_BALL;
--	
--	bola_eff(0) <= raq_eff_L(0) OR raq_eff_R(0);
--	bola_eff(1) <= raq_eff_L(1) OR raq_eff_R(1);
--	bola_eff(2) <= raq_eff_L(2) OR raq_eff_R(2);

--bola_eff <= (NOT raq_eff_L);

	bola_eff <= (raq_eff_L) WHEN RAQ_IZ_BALL = '1' ELSE
					( raq_eff_R) WHEN RAQ_DE_BALL = '1' ELSE
					"011";
--								
		rdx_add_I <= to_integer(unsigned(rdx_address));
		rdy_add_I <= to_integer(unsigned(rdy_address));
--								
--	   Posicionx <= 100;
--		PosicionY <= 400;
--		
--		--Imprimir
--		En_printX <= '1' WHEN (rdx_address_I > Posicionx) AND (rdx_address_I < Posicionx+20) ELSE
--							'0';	
--		En_printY <= '1' WHEN (rdy_address_I > PosicionY) AND (rdy_address_I < PosicionY+10)  ELSE
--							'0';	
--		EN_print <=En_printX AND En_printY;

-- MAPEO DE RAQUETA IZQUIERDA
		LRAQI_Posx <= to_integer(unsigned(LRAQ_Posx));
		LRAQI_Posy <= to_integer(unsigned(LRAQ_Posy));
		
		Print_LRAQX <= '1' WHEN (rdx_add_I > LRAQI_Posx) AND (rdx_add_I < LRAQI_Posx+18) ELSE
							'0';	
		Print_LRAQY <= '1' WHEN (rdy_add_I > LRAQI_Posy) AND (rdy_add_I < LRAQI_Posy+150)  ELSE
							'0';
      En_print_Lraq <= Print_LRAQX AND Print_LRAQY;
		
-- MAPEO DE RAQUETA DERECHA
		RRAQI_Posx <= to_integer(unsigned(RRAQ_Posx));
		RRAQI_Posy <= to_integer(unsigned(RRAQ_Posy));
		
		Print_RRAQX <= '1' WHEN (rdx_add_I > RRAQI_Posx) AND (rdx_add_I < RRAQI_Posx+18) ELSE
							'0';	
		Print_RRAQY <= '1' WHEN (rdy_add_I > RRAQI_Posy) AND (rdy_add_I < RRAQI_Posy+150)  ELSE
							'0';
      En_print_Rraq <= Print_RRAQX AND Print_RRAQY;

      Print_ot <=(En_print_bola OR En_print_Lraq OR En_print_Rraq OR Print_PL OR Print_PR) AND  rd_en;
			
      VGA_R		<=	"0000" WHEN Print_ot = '1' ELSE
	                  "0000";
		VGA_G		<=	"1111" WHEN Print_ot = '1' ELSE
	                  "0000";
		VGA_B		<=	"1111" WHEN Print_ot = '1' ELSE
	                  "0000";			
END ARCHITECTURE Control;