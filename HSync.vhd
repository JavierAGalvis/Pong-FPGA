---------<<------------------------<<------------------------<<------------------------<<------------------------
library IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ENTITY HSync IS
GENERIC(	FRONTX_PULSES	:	INTEGER	:=	47;
			VIDEOX_PULSES	:	INTEGER	:=	688;
			BACKX_PULSES	:	INTEGER	:=	704;
			RETRX_PULSES	:	INTEGER	:=	800;
			ADDRESS_SIZE	:	INTEGER	:= 10);
--Testbench
--GENERIC(	FRONTX_PULSES	:	INTEGER	:=	2;
--			VIDEOX_PULSES	:	INTEGER	:=	6;
--			BACKX_PULSES	:	INTEGER	:=	8;
--			RETRX_PULSES	:	INTEGER	:=	9;
--			ADDRESS_SIZE	:	INTEGER	:= 10);
	PORT(	clk				:	IN	STD_LOGIC;
			rst				:	IN	STD_LOGIC;
			RetraceY       :  IN	STD_LOGIC;
			EnableY			: OUT STD_LOGIC;
			AddressX			: OUT STD_LOGIC_VECTOR(ADDRESS_SIZE-1 DOWNTO 0);
			Horiz_Video		: OUT STD_LOGIC;
			Video_OnH		: OUT STD_LOGIC);
END ENTITY HSync;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ARCHITECTURE FSM OF HSync IS
	TYPE state IS (Horizontal_Clear, Horizontal_FrontPorch, Horizontal_VideoAct, Horizontal_BackPorch, Horizontal_Retrace);
	SIGNAL	pr_state, nx_state : state;
	
	SIGNAL	count_X		:	UNSIGNED (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL	Add_Prev		:	UNSIGNED (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL	Flag_State	:	INTEGER	RANGE 0 TO 4;
	
	SIGNAL	Clr_Flag		:	STD_LOGIC;
	SIGNAL	ena_Flag		:	STD_LOGIC;
	
BEGIN
		
		AddressX	<=	STD_LOGIC_VECTOR(add_Prev);
		
		
		lower_fsm: PROCESS (clk, rst)
		BEGIN
			IF (rst = '1') THEN
				pr_state <= Horizontal_Clear;
			ELSIF (rising_edge(clk)) THEN
				pr_state	<= nx_state;
			END IF;
		END PROCESS lower_fsm;
	
	--========================================================
	--Upper part FSM
	--========================================================
	upper_fsm: PROCESS(pr_state, Flag_State, count_X)
	BEGIN
		CASE pr_state IS
			------------------------------------------------------ Clear
			WHEN Horizontal_Clear => 
				   --EnableY		<=	'0';
				   Add_Prev		<= to_unsigned(0, add_Prev'length);
				   Horiz_Video	<= '0';
				   Video_OnH	<= '0';
				
				   clr_Flag		<= '1';
				   ena_Flag		<=	'0';
				
				nx_state	<= Horizontal_FrontPorch;
			------------------------------------------------------ Front Porch 
			WHEN Horizontal_FrontPorch => 
				--EnableY		<=	'0';
				Add_Prev		<= to_unsigned(0, add_Prev'length);
				Horiz_Video	<= '1';
				Video_OnH	<= '0';
				
				clr_Flag		<= '0';
				ena_Flag		<= '1';
				
				IF (Flag_State = 1) THEN
					nx_state	<= Horizontal_VideoAct;
				ELSE
					nx_state	<= Horizontal_FrontPorch;
				END IF;
			------------------------------------------------------ Video Activo 
			WHEN Horizontal_VideoAct => 
				--EnableY		<=	'0';
				Add_Prev		<= count_X - FRONTX_PULSES-1;
				Horiz_Video	<= '1';
				Video_OnH	<= '1';
				
				clr_Flag		<= '0';
				ena_Flag		<= '1';
				
				IF (Flag_State = 2) THEN
					nx_state	<= Horizontal_BackPorch;
				ELSE
					nx_state	<= Horizontal_VideoAct;
				END IF;
			------------------------------------------------------ Back Porch 
			WHEN Horizontal_BackPorch => 
				--EnableY		<=	'0';
				Add_Prev		<= to_unsigned(0, add_Prev'length);
				Horiz_Video	<= '1';
				Video_OnH	<= '0';
				
				clr_Flag		<= '0';
				ena_Flag		<= '1';
				
				IF (Flag_State = 3) THEN
					nx_state	<= Horizontal_Retrace;
				ELSE
					nx_state	<= Horizontal_BackPorch;
				END IF;
			------------------------------------------------------ Retrace 
			WHEN Horizontal_Retrace => 
				--EnableY		<=	'0';
				Add_Prev		<= to_unsigned(0, add_Prev'length);
				Horiz_Video	<= '0';
				Video_OnH	<= '0';
				
				clr_Flag		<= '0';
				ena_Flag		<= '1';
				
				IF (Flag_State = 4) THEN
				   --EnableY		<=	'1';
					--EnableY		<=	'0';
				   Add_Prev		<= to_unsigned(0, add_Prev'length);
				   Horiz_Video	<= '0';
				   Video_OnH	<= '0';
				   clr_Flag		<= '1';
				   ena_Flag		<=	'0';
					nx_state	<= Horizontal_FrontPorch;
				ELSE
					nx_state	<= Horizontal_Retrace;
				END IF;
		END CASE;
	end process;
	
	--Finish row
	EnableY <= '1' WHEN count_X =RETRX_PULSES-1 ELSE 
	                 '0';
	
	
	--========================================================
	--	Counters: Retrace X, Retrace Y, Video On X, Video On y
	--========================================================	
	Horizontal_Counter: PROCESS (clk, rst, clr_Flag, ena_Flag)
	BEGIN
		IF (rst = '1') THEN
			count_X			<= to_unsigned(0, count_X'length);
			Flag_State		<= 0;
		ELSIF (rising_edge(clk)) THEN
			IF (clr_Flag = '1') THEN
				count_X			<= to_unsigned(0, count_X'length);
				Flag_State		<= 0;
			ELSIF (ena_Flag = '1') THEN
				count_X		<= count_X + 1;
				IF ((count_x >= FRONTX_PULSES-1) AND (count_x < VIDEOX_PULSES-1)) THEN 		-- Front -> Active
					Flag_State	<=	1;
				ELSIF ((count_x >= VIDEOX_PULSES-1) AND (count_x < BACKX_PULSES-1)) THEN	-- Active -> Back
					Flag_State	<= 2;
				ELSIF ((count_x >= BACKX_PULSES-1) AND (count_x < RETRX_PULSES-1)) THEN		-- Back -> Retrace
					Flag_State	<= 3;
				ELSIF ((count_x >= RETRX_PULSES-1)) THEN												-- Retrace -> Front
					Flag_State	<= 4;
				ELSE																								-- FRONT PORCH
					Flag_State	<= 0;
				END IF;
			END IF;
		END IF;
	END PROCESS Horizontal_Counter;
	
END ARCHITECTURE FSM;