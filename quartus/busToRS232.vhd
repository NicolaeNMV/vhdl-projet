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

    
    
BEGIN

-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------

    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN


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

            END CASE;
        END IF;
    END PROCESS;

    -- fonction de sortie    

END Montage;

