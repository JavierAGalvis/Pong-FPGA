---------<<------------------------<<------------------------<<------------------------<<------------------------
library IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ENTITY VGA_Sync IS
GENERIC(	FRONTY_PULSES	:	INTEGER	:=	33;
			VIDEOY_PULSES	:	INTEGER	:=	514;
			BACKY_PULSES	:	INTEGER	:=	524;
			RETRY_PULSES	:	INTEGER	:=	526;
			ADDRESS_SIZE	:	INTEGER	:= 10);
--Testbench
--GENERIC(	FRONTY_PULSES	:	INTEGER	:=	2;
--			VIDEOY_PULSES	:	INTEGER	:=	6;
--			BACKY_PULSES	:	INTEGER	:=	8;
--			RETRY_PULSES	:	INTEGER	:=	10;
--			ADDRESS_SIZE	:	INTEGER	:= 10);
	PORT(	clk				:	IN	STD_LOGIC;
			rst				:	IN	STD_LOGIC;
			AddressX			: OUT STD_LOGIC_VECTOR(ADDRESS_SIZE-1 DOWNTO 0);
			AddressY			: OUT STD_LOGIC_VECTOR(ADDRESS_SIZE-1 DOWNTO 0);
			Video_On			: OUT STD_LOGIC;
			HSync_Out		: OUT STD_LOGIC;
			VSync_Out		: OUT STD_LOGIC);
END ENTITY VGA_Sync;
---------<<------------------------<<------------------------<<------------------------<<------------------------
ARCHITECTURE FSM OF VGA_Sync IS
	TYPE state IS (Vertical_Clear, Vertical_FrontPorch, Vertical_VideoAct, Vertical_BackPorch, Vertical_Retrace);
	SIGNAL	pr_state, nx_state : state;
	
	SIGNAL	count_Y		:	UNSIGNED (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL	Add_Prev		:	UNSIGNED (ADDRESS_SIZE-1 DOWNTO 0);
	SIGNAL	Flag_State	:	INTEGER	RANGE 0 TO 4;
	
	SIGNAL	Clr_Flag		:	STD_LOGIC;
	SIGNAL	ena_Flag		:	STD_LOGIC;
	
	SIGNAL	EnableY		:	STD_LOGIC;
	SIGNAL	Verti_Video	:	STD_LOGIC;
	SIGNAL	Horiz_Video	:	STD_LOGIC;
	
	SIGNAL	Video_OnV	:	STD_LOGIC;
	SIGNAL	Video_OnH	:	STD_LOGIC;
	SIGNAL	wr_en_a   	:	STD_LOGIC;
	
BEGIN
------------------------------ Combinacional y Bloques ---------------------------------------
		AddressY		<=	STD_LOGIC_VECTOR(add_Prev);
		Video_On		<= Video_OnV AND Video_OnH;
		HSync_Out	<=	Horiz_Video AND NOT wr_en_a;
		VSync_Out	<= Verti_Video;
		
		
		HSync:	ENTITY work.HSync
				PORT MAP(	clk			=>	clk,
								rst			=>	rst,
								RetraceY		=>	wr_en_a,
								EnableY		=> ena_Flag,
								AddressX		=> AddressX,
								Horiz_Video	=> Horiz_Video,
								Video_OnH	=>	Video_OnH);
		
-------------------------------- Máquina de estados ------------------------------------------
		lower_fsm: PROCESS (clk, rst)
		BEGIN
			IF (rst = '1') THEN
				pr_state <= Vertical_Clear;
			ELSIF (rising_edge(clk)) THEN
				pr_state	<= nx_state;
			END IF;
		END PROCESS lower_fsm;
	
		--========================================================
		--Upper part FSM
		--========================================================
		upper_fsm: PROCESS(pr_state, Flag_State, count_Y)
		BEGIN
			CASE pr_state IS
				------------------------------------------------------ Clear
				WHEN Vertical_Clear => 
					Add_Prev		<= to_unsigned(0, add_Prev'length);
					Verti_Video	<= '0';
					
					wr_en_a		<= '0';
					Video_OnV	<= '0';
					clr_Flag		<= '1';
					
					nx_state		<=	Vertical_FrontPorch;
				------------------------------------------------------ Front Porch 
				WHEN Vertical_FrontPorch => 
					Add_Prev		<= to_unsigned(0, add_Prev'length);
					Verti_Video	<= '1';
					
					wr_en_a		<= '0';
					Video_OnV	<= '0';
					clr_Flag		<= '0';
					
					IF (Flag_State = 1) THEN
						nx_state	<= Vertical_VideoAct;
					ELSE
						nx_state	<= Vertical_FrontPorch;
					END IF;
				------------------------------------------------------ Video Activo 
				WHEN Vertical_VideoAct => 
					Add_Prev		<= count_Y - FRONTY_PULSES;
					Verti_Video	<= '1';
					
					wr_en_a		<= '0';
					Video_OnV	<= '1';
					clr_Flag		<= '0';
					
					IF (Flag_State = 2) THEN
						nx_state	<= Vertical_BackPorch;
					ELSE
						nx_state	<= Vertical_VideoAct;
					END IF;
				------------------------------------------------------ Back Porch 
				WHEN Vertical_BackPorch => 
					Add_Prev		<= to_unsigned(0, add_Prev'length);
					Verti_Video	<= '1';
					
					wr_en_a		<= '0';
					Video_OnV	<= '0';
					clr_Flag		<= '0';
					
					IF (Flag_State = 3) THEN
						nx_state	<= Vertical_Retrace;
					ELSE
						nx_state	<= Vertical_BackPorch;
					END IF;
				------------------------------------------------------ Retrace 
				WHEN Vertical_Retrace => 
					Add_Prev		<= to_unsigned(0, add_Prev'length);
					Verti_Video	<= '0';
					wr_en_a		<= '1';
					Video_OnV	<= '0';
					clr_Flag		<= '0';
					
					IF (Flag_State = 4) THEN
						Add_Prev		<= to_unsigned(0, add_Prev'length);
					   Verti_Video	<= '0';
					
					   wr_en_a		<= '0';
					   Video_OnV	<= '0';
					   clr_Flag		<= '1';
						nx_state	<= Vertical_FrontPorch;
					ELSE
						nx_state	<= Vertical_Retrace;
					END IF;
			END CASE;
		end process;
		
		
----------------------------------- Counter ---------------------------------------------
		Vertical_Counter: PROCESS (clk, rst, clr_Flag, ena_Flag)
		BEGIN
			IF (rst = '1') THEN
				count_Y			<= to_unsigned(0, count_Y'length);
				Flag_State		<= 0;
			ELSIF (rising_edge(clk)) THEN
				IF (clr_Flag = '1') THEN
					count_Y			<= to_unsigned(0, count_Y'length);
					Flag_State		<= 0;
				ELSIF (ena_Flag = '1') THEN
					count_Y		<= count_Y + 1;
					IF ((count_Y >= FRONTY_PULSES-1) AND (count_Y < VIDEOY_PULSES-1)) THEN 		-- Front -> Active
						Flag_State	<=	1;
					ELSIF ((count_Y >= VIDEOY_PULSES-1) AND (count_Y < BACKY_PULSES-1)) THEN	-- Active -> Back
						Flag_State	<= 2;
					ELSIF ((count_Y >= BACKY_PULSES-1) AND (count_Y < RETRY_PULSES-1)) THEN		-- Back -> Retrace
						Flag_State	<= 3;
					ELSIF ((count_Y >= RETRY_PULSES-1)) THEN												-- Retrace -> Front
						Flag_State	<= 4;
					ELSE																								-- FRONT PORCH
						Flag_State	<= 0;
					END IF;
				END IF;
			END IF;
		END PROCESS Vertical_Counter;
	
END ARCHITECTURE FSM;