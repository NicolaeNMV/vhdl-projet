LIBRARY IEEE ;
USE IEEE.std_logic_1164.ALL ;
-------------------------------------------------------------------------------
-- Ce module déserialise l'entree RX dans la sortie DATA de 8 bits.
--
-- le format lu est:
--    - 1 start bit
--    - 8 bit de données
--    - 1 ou plusieurs stop bits
-- 
-- Ce module met NDATA à 1 pendant un cycle quand une nouvelle
-- valeur est presente sur DATA d'où le chronogramme suivant
-- avec A, B et C des valeurs stables de NDATA.
--
-- NDATA    0000100000000000000000001000000000000000100000000000
-- DATA     ????A???????????????????B???????????????C???????????
-- 
-- Pour fixer le BAUD du composant utilisez les parametres generiques
-- BAUD et FREQ ci dessous.
-------------------------------------------------------------------------------

ENTITY rs232in IS
	GENERIC(
		FREQ : integer :=  50000000;  -- Frequence de clk
	    BAUD : integer :=  9600);      -- Baud de Rx
    PORT(
        clk     : IN    STD_LOGIC;
        Rx      : IN    STD_LOGIC;
        Ndata   : OUT   STD_LOGIC;
        Data    : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0));
END rs232in;


ARCHITECTURE Montage_1 OF rs232in IS

    SIGNAL CMD_sh:  STD_LOGIC;                      -- 0:noop, 1:shift
    SIGNAL R_sh:    STD_LOGIC_VECTOR(7 DOWNTO 0);

    TYPE T_CMD_baud is (COUNT, INIT1P5B, INIT1B) ;
    SIGNAL CMD_baud: T_CMD_baud;
    SIGNAL VT_baud:  STD_LOGIC;
    SIGNAL R_baud:   INTEGER RANGE 0 TO (2*FREQ)/BAUD;

    TYPE T_CMD_i IS (NOOP, COUNT, INIT);
    SIGNAL CMD_i: T_CMD_i;
    SIGNAL R_i:   INTEGER RANGE 0 TO 10;
    SIGNAL VT_i:  STD_LOGIC;

    --Description des états
    TYPE STATE_TYPE IS ( WAIT_StartBit, WAIT_1P5B, MainLoop, ECRIRE,
                         WAIT_1B, GEN_PULSE, WAIT_FIN);
    SIGNAL state : STATE_TYPE;
    
    
BEGIN
    
-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------

    VT_baud <= '1' WHEN R_baud=0 ELSE '0';
    VT_i <= '1' WHEN R_i=0 ELSE '0';
    Data <= R_sh;

    PROCESS (clk)
        BEGIN if clk'event and clk='1' then
            --R_baud
            if CMD_baud=INIT1P5B then
                R_baud <= (FREQ+FREQ/2)/BAUD;  -- init à 1.5 * F/B
            elsif CMD_baud=INIT1B then
                R_baud <= FREQ/BAUD;          -- init à F/B
            else
                R_baud <= R_baud - 1;
            end if;     
            -- R_i
            if CMD_i=NOOP then
                R_i <= R_i ;            -- on ne fait rien (noop)
            elsif CMD_i=INIT then
                R_i <= 8;             -- init à 8
            else
                R_i <= R_i - 1;     -- on compte
            end if;
            -- R_sh
            if CMD_sh='1' then                  
                R_sh(6 downto 0) <= R_sh(7 downto 1);                 
                R_sh(7) <= Rx;
            end if;
        END IF; END PROCESS; 

-------------------------------------------------------------------------------
-- Partie Contrôle
-------------------------------------------------------------------------------

    -- fonction de transitition    
    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN CASE state IS
        WHEN WAIT_StartBit =>
            IF Rx = '0' THEN
                state <= WAIT_1P5B;
            ELSE
                state <= WAIT_StartBit;
            END IF; 
        
        WHEN WAIT_1P5B =>
            IF VT_baud='1' THEN
                state <= MainLoop;                            
            ELSE
                state <= WAIT_1P5B;
            END IF;
        
        WHEN MainLoop=>
            IF VT_i='1' THEN
                state <= GEN_PULSE;
            ELSE
                state <= ECRIRE;
            END IF;
        
        WHEN ECRIRE=>
            state <= WAIT_1B;
        
        WHEN WAIT_1B=>
            IF VT_baud='1' THEN
                state <= MainLoop;
            ELSE
                state <= WAIT_1B;
            END IF;
        
        WHEN GEN_PULSE =>
            state <= WAIT_FIN;
        
        WHEN WAIT_FIN=>
            IF VT_baud='1' THEN
                state <= WAIT_StartBit;
            ELSE
                state <= WAIT_FIN;
            END IF;
                
    END CASE; END IF; END PROCESS;

    -- fonction de sortie    
    WITH state SELECT nData <=
        '1' WHEN    GEN_PULSE,
        '0' WHEN    OTHERS; 

    WITH state SELECT CMD_sh <=
        '1' WHEN    ECRIRE,
        '0' WHEN    OTHERS;     

    WITH state SELECT CMD_baud <=
        INIT1B    WHEN    MainLoop,
        INIT1B    WHEN    ECRIRE,
        INIT1P5B  WHEN    WAIT_StartBit,
        COUNT     WHEN    OTHERS; 
    
    WITH state SELECT CMD_i <=
        INIT    WHEN    WAIT_StartBit,
        INIT    WHEN    WAIT_1P5B,
        COUNT   WHEN    MainLoop,
        NOOP    WHEN    OTHERS; 
            
END Montage_1;
