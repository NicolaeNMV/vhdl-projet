LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-------------------------------------------------------------------------------
-- Ce module recupere des octets 1 par 1 sur RS232in et les regroupe pour
-- realiser l'interface bus (voir bus.txt).
--
-- soit X la concatenation de adresse (partie haute), status et data (partie
-- basse) du bus, le premier octet recupere est X>>24 (poid fort), le
-- deuxieme octet recupere est X>>16, le troisieme octet recupere est X>>8
-- et le dernier octet recupere est le poid faible de X.
--
-- Du cote bus, il suit le protocole du busout (signaux: busout, 
-- busout_valid, busout_eated).
-- 
-- Du cote RS232in, il suit le protocole de ce module (signaux: Ndata, Data).
-- 
-- Attention: il n'y a pas de controle de flux du cote RS232in.
-------------------------------------------------------------------------------


ENTITY busFromRS232 IS
    PORT(
        clk          : IN  STD_LOGIC;
        -- interface busout
        busout       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        busout_valid : OUT STD_LOGIC;
        busout_eated : IN  STD_LOGIC; 
        -- interface vers rs232out
        Ndata        : IN  STD_LOGIC;
        Data         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0));
END busFromRS232;


ARCHITECTURE Montage OF busFromRS232 IS

    -- compteur donnant le nombre d'octets a mettre dans R_32
    TYPE T_CMD_i IS (NOOP, COUNT, INIT);
    SIGNAL CMD_i :  T_CMD_i ; 
    SIGNAL R_i   :  INTEGER RANGE 0 TO 4;
    SIGNAL VT_endLoop:  STD_LOGIC;

    -- accumule les octets venant de Data.
    TYPE T_CMD_32 IS (NOOP, SHIFT);
    SIGNAL CMD_32 :  T_CMD_32 ; 
    SIGNAL R_32   :  STD_LOGIC_VECTOR (31 DOWNTO 0);

    --Description des états
    TYPE STATE_TYPE IS (ST_WAIT_RS232, ST_SHIFT_DATA, ST_WAIT_BUS, ST_EndLoop);
    SIGNAL state : STATE_TYPE;
    
    
BEGIN

-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------

    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN
        -- R_i
        if    ( CMD_i = INIT ) then
            R_i <= 4 ;
        elsif ( CMD_i = COUNT ) then
            R_i <= R_i - 1;
        else
            R_i <= R_i;
        end if;
        -- R_32
        if    ( CMD_32 = SHIFT ) then
            R_32(31 DOWNTO 24) <= R_32(23 DOWNTO 16);
            R_32(23 DOWNTO 16) <= R_32(15 DOWNTO  8);
            R_32(15 DOWNTO  8) <= R_32( 7 DOWNTO  0);
            R_32( 7 DOWNTO  0) <= Data;
        else
            R_32 <= R_32 ;
        end if;
    END IF; END PROCESS;
    
    VT_endLoop <= '1' when R_i=0 else '0' ; 
    
    busout <= R_32;

-------------------------------------------------------------------------------
-- Partie Contrôle
-------------------------------------------------------------------------------
-- Inputs:  busout_eated Ndata VT_endLoop 
-- Outputs: busout_valid CMD_i CMD_32
-------------------------------------------------------------------------------

    -- fonction de transitition    
    PROCESS (clk)
    BEGIN
        IF clk'EVENT AND clk = '1' THEN
            CASE state IS
                WHEN ST_WAIT_RS232 =>
                    IF Ndata  = '1' THEN
                        state <= ST_SHIFT_DATA;
                    END IF; 

                WHEN ST_SHIFT_DATA =>
                    state  <= ST_EndLoop;

                WHEN ST_EndLoop =>
                    IF VT_endLoop = '1' THEN
                        state  <= ST_WAIT_BUS;
                    elsif Ndata = '1' THEN
                        state  <= ST_SHIFT_DATA;
                    else
                        state  <= ST_EndLoop;
                    END IF; 

                WHEN ST_WAIT_BUS =>
                    IF busout_eated = '1' THEN
                        state <= ST_WAIT_RS232;
                    END IF;

            END CASE;
        END IF;
    END PROCESS;

    -- fonction de sortie    
    WITH state  SELECT busout_valid <=
        '1'     WHEN   ST_WAIT_BUS,
        '0'     WHEN   OTHERS; 

    WITH state  SELECT CMD_i <=
         INIT   WHEN   ST_WAIT_RS232,
         COUNT  WHEN   ST_SHIFT_DATA,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_32 <=
         SHIFT  WHEN   ST_SHIFT_DATA,
         NOOP   WHEN   OTHERS; 

END Montage;

