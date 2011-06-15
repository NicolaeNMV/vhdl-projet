LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------
-- Ce module est un jeu de devinette
-- La personne qui doit faire deviner entre un nombre N sur busin (l'etat du jeu est reinitialise)
-- La personne qui doit deviner N utilise les 18 interrupteurs pour entrer son nombre P 
-- et valide sa proposition au moyen d'un bouton pressoire.
-- Si P <= N , une diode inferieur s'affiche, Si P >= N une diode superieur s'affiche
-- Le joueur a un certain nombre de tour pour deviner le nombre
-- Si le nombre de tour est atteint, les diodes s'eteignent.

-- Ses E/S sont les busin et busout.
--
-- Input:
--   busin_data(17 DOWNTO  0) : nombre a deviner
--   busin_addr               : 01000
--
-- Output:
--   busout_data(1 DOWNTO  0) : code retour du jeu : 00: lose, 01: win, 10: >, 11: <
--   busout_data(15 DOWNTO  8) : nombre de tour restant

--   busout_status(26 DOWNTO 24) : status
--   busout_address(31 DOWNTO 27)  : adresse
-------------------------------------------------------------------------------


ENTITY guess IS
    PORT(
        clk          : IN  STD_LOGIC;
        -- interface busin
        busin        : in  STD_LOGIC_VECTOR(31 DOWNTO 0);
        busin_valid  : in  STD_LOGIC;
        busin_eated  : out STD_LOGIC; 
		  
        -- interface busout
        busout       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        busout_valid : OUT STD_LOGIC;
        busout_eated : IN  STD_LOGIC;
		  
		  -- jeu
		  button : in STD_LOGIC;
		  switchs : in STD_LOGIC_VECTOR(17 downto 0);
		  diode_inf : OUT STD_LOGIC;
		  diode_sup : OUT STD_LOGIC
	);
END guess;


ARCHITECTURE Montage OF guess IS

    -- l'adresse et le status
    TYPE T_CMD_R IS (NOOP, LOAD);
    SIGNAL CMD_Addr   :  T_CMD_R; 
    SIGNAL CMD_Status :  T_CMD_R; 
    SIGNAL R_Addr     :  STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL R_Status   :  STD_LOGIC_VECTOR (2 DOWNTO 0);
    
    TYPE T_CMD_data IS (INIT, NOOP);
    SIGNAL CMD_data : T_CMD_data; 
    SIGNAL data:  STD_LOGIC_VECTOR (18 DOWNTO 0);
    SIGNAL n:  UNSIGNED (18 DOWNTO 0);
	 
	 -- proposition actuelle
    SIGNAL p : UNSIGNED (17 DOWNTO 0);

    SIGNAL ret : UNSIGNED (1 DOWNTO 0);
	 
    TYPE T_CMD_i IS (INIT, DECR, NOOP);
    SIGNAL CMD_i : T_CMD_i;
    SIGNAL i : UNSIGNED (7 DOWNTO 0);

    TYPE T_CMD_sup IS (INIT, NOOP);
    SIGNAL CMD_sup : T_CMD_sup;
    SIGNAL estsup: STD_LOGIC;
	 
    TYPE T_CMD_inf IS (INIT, NOOP);
    SIGNAL CMD_inf : T_CMD_inf;
    SIGNAL estinf: STD_LOGIC;
	 
    SIGNAL endmloop: STD_LOGIC;
	 
	 -- les bus in & out
    SIGNAL busin_addr   : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busin_status : STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busin_data   : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL busout_addr  : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busout_status: STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busout_data  : STD_LOGIC_VECTOR(23 DOWNTO 0);

    --Description des états
    TYPE STATE_TYPE IS (
        ST_READ, -- lire la donnee
        ST_WRITE_COPY, --passer data au suivant (adresse ne me concerne pas)
        MLOOP,
		  BUTTON_PRESSED,
		  BUTTON_RELEASED,
		  ST_INF,
		  ST_WIN,
		  ST_SUP
    );
    SIGNAL state : STATE_TYPE;
    
BEGIN

-------------------------------------------------------------------------------
--  Partie OpÃ©rative
-------------------------------------------------------------------------------
    
	 p <= UNSIGNED(switchs);
	 n <= UNSIGNED(data);
	 endmloop <= '1' when i="00000000" else '0';
	 
	 diode_inf <= estinf;
	 diode_sup <= estsup;
	 
	 busin_addr          <= busin(31 DOWNTO 27) ;
    busin_status        <= busin(26 DOWNTO 24) ;
    busin_data          <= busin(23 DOWNTO  0) ;
    busout(31 DOWNTO 27) <= busout_addr  ;
    busout(26 DOWNTO 24) <= busout_status;
    busout(23 DOWNTO  0) <= busout_data  ;
    
	 PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN
      -- registre n : pour la donnee
      if    ( CMD_data = INIT ) then
           data(17 DOWNTO 0) <= busin_data(17 DOWNTO  0);
      end if;
		
		if (CMD_sup = INIT and p>=n ) then 
			estsup <= '1';
		elsif (CMD_sup = INIT) then
			estsup <= '0';
		end if;
		
		if (CMD_inf = INIT and p<=n) then 
			estinf <= '1';
		elsif (CMD_sup = INIT) then
			estinf <= '0';
		end if;
		
      -- registre i :  INIT, DECR, NOOP
      if ( CMD_i = INIT ) then
          i <= "00001000"; -- 16
      elsif (CMD_i = DECR ) then
          i <= i - 1;
      else
          i <= i;
      end if;

    END IF; END PROCESS;
    
    busout_addr      <= R_Addr;
    busout_status(2) <= R_status(2) when state=ST_WRITE_COPY else '1';
    --TODO busout_status(1) <= R_status(1) when state=ST_WRITE_COPY else ov_tmp;
    --TODO busout_status(0) <= R_status(0) when state=ST_WRITE_COPY else z_tmp;
    busout_data(23 downto 16)<= busout_data(23 DOWNTO 16) when state=ST_WRITE_COPY else "00000000";
	 busout_data(15 DOWNTO 8) <= busout_data(15 DOWNTO 8) when state=ST_WRITE_COPY else std_logic_vector(i);
    busout_data(7 downto 2)  <= busout_data(7 DOWNTO 2) when state=ST_WRITE_COPY else "000000";
	 busout_data(1 DOWNTO  0) <= busout_data(1 DOWNTO  0) when state=ST_WRITE_COPY else std_logic_vector(ret);

-------------------------------------------------------------------------------
-- Partie Controle
-------------------------------------------------------------------------------

    -- fonction de transitition    
    PROCESS (clk)
    BEGIN
      IF clk'EVENT AND clk = '1' THEN
          CASE state IS
              WHEN ST_READ =>
                  IF busin_valid  = '1' and busin_addr = "01000" THEN
                      state <= MLOOP;
                  ELSIF busin_valid  = '1' and busin_addr /= "01000" THEN
                      state <= ST_WRITE_COPY;
                  END IF;
						
              WHEN ST_WRITE_COPY =>
                  IF busout_eated = '1' THEN
                      state  <= ST_READ;
                  END IF; 

              WHEN MLOOP =>
                  IF button = '1' THEN
							state <= BUTTON_PRESSED;
                  END IF; 
					
					WHEN BUTTON_PRESSED =>
						IF button = '0' THEN
							state <= BUTTON_RELEASED;
						END IF;
						
					WHEN BUTTON_RELEASED =>
						IF busout_eated = '0' THEN
							state <= BUTTON_RELEASED;
						ELSIF endmloop='1' THEN
							state <= ST_READ;
						ELSIF estinf='1' and estsup='1' THEN
							state <= ST_WIN;
						ELSIF estinf='1' THEN
							state <= ST_INF;
						ELSIF estsup='1' THEN
							state <= ST_SUP;
						END IF;

              WHEN ST_WIN =>
                  state  <= ST_READ;
						
					WHEN ST_INF => 
						state <= MLOOP;
						
					WHEN ST_SUP => 
						state <= MLOOP;

          END CASE;
      END IF;
    END PROCESS;

    -- fonction de sortie    
    WITH state  SELECT busin_eated <=
         '1'    WHEN   ST_READ,
         '0'    WHEN   OTHERS; 

    WITH state  SELECT busout_valid <=
        '1'     WHEN   ST_WRITE_COPY,
        '1'     WHEN   BUTTON_RELEASED,
        '0'     WHEN   OTHERS; 

    WITH state  SELECT CMD_Addr <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Status <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 
			
    WITH state  SELECT CMD_inf <=
         INIT   WHEN   BUTTON_RELEASED,
         NOOP   WHEN   OTHERS;
			
    WITH state  SELECT CMD_sup <=
         INIT   WHEN   BUTTON_RELEASED,
         NOOP   WHEN   OTHERS; 
			
    WITH state  SELECT CMD_data <=
         INIT   WHEN   ST_READ,
         NOOP   WHEN   OTHERS;

        WITH state SELECT CMD_i <=
        INIT WHEN ST_READ,
        DECR WHEN BUTTON_RELEASED,
        NOOP WHEN OTHERS;



END Montage;

