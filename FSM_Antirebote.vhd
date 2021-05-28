LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY FSM_Antirebote IS 
	PORT ( rst :IN STD_LOGIC;
			 clk :IN STD_LOGIC;
			 sw :IN STD_LOGIC;
			 MaxTick_B :IN STD_LOGIC;
			 MaxTick_3 :IN STD_LOGIC;
			 Ena_countB :OUT STD_LOGIC;
			 Ena_count3 :OUT STD_LOGIC;
			 clear_count3 : OUT STD_LOGIC;
			 sw_AntB :OUT STD_LOGIC
	);
END ENTITY FSM_Antirebote;

ARCHITECTURE FSM OF FSM_Antirebote IS
	TYPE state IS ( Iniciar, Wait_B, Confirmar, Contar_3, Prender);
	SIGNAL pr_state, nx_state: state;
BEGIN 
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
	PROCESS( sw, MaxTick_B, MaxTick_3, pr_state)
	BEGIN
		CASE pr_state IS
			WHEN Iniciar =>
			sw_AntB <= '0';
			clear_count3 <= '1';
			Ena_countB <= '0';
			Ena_count3 <= '1';
				IF (sw = '1') THEN 
					nx_state <= Wait_B;
				ELSE 
					nx_state <= Iniciar;
				END IF;
			WHEN Wait_B =>
			sw_AntB <= '0';
			clear_count3 <= '0';
			Ena_countB <= '1';
			Ena_count3 <= '0';
				IF (MaxTick_B= '1') THEN 
					nx_state <= Confirmar;
				ELSE 
					nx_state <= Wait_B;
				END IF;
			WHEN Confirmar =>
			sw_AntB <= '0';
			clear_count3 <= '0';
			Ena_countB <= '0';
			Ena_count3 <= '0';
				IF (sw = '1') THEN 
					nx_state <= contar_3;
				ELSE 
					nx_state <= Iniciar;
				END IF;
			WHEN Contar_3 =>
			sw_AntB <= '0';
			clear_count3 <= '0';
			Ena_countB <= '0';
			Ena_count3 <= '1';
				IF (MaxTick_3 = '1') THEN 
					nx_state <= Prender;
				ELSE 
					nx_state <= Wait_B;
				END IF;
			WHEN Prender =>
			sw_AntB <= '1';
			clear_count3 <= '0';
			Ena_countB <= '0';
			Ena_count3 <= '0';
			IF (sw = '1') THEN 
					nx_state <= Prender;
				ELSE 
					nx_state <= Iniciar;
				END IF;
			END CASE;
		END PROCESS;
	END ARCHITECTURE;