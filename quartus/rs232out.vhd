LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
-------------------------------------------------------------------------------
-- Ce module serialise l'entree DATA de 8 bits sur la sortie TX.
--
-- le format écrit est:
--    - 1 start bit
--    - 8 bit de données
--    - 1 stop bits
--
-- La sortie BUSY indique que le module est en train de serialiser.
-- 
-- Pour serialiser une nouvelle valeur, il faut:
--    * attendre que BUSY soit nul.
--    * la positionner sur DATA et mettre NDATA à 1 au moins 1 cycle.
--
-- Pour fixer le BAUD du composant utilisez les parametres generiques
-- BAUD et FREQ ci dessous.
-------------------------------------------------------------------------------


ENTITY rs232out IS
	GENERIC(
		FREQ : integer :=  50000000;  -- Frequence de clk
	    BAUD : integer :=  9600);      -- Baud de Rx
    PORT(
        clk     :IN     STD_LOGIC;
        Tx      :OUT    STD_LOGIC;
        Busy    :OUT    STD_LOGIC;
        Ndata   :IN     STD_LOGIC;
        Data    :IN     STD_LOGIC_VECTOR(7 DOWNTO 0));
END rs232out;


ARCHITECTURE Montage_1 OF rs232out IS

    TYPE T_CMD_i IS (NOOP, COUNT, INIT);
    SIGNAL CMD_i :  T_CMD_i ; 
    SIGNAL R_i   :  INTEGER RANGE 0 TO 15;
    SIGNAL VT_endLoop:  STD_LOGIC;

    TYPE T_CMD_baud IS (NOOP, COUNT, INIT);
    SIGNAL CMD_baud :  T_CMD_baud ; 
    SIGNAL R_baud:  INTEGER RANGE 0 TO (FREQ)/BAUD;
    SIGNAL VT_endbaud:  STD_LOGIC;

    TYPE T_CMD_data IS (NOOP, SHIFT, INIT);
    SIGNAL CMD_data :  T_CMD_data ; 
    SIGNAL R_data:  STD_LOGIC_VECTOR(9 DOWNTO 0);  --    0 : 1 start bit
                                                   --  8:1 : 8 data bits
																	--    1 : 1 end bit
    SIGNAL CMD_F1 :  STD_LOGIC; 
	 
    --Description des états
    TYPE STATE_TYPE IS ( W_ND, SLOOP, W_B, SHIFT );
    SIGNAL state : STATE_TYPE;
    
    
BEGIN

-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------
    VT_endbaud <= '1' when R_baud=0 else '0';
    VT_endLoop <= '1' when R_i=9 else '0';
    Tx <= R_data(0) when CMD_F1='0' else '1';
    Busy <= '0' when R_i=9 else '1';
    PROCESS (clk)
    BEGIN if clk'event and clk='1' then
        -- registre R_baud
        if CMD_baud=INIT then
            R_baud <= FREQ/BAUD;
        elsif CMD_baud=COUNT then
            R_baud <= R_baud - 1;
        elsif CMD_baud=NOOP then
           R_baud <= R_baud;
        end if;

        -- registre R_i
        if CMD_i=INIT then
            R_i <= 0;
        elsif CMD_i=COUNT then
            R_i <= R_i + 1;
        elsif CMD_i=NOOP then
            R_i <= R_i;
        end if;

        -- registre R_data
        if CMD_data=INIT then
            R_data(0) <= '0';
            R_data(8 downto 1) <= Data(7 downto 0);
            R_data(9) <= '1';
        elsif CMD_data=SHIFT then
            R_data(8 downto 0) <= R_data(9 downto 1);
				R_data(9) <= '1';
        else
            R_data <= R_data; --noop
        end if;

    END IF; END PROCESS;


-------------------------------------------------------------------------------
-- Partie Contrôle
-------------------------------------------------------------------------------
-- Inputs:  Ndata VT_endLoop VT_endBaud
-- Outputs: Tx Busy  CMD_i CMD_baud CMD_data
-------------------------------------------------------------------------------

    -- fonction de transitition
    -- fonction de transitition    
    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN CASE state IS
        WHEN W_ND =>
          IF NDATA = '0' THEN
            state <= W_ND;
          ELSE
            state <= SLOOP;
          END IF;

         when SLOOP =>
           if VT_endLoop='1' then
             state <= W_ND;
           ELSE
             state <= W_B;
           end if;

         when W_B =>
            if VT_endbaud='1' then
              state <= SHIFT;
            else
              state <= W_B;
            end if;
                   
         when SHIFT =>
             state <= SLOOP;
         
     end CASE; end IF; end PROCESS;
 
    -- fonction de sortie (g)

    WITH state SELECT CMD_I <=
      INIT when W_ND,
      NOOP when SLOOP,
      NOOP when W_B,
      COUNT when SHIFT;

    WITH state SELECT CMD_BAUD <=
      INIT when W_ND,
      INIT when SLOOP,
      COUNT when W_B,
      INIT when SHIFT;

    WITH state SELECT CMD_DATA <=
      INIT when W_ND,
      NOOP when SLOOP,
      NOOP when W_B,
      SHIFT when SHIFT;
		
	 WITH state SELECT CMD_F1 <=
		'1' when W_ND,
		'0' when SLOOP,
		'0' when W_B,
		'0' when SHIFT;

END Montage_1;

