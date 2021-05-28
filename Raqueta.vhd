LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Raqueta IS 
	GENERIC(	Sentido   :	STD_LOGIC	:= '0'); --0 : Izquierda, 1 : Derecha
	PORT ( rst            :IN STD_LOGIC;
			 clk            :IN STD_LOGIC;
			 start			 :IN STD_LOGIC;
			 Bola_Pos_X     :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Bola_Pos_Y     :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 BT_up          :IN STD_LOGIC;
			 BT_down        :IN STD_LOGIC;
			 Bola_ra        :OUT STD_LOGIC;
			 Raqueta_Pos_X  :OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Raqueta_Pos_Y  :OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Est_Act        :OUT STD_LOGIC_VECTOR(2 DOWNTO 0)			 
	);
END ENTITY Raqueta;

ARCHITECTURE arch OF Raqueta IS
   TYPE state IS ( Iniciar, Limite_up, Limite_down, Arriba, Abajo, Refresh);
	SIGNAL pr_state, nx_state: state;
	SIGNAL ZEROSR                          : STD_LOGIC_VECTOR(9 DOWNTO 0):= (OTHERS => '0');
	SIGNAL Raqueta_Pos                     : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL count_WT,ZEROSC                 : STD_LOGIC_VECTOR(19 DOWNTO 0):= (OTHERS => '0');
	SIGNAL Ena_ctWT,clear_ctWT,Max_tick_WT : STD_LOGIC;
	SIGNAL Ena_countR                      : STD_LOGIC;
	SIGNAL up, up_change                   : STD_LOGIC;
	SIGNAL Limit_Y_Sup,Limit_Y_Inf         : STD_LOGIC;
	SIGNAL Raqueta                         : INTEGER;
--	CONSTANT wait_time                     : INTEGER:=625000;--25ms --25000 equivale a 1ms
	--testbench
	CONSTANT wait_time                     : INTEGER:=250000;--25ms --25000 equivale a 1ms
	CONSTANT Limit_Raqueta                 : INTEGER:=150;--480 pixeles
BEGIN

Raqueta_Pos_X<="0000000000" WHEN Sentido = '0' ELSE
	            "1001101101";

Raqueta_Pos_Y<=Raqueta_Pos;

Raqueta<=to_integer(unsigned(Raqueta_Pos));

Limit_Y_Sup	<=	'1' WHEN Raqueta = 0 ELSE
	            '0';
Limit_Y_Inf	<=	'1' WHEN Raqueta = (480-Limit_Raqueta) ELSE
	            '0';			
--Efectos
Efectos: entity work.FSM_Efectos
	GENERIC MAP(	Sentido	=> Sentido)
		PORT MAP(	clk		   => clk,
						rst		   => rst,
						Bola_Pos_X  => Bola_Pos_X,
						Bola_Pos_y  => Bola_Pos_Y,
						Raqueta_Pos	=> Raqueta_Pos,
						Colision    => Bola_ra,
						Est_Act		=> Est_Act
						);

--Contador posicion raqueta					
Counter_Raqueta: entity work.Univ_counter
	GENERIC MAP(	N	=> 10)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_countR AND start,
						syn_clr	=> '0',
						load		=> '0',
						up			=> up,
						d			=> ZEROSR,
						Counter	=> Raqueta_Pos
						);
						
--Contador refresco					
Counter_Wait_Time: entity work.Univ_counter
	GENERIC MAP(	N	=> 20)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_ctWT,
						syn_clr	=> clear_ctWT,
						load		=> '0',
						up			=> '1',
						d			=> ZEROSC,
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
	PROCESS(Limit_Y_Sup, Limit_Y_Inf, BT_up, BT_down, Max_tick_WT, pr_state)
	BEGIN
		CASE pr_state IS
			WHEN Iniciar =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='1';
			clear_ctWT<='1';
			IF (BT_up = '1') THEN
				nx_state <= Limite_up;
			ELSIF (BT_down = '1') THEN 
				nx_state <= Limite_down;
			ELSE
				nx_state <= Iniciar;
			END IF;
			  
			WHEN Limite_up =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			IF (Limit_Y_Sup = '0' ) THEN  
				nx_state <= Arriba;
			ELSE                     
			   nx_state <= Iniciar;
			END IF;
			
			WHEN Limite_down =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			IF (Limit_Y_Inf = '0' ) THEN  
				nx_state <= Abajo;
			ELSE                     
			   nx_state <= Iniciar;
			END IF;
		
			WHEN Arriba =>
			up<='0';
			Ena_countR<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			   
				nx_state <= Refresh;
				
			WHEN Abajo =>
			up<='1';
			Ena_countR<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			   
				nx_state <= Refresh;
		
			WHEN Refresh =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='1';
			clear_ctWT<='0';
			IF (Max_tick_WT = '1') THEN 
			   nx_state <= Iniciar;
			ELSE 
				nx_state <= Refresh;
			END IF;
		END CASE;
	END PROCESS;
END ARCHITECTURE;
		