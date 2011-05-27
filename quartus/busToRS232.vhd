LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-------------------------------------------------------------------------------
-- Ce module envoie/decoupe le bus (adresse+status+data) en mot de 8 bits et
-- les transmet 1 par 1 au module RS232out (voir bus.txt).
--
-- soit X la concatenation de adresse (partie haute), status et data (partie
-- basse) du bus, il transmet d'abord l'octet X>>24 (poid fort),
-- puis l'octet X>>16, puis l'octet X>>8 et enfin l'octet de poid faible de X.
--
-- Du cote bus, il suit le protocole du busin (signaux: busin, busin_valid,
-- busin_eated). Il transmet toutes les adresses.
-- 
-- Du cote RS232out, il suit le protocole de ce module (signaux: Busy,
-- Ndata, Data).
-------------------------------------------------------------------------------


ENTITY busToRS232 IS
    PORT(
        clk     :IN     STD_LOGIC;
        -- interface busin
        busin       : in  STD_LOGIC_VECTOR(31 DOWNTO 0);
        busin_valid : in  STD_LOGIC;
        busin_eated : out STD_LOGIC; 
        -- interface vers rs232out
        Busy    :IN     STD_LOGIC;
        Ndata   :Out     STD_LOGIC;
        Data    :Out     STD_LOGIC_VECTOR(7 DOWNTO 0));
END busToRS232;


ARCHITECTURE Montage OF busToRS232 IS
    -- Compteur
    TYPE T_CMD_i IS (NOOP, COUNT, INIT);
    SIGNAL CMD_i :  T_CMD_i; 
    SIGNAL R_i   :  INTEGER RANGE 0 TO 4;
    SIGNAL endloop:  STD_LOGIC;

    -- Registre pour la donnée de 32 bits 
    TYPE T_CMD_32 IS (INIT, NOOP, SHIFT);
    SIGNAL CMD_32 : T_CMD_32;
    SIGNAL R_32   : STD_LOGIC_VECTOR(31 DOWNTO 0);

    --Description des états
    TYPE STATE_TYPE IS ( W_ND, LOOP_WRITE, W_RS232OUT, SHIFT );
    SIGNAL state : STATE_TYPE;
BEGIN

-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------

    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN
        -- compteur
         if ( CMD_i = INIT ) then
            R_i <= 4 ;
        elsif ( CMD_i = COUNT ) then
            R_i <= R_i - 1;
        else
            R_i <= R_i;
        end if;
        -- R_32
        if ( CMD_32 = INIT ) then
            R_32 <= busin;
        elsif ( CMD_32 = SHIFT ) then
            R_32(31 DOWNTO 8) <= R_32(23 DOWNTO 0);
            R_32(7 downto 0) <= "00000000";
        else
            R_32 <= R_32;
        end if;
    END IF; END PROCESS;

    endLoop <= '1' when R_i=0 else '0';
    Ndata <= '1' when state = W_RS232OUT else '0';
    busin_eated <= '1' when state = W_ND else '0';
    Data <= R_32(31 downto 24);

-------------------------------------------------------------------------------
-- Partie Contrôle
-------------------------------------------------------------------------------
-- Inputs:  
-- Outputs: 
-------------------------------------------------------------------------------

    -- fonction de transitition    
    PROCESS (clk)
    BEGIN
        IF clk'EVENT AND clk = '1' THEN
            CASE state IS
                WHEN W_ND =>
                    if busin_valid='1' then
                        state <= LOOP_WRITE;
                    end if; 
                WHEN LOOP_WRITE =>
                    if endLoop = '1' then
                        state <= W_ND;
                    else
                        state <= W_RS232OUT;
                    end if;
                WHEN W_RS232OUT =>
                    if Busy = '0' then
                        state <= SHIFT;
                    end if;
                WHEN SHIFT =>
                    state <= LOOP_WRITE;

            END CASE;
        END IF;
    END PROCESS;

    -- fonction de sortie  
    WITH state SELECT CMD_i <=
        INIT when W_ND,
        NOOP when LOOP_WRITE,
        NOOP when W_RS232OUT,
        COUNT when SHIFT;

    WITH state SELECT CMD_32 <=
        INIT when W_ND,
        NOOP when LOOP_WRITE,
        NOOP when W_RS232OUT,
        SHIFT when SHIFT;

END Montage;

