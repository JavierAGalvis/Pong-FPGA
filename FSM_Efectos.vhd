LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY FSM_Efectos IS 
   GENERIC(	Sentido			:	STD_LOGIC	:= '0');
	PORT ( rst         :IN STD_LOGIC;
			 clk         :IN STD_LOGIC;
			 Bola_Pos_X  :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Bola_Pos_Y  :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Raqueta_Pos :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Colision    : OUT STD_LOGIC;
			 Est_Act     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)			 
	);
END ENTITY FSM_Efectos;

ARCHITECTURE FSM OF FSM_Efectos IS
	TYPE state IS ( Iniciar, Golpear, Arriba, Medio, Abajo, WaitRefresh);
	SIGNAL pr_state, nx_state: state;
	SIGNAL parte                                       : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL Est_Out                                     : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL golpe,Actu_Est,Limit_Inf, golpe_R, golpe_L  : STD_LOGIC;
	SIGNAL LG_UP,LG_D               : STD_LOGIC;
	SIGNAL RG_UP,RG_D               : STD_LOGIC;
	SIGNAL count_WT,ZEROS                              : STD_LOGIC_VECTOR(19 DOWNTO 0):= (OTHERS => '0');
	SIGNAL Ena_ctWT,clear_ctWT,Max_tick_WT             : STD_LOGIC;
	SIGNAL Bola_X,Bola_Y,Raqueta,Limit_X_R             : INTEGER;
	SIGNAL Limit_Y_R,Limit_U_R,Limit_D_R               : INTEGER;
	SIGNAL Limit_Bola_Y	                              : INTEGER;--18 pixeles
--	CONSTANT wait_time                                 : INTEGER:=625000;--25ms --25000 equivale a 1ms
	--testbench
	CONSTANT wait_time                                 : INTEGER:=2;--25ms --25000 equivale a 1ms
	CONSTANT Limit_X_R_I	                              : INTEGER:=17;--18 pixeles
	CONSTANT Limit_X_R_D	                              : INTEGER:=603;--18 pixeles
BEGIN

Colision <= golpe;
Limit_Bola_Y <= Bola_Y+17;

--Sentido raueta
Limit_X_R<=	Limit_X_R_I WHEN Sentido = '0' ELSE
	         Limit_X_R_D;
				
golpe <=	golpe_L WHEN Sentido = '0' ELSE
	      golpe_R;
--Conversión
Raqueta <= to_integer(unsigned(Raqueta_Pos));
Bola_X  <= to_integer(unsigned(Bola_Pos_X));
Bola_Y  <= to_integer(unsigned(Bola_Pos_Y));

--Limites raqueta
Limit_U_R <= Raqueta+50;
Limit_D_R <= Raqueta+100;
Limit_Y_R <= Raqueta+150;

--Habilitar actualización
Est_Act		<=	Est_Out       WHEN ( (NOT Sentido) ) = '1' ELSE
				   (NOT Est_Out) WHEN ( Sentido ) = '1'       ELSE
	            "011";--NONE
					
--Desición de golpe
--LG_UP <=	'1' WHEN (((Raqueta < Bola_Y) AND (Bola_Y<Limit_Y_R))AND((Limit_X_R>=Bola_X))) ELSE
--	            '0';
--
--LG_D 
--
--RG_UP <=	'1' WHEN (((Raqueta < Bola_Y) AND (Bola_Y<Limit_Y_R))AND((Limit_X_R<=Bola_X) )) ELSE
--	            '0';
--
--RG_D

golpe_L		   <=	'1' WHEN (((Raqueta < Limit_Bola_Y) AND (Bola_Y<Limit_Y_R)) AND ((Limit_X_R>=Bola_X))) ELSE
	            '0';
golpe_R		   <=	'1' WHEN (((Raqueta < Limit_Bola_Y) AND (Bola_Y<Limit_Y_R)) AND ((Limit_X_R<=Bola_X) )) ELSE
	            '0';
					
--Parte de la raqueta
parte		   <=	"00" WHEN (Bola_Y<Limit_U_R) OR (Bola_Y=Limit_U_R) ELSE  --Arriba
					"01" WHEN (Limit_U_R<Bola_Y) AND (Limit_Bola_Y<Limit_D_R) ELSE --Medio
	            "10";                                                    --Abajo
					
--Contador refresco					
Counter_25ms: entity work.Univ_counter
	GENERIC MAP(	N	=> 20)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_ctWT,
						syn_clr	=> clear_ctWT,
						load		=> '0',
						up			=> '1',
						d			=> ZEROS,
						Counter	=> count_WT
						);
						

	Max_tick_WT <= '1' WHEN count_WT = std_logic_vector(to_unsigned(wait_time, count_WT'length)) ELSE 
                  '0';

--FSM-----------------------------------

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
	PROCESS(golpe, parte, Max_tick_WT , pr_state)
	BEGIN
		CASE pr_state IS
			WHEN Iniciar =>
			Actu_Est<='0';
			Ena_ctWT<='1';
			clear_ctWT<='1';
			Est_Out<="011";--Null
			IF (golpe = '1') THEN
				nx_state <= Golpear;
			ELSE 
				nx_state <= Iniciar;
			END IF;
			  
			WHEN Golpear =>
			Actu_Est<='0';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			Est_Out<="011";--Null
			IF (parte =  "00") THEN   --U
				nx_state <= Arriba;
			ELSIF (parte =  "01") THEN--M
				nx_state <= Medio;
			ELSE                      --D
			   nx_state <= Abajo;
			END IF;
		
			WHEN Arriba =>
			Actu_Est<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			Est_Out<="110";--Arriba-Derecha
			   
				nx_state <= WaitRefresh;
				
			WHEN Medio =>
			Actu_Est<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			Est_Out<="111";--Derecha
			   
				nx_state <= WaitRefresh;
				
			WHEN Abajo =>
			Actu_Est<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			Est_Out<="101";--Abajo-Derecha
			   
				nx_state <= WaitRefresh;
		
			WHEN WaitRefresh =>
			Actu_Est<='0';
			Ena_ctWT<='1';
			clear_ctWT<='0';
			--Est_Out<="011";--Null
			IF (Max_tick_WT = '1') THEN 
			   nx_state <= Iniciar;
			ELSE 
				nx_state <= WaitRefresh;
			END IF;
		END CASE;
	END PROCESS;
END ARCHITECTURE;