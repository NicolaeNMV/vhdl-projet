LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------
-- Ce module fait la racine entiere d'un nombre de 24 bits non signes.
-- Ses E/S sont les busin et busout.
--
-- Input:
--   busin_data(23 DOWNTO  0) : nombre
--   busin_addr               : 00001
--
-- Output:
--   busout_data(11 DOWNTO  0)  : racine inferieur
--   busout_data(23 DOWNTO  12) : racine superieur

--   busout_status(26 DOWNTO 24) : status
--   busout_address(31 DOWNTO 27)  : adresse
-------------------------------------------------------------------------------

-- Algo :
-- short racine_inf, racine_sup;
-- isqrt(short num) {
--    short op = num;
--    short res = 0;
--    short one = 1 << 14; // pour le vhdl, sur 24 bits => 22 bits
--    short tmp;
--    while (one > op)
--        one >>= 2;
--    while (one != 0) {
--        tmp = res + one;
--        if (op >= tmp) {
--            op -= tmp;
--            res = (res >> 1) + one;
--        }
--        else {
--          res >>= 1;
--        }
--        one >>= 2;
--    }
--    racine_inf = res;
--    if(num == res*res)
--      racine_sup = res;
--    else
--      racine_sup = res+1;
-- }


ENTITY racine IS
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
END racine;


ARCHITECTURE Montage OF racine IS
    TYPE T_CMD_R IS (NOOP, LOAD);
    
    TYPE T_CMD_OP IS (INIT, DEL_TMP, NOOP);
    SIGNAL CMD_OP : T_CMD_OP; 
    SIGNAL op:  STD_LOGIC_VECTOR (23 DOWNTO 0);

    -- l'adresse et le status
    SIGNAL CMD_Addr   :  T_CMD_R; 
    SIGNAL CMD_Status :  T_CMD_R; 
    SIGNAL R_Addr     :  STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL R_Status   :  STD_LOGIC_VECTOR ( 2 DOWNTO 0);

    -- le resulat 
    SIGNAL racine_sup, racine_inf:  STD_LOGIC_VECTOR (11 DOWNTO 0);

    TYPE T_CMD_res IS (INIT, SHIFT_RIGHT, ADD_ONE, NOOP);
    SIGNAL CMD_res : T_CMD_res;
    SIGNAL res : UNSIGNED (23 DOWNTO 0);

    TYPE T_CMD_one IS (INIT, SHIFT_2_RIGHT, NOOP);
    SIGNAL CMD_one : T_CMD_one;
    SIGNAL one : UNSIGNED (23 DOWNTO 0);
    
    SIGNAL tmp : UNSIGNED (23 DOWNTO 0);

    SIGNAL one_gt_op : STD_LOGIC;
    SIGNAL one_not_null : STD_LOGIC;
    SIGNAL op_gte_tmp : STD_LOGIC;

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
        ST_WRITE_RES, -- ecrire le résultat
        LOOP_DECALE_ONE,
        LOOP_MAIN,
        IF_OP_SUP_TMP,
        ELSE_OP_INF_TMP,
        ONE_DECALE
    );
    SIGNAL state : STATE_TYPE;
    
BEGIN

-------------------------------------------------------------------------------
--  Partie OpÃ©rative
-------------------------------------------------------------------------------
    tmp <= res + one;
    racine_inf <= std_logic_vector(res)(11 DOWNTO 0);
    racine_sup <= std_logic_vector(res+1)(11 DOWNTO 0);

    one_gt_op <= '1' when one>UNSIGNED(op) else '0';
    one_not_null <= '1' when one/=0 else '0';
    op_gte_tmp <= '1' when UNSIGNED(op)>tmp else '0';
    
    busin_addr          <= busin(31 DOWNTO 27) ;
    busin_status        <= busin(26 DOWNTO 24) ;
    busin_data          <= busin(23 DOWNTO  0) ;
    busout(31 DOWNTO 27) <= busout_addr  ;
    busout(26 DOWNTO 24) <= busout_status;
    busout(23 DOWNTO  0) <= busout_data  ;
    
    PROCESS (clk)
    BEGIN IF clk'EVENT AND clk = '1' THEN
        -- registre op : INIT, DEL_TMP, NOOP 
        if CMD_OP=INIT then
            op <= busin_data;
        elsif CMD_OP=DEL_TMP then
            op <= std_logic_vector(UNSIGNED(op) - tmp);
        end if;
        -- registre res : INIT, SHIFT_RIGHT, ADD_ONE, NOOP
        if CMD_res=INIT then
            res <= "000000000000000000000000";
        elsif CMD_res=SHIFT_RIGHT then
            res(22 downto 0) <= res(23 downto 1);
            res(23) <= '0';
        elsif CMD_res=ADD_ONE then
            res <= res + one;
        end if;
        -- registre one : INIT SHIFT_2_RIGHT, NOOP
        if CMD_one=INIT then
            one <= "010000000000000000000000";
        elsif CMD_one=SHIFT_2_RIGHT then
            one(21 downto 0) <= one(23 downto 2);
            one(23) <= '0';
            one(22) <= '0';
        end if;
    END IF; END PROCESS;
    
    busout_addr      <= R_Addr;
    busout_status(2) <= R_status(2) when state=ST_WRITE_COPY else '1';
    --TODO busout_status(1) <= R_status(1) when state=ST_WRITE_COPY else ov_tmp;
    --TODO busout_status(0) <= R_status(0) when state=ST_WRITE_COPY else z_tmp;
    busout_data(23 DOWNTO 12) <= racine_sup when state=ST_WRITE_COPY else "000000000000" ;
    busout_data(11 DOWNTO  0) <= racine_inf when state=ST_WRITE_COPY else
    "000000000000";

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
                  IF busin_valid  = '1' and busin_addr = "00100" THEN
                      state <= LOOP_DECALE_ONE;
                  ELSIF busin_valid  = '1' and busin_addr /= "00100" THEN
                      state <= ST_WRITE_COPY;
                  END IF; 

              WHEN LOOP_DECALE_ONE =>
                  IF one_gt_op='1' THEN
                      state <= LOOP_DECALE_ONE;
                  ELSE
                      state <= LOOP_MAIN;
                  END IF;
              
              WHEN LOOP_MAIN =>
                  IF one_not_null='1' and op_gte_tmp='1' THEN
                      state <= IF_OP_SUP_TMP;
                  ELSIF one_not_null='1' THEN -- one!=0 && op<tmp
                      state <= ELSE_OP_INF_TMP;
                  ELSE
                      state <= ST_WRITE_RES;
                  END IF;

              WHEN IF_OP_SUP_TMP =>
                  state <= ONE_DECALE;
              
              WHEN ELSE_OP_INF_TMP =>
                  state <= ONE_DECALE;
              
              WHEN ONE_DECALE =>
                  state <= LOOP_MAIN;

              WHEN ST_WRITE_RES =>
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
        '1'     WHEN   ST_WRITE_RES,
        '0'     WHEN   OTHERS; 

    WITH state  SELECT CMD_Addr <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Status <=
         LOAD   WHEN   ST_READ,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_OP <= -- INIT, DEL_TMP, NOOP
         INIT   WHEN   ST_READ,
         DEL_TMP WHEN  IF_OP_SUP_TMP,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_one <= -- INIT, SHIFT_2_RIGHT, NOOP
        INIT    WHEN   ST_READ,
        SHIFT_2_RIGHT WHEN LOOP_DECALE_ONE,
        SHIFT_2_RIGHT WHEN ONE_DECALE,
        NOOP    WHEN OTHERS; 

    WITH state  SELECT CMD_res <= -- INIT, SHIFT_RIGHT, ADD_ONE, NOOP
        INIT   WHEN   ST_READ,
        SHIFT_RIGHT WHEN ELSE_OP_INF_TMP,
        ADD_ONE WHEN  IF_OP_SUP_TMP,
        NOOP   WHEN   OTHERS; 

END Montage;

