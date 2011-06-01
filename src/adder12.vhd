LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------
-- Ce module additionne 2 nombres de 12 bits signes.
-- Ses E/S sont les busin et busout.
--
-- Input:
--   busin_data(11 DOWNTO  0) : operande 1 en complement a 2
--   busin_data(23 DOWNTO 12) : operande 2 en complement a 2
--   busin_addr               : 00001
--
-- Output:
--   busout_data(11 DOWNTO  0)  : resulat
--   busout_data(12 DOWNTO  12) : C (retenue sortante)
--   busout_data(13 DOWNTO  13) : Z (resultat nul)
--   busout_status(25)          : V (overflow)
-------------------------------------------------------------------------------

ENTITY adder12 IS
    PORT(
        clk          : IN  STD_LOGIC;
        -- interface busin
        busin        : in  STD_LOGIC_VECTOR(31 DOWNTO 0);
        busin_valid  : in  STD_LOGIC;
        busin_eated  : out STD_LOGIC; 
        -- interface busout
        busout       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        busout_valid : OUT STD_LOGIC;
        busout_eated : IN  STD_LOGIC);
END adder12;


ARCHITECTURE Montage OF adder12 IS
    TYPE T_CMD_R IS (NOOP, LOAD);


    -- les operandes A et B
    -- on les etend sur 13 bits pour avoir la retenue
    SIGNAL CMD_AB :  T_CMD_R ; 
    SIGNAL R_A,R_B:  STD_LOGIC_VECTOR (12 DOWNTO 0);

    -- l'adresse et le status
    SIGNAL CMD_Addr   :  T_CMD_R ; 
    SIGNAL CMD_Status :  T_CMD_R ; 
    SIGNAL R_Addr     :  STD_LOGIC_VECTOR ( 4 DOWNTO 0);
    SIGNAL R_Status   :  STD_LOGIC_VECTOR ( 2 DOWNTO 0);

    -- le resulat 
    SIGNAL CMD_Res :  T_CMD_R ; 
    SIGNAL R_Res   :  STD_LOGIC_VECTOR (12 DOWNTO 0);

    -- signaux intermediaires
    SIGNAL a_tmp   : SIGNED (12 DOWNTO 0);
    SIGNAL b_tmp   : SIGNED (12 DOWNTO 0);
    SIGNAL r_tmp   : SIGNED (12 DOWNTO 0);
    -- SIGNAL p_tmp   : SIGNED (25 DOWNTO 0); -- for mult
    SIGNAL ov_tmp  : STD_LOGIC;
    SIGNAL z_tmp   : STD_LOGIC;
    -- les bus in & out
    SIGNAL busin_addr   : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busin_status : STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busin_data   : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL busout_addr  : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busout_status: STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busout_data  : STD_LOGIC_VECTOR(23 DOWNTO 0);

    --Description des états
    TYPE STATE_TYPE IS (ST_READ, ST_WRITE_COPY, ST_WRITE_SUM, ST_COMPUTE);
    SIGNAL state : STATE_TYPE;
    
BEGIN

-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------
    busin_addr          <= busin(31 DOWNTO 27) ;
    busin_status        <= busin(26 DOWNTO 24) ;
    busin_data          <= busin(23 DOWNTO  0) ;
    busout(31 DOWNTO 27) <= busout_addr  ;
    busout(26 DOWNTO 24) <= busout_status;
    busout(23 DOWNTO  0) <= busout_data  ;
    -- a_tmp <= TO_INTEGER(SIGNED(R_A));
    -- b_tmp <= TO_INTEGER(SIGNED(R_B));
    a_tmp <= SIGNED(R_A);
    b_tmp <= SIGNED(R_B);
    r_tmp <= a_tmp + b_tmp;
    -- p_tmp <= a_tmp * b_tmp;       -- for mult
    -- r_tmp <= p_tmp(12 DOWNTO 0);  -- for mult

    ov_tmp <= '1' when (R_a(11)='1' and R_b(11)='1' and r_tmp(11)='0')
                    or (R_a(11)='0' and R_b(11)='0' and r_tmp(11)='1') else
              '0';
    z_tmp  <= '1' when r_tmp(11 DOWNTO 0)="000000000000" else '0';

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
        -- R_Res
        if    ( CMD_Res = LOAD ) then
            R_Res <= std_logic_vector(r_tmp);
        end if;
    END IF; END PROCESS;
    
    busout_addr      <= R_Addr;
    busout_status(2) <= R_status(2) when state=ST_WRITE_COPY else '1';
    busout_status(1) <= R_status(1) when state=ST_WRITE_COPY else ov_tmp;
    busout_status(0) <= R_status(0) when state=ST_WRITE_COPY else z_tmp;
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
              WHEN ST_READ =>
                  IF busin_valid  = '1' and busin_addr = "00001" THEN
                      state <= ST_COMPUTE;
                  ELSIF busin_valid  = '1' and busin_addr /= "00001" THEN
                      state <= ST_WRITE_COPY;
                  END IF; 

              WHEN ST_COMPUTE =>
                  state  <= ST_WRITE_SUM;

              WHEN ST_WRITE_SUM =>
                  IF busout_eated = '1' THEN
                      state  <= ST_READ;
                  END IF; 

              WHEN ST_WRITE_COPY =>
                  IF busout_eated = '1' THEN
                      state  <= ST_READ;
                  END IF; 
          END CASE;
      END IF;
    END PROCESS;

    -- fonction de sortie    
    WITH state  SELECT busin_eated <=
         '1'    WHEN   ST_READ,
         '0'    WHEN   OTHERS; 

    WITH state  SELECT busout_valid <=
        '1'     WHEN   ST_WRITE_COPY,
        '1'     WHEN   ST_WRITE_SUM,
        '0'     WHEN   OTHERS; 

    WITH state  SELECT CMD_Addr <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Status <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_AB <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Res <=
         LOAD   WHEN   ST_Compute,
         NOOP   WHEN   OTHERS; 

END Montage;

