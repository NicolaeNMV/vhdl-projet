-- int pgcd (int a, int b)
-- {
-- 	if (b > a)
-- 		return pgcd (b, a);
-- 	if (b == 0)
-- 		return a;
-- 	return pgcd (b, a % b);
-- }

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------
-- Ce module determine le PGCD d'un nombre 2 nombres de 24 bits signes.
-- Ses E/S sont les busin et busout.
-- Il doit attandre (A) le premier 24 bits pour le premier operand et apres (B) le deuxieme
--
-- Input:
--   busin_data(23 DOWNTO 0) : operand A ou B
--   busin_addr               : 00011 -- 3
--
-- Output:
--   busout_data(11 DOWNTO  23)  : resulat
--   busout_status(25)          : V (overflow)
-------------------------------------------------------------------------------

ENTITY pgcd IS
    PORT(
        clk          : IN  STD_LOGIC;
        -- interface busin
        busin        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        busin_valid  : IN  STD_LOGIC;
        busin_eated  : out STD_LOGIC; -- If we are ready for next value
        -- interface busout
        busout       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        busout_valid : OUT STD_LOGIC; -- If the output is ready to be taken
        busout_eated : IN  STD_LOGIC); -- If our source is ready to receive the 
END pgcd;

ARCHITECTURE Montage OF pgcd IS
    TYPE T_CMD_R IS (NOOP, LOAD, LOAD_B);
	
    SIGNAL CMD_AB :  T_CMD_R ; 

    -- les operandes A et B
    SIGNAL a_tmp   : SIGNED (24 DOWNTO 0);
    SIGNAL b_tmp   : SIGNED (24 DOWNTO 0);

    -- les bus in & out
    SIGNAL busin_addr   : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busin_status : STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busin_data   : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL busout_addr  : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busout_status: STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busout_data  : STD_LOGIC_VECTOR(23 DOWNTO 0);

    --Description des états
    TYPE STATE_TYPE IS (ST_READ_A, ST_READ_B, ST_WRITE_COPY, ST_WRITE_PGCD, ST_COMPUTE);
    SIGNAL state : STATE_TYPE;
BEGIN
	 
-------------------------------------------------------------------------------
--  Partie Operative
-------------------------------------------------------------------------------
    busin_addr          <= busin(31 DOWNTO 27) ;
    busin_status        <= busin(26 DOWNTO 24) ;
    busin_data          <= busin(23 DOWNTO  0) ;
	 
    busout(31 DOWNTO 27) <= busout_addr  ;
    busout(26 DOWNTO 24) <= busout_status;
    busout(23 DOWNTO  0) <= busout_data  ;
	 busout_addr      <= R_Addr;
	 
    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN
        -- R_Aaddr
        if    ( CMD_Addr = LOAD ) then
            R_Addr <= busin_addr;
        end if;
		  
        -- R_Status
        if    ( CMD_Status = LOAD ) then
            R_Status <= busin_status;
        end if;
        -- R_A,R_B
        if    ( CMD_AB = LOAD ) then
            R_A(11 DOWNTO 0) <= busin_data(11 DOWNTO  0);
            R_A(12)          <= '0' ;
            R_B(11 DOWNTO 0) <= busin_data(23 DOWNTO 12);
            R_B(12)          <= '0' ;
        end if;
	 
	 -- Just COPY, we have nothing to do
    busout_data(23 DOWNTO 13) <= R_B (11 DOWNTO 1) when state=ST_WRITE_COPY else "00000000000" ;
    busout_data          (12) <= R_B (0)           when state=ST_WRITE_COPY else R_Res(12) ;
    busout_data(11 DOWNTO  0) <= R_A (11 DOWNTO 0) when state=ST_WRITE_COPY else R_Res(11 DOWNTO 0);
	

-------------------------------------------------------------------------------
-- Partie Controle
-------------------------------------------------------------------------------
-- Inputs:  busin_valid busout_eated
-- Outputs: busin_eated busout_valid, CMD_AB, CMD_Addr, CMD_Status, CMD_Res
-------------------------------------------------------------------------------

    -- fonction de transitition    
    PROCESS (clk)
    BEGIN
      IF clk'EVENT AND clk = '1' THEN
          CASE state IS
              WHEN ST_READ_A =>
                  IF busin_valid  = '1' and busin_addr = "00011" THEN
							 a_tmp <= busin_data;
                      state <= ST_READ_B;
                  ELSIF busin_valid  = '1' and busin_addr /= "00011" THEN
                      state <= ST_WRITE_COPY;
                  END IF; 
					
              WHEN ST_READ_B =>
                  IF busin_valid  = '1' and busin_addr = "00011" THEN
							 b_tmp <= busin_data;
                      state <= ST_COMPUTE;
                  ELSIF busin_valid  = '1' and busin_addr /= "00011" THEN
                      state <= ST_WRITE_COPY;
                  END IF; 
						
          END CASE;
      END IF;
    END PROCESS;
	 
    -- fonction de sortie    
    WITH state  SELECT busin_eated <=
         '1'    WHEN   ST_READ_A,
         '1'    WHEN   ST_READ_B,
         '0'    WHEN   OTHERS; 

    WITH state  SELECT busout_valid <=
        '1'     WHEN   ST_WRITE_COPY,
        '1'     WHEN   ST_WRITE_SUM,
        '0'     WHEN   OTHERS; 

    WITH state  SELECT CMD_Addr <=
         LOAD   WHEN   ST_READ_A,
         LOAD   WHEN   ST_READ_B,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Status <=
         LOAD   WHEN   ST_READ_A,
         LOAD   WHEN   ST_READ_B,
         NOOP   WHEN   OTHERS; 
		  
    WITH state  SELECT CMD_AB <=
         LOAD   WHEN   ST_READ_A,
         LOAD_B   WHEN   ST_READ_B,
         NOOP   WHEN   OTHERS; 
			
    WITH state  SELECT CMD_Res <=
         LOAD   WHEN   ST_Compute,
         NOOP   WHEN   OTHERS; 
		  
END Montage;