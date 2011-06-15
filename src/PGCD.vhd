LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------
-- Ce module determine le PGCD d'un nombre 2 nombres de 24 bits signes.
-- Ses E/S sont les busin et busout.
-- Il doit attandre (A) le premier 24 bits pour le premier operand et apres (B) le deuxieme
--
-- Input:
--   busin_data(23 DOWNTO  0) : operande 1 ou 2
--   busin_addr               : 00011
--
-- Output:
--   busout_data(23 DOWNTO  0)  : resulat
--   busout_status(25)          : V (overflow)
-------------------------------------------------------------------------------

ENTITY PGCD IS
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
END PGCD;


ARCHITECTURE Montage OF PGCD IS
    TYPE T_CMD_R IS (NOOP, LOAD, LOAD_B, SWAP, SUB, COMPUTE);


    -- les operandes A et B
    -- on les etend sur 24 bits
    SIGNAL CMD_A,CMD_B :  T_CMD_R ; 
    SIGNAL R_INPUT,R_A,R_B:  STD_LOGIC_VECTOR (23 DOWNTO 0);

    -- l'adresse et le status
    SIGNAL CMD_Addr   :  T_CMD_R ; 
    SIGNAL CMD_Status :  T_CMD_R ; 
	 SIGNAL CMD_Input :  T_CMD_R ; 
	 
    SIGNAL R_Addr     :  STD_LOGIC_VECTOR ( 4 DOWNTO 0);
    SIGNAL R_Status   :  STD_LOGIC_VECTOR ( 2 DOWNTO 0);

    -- le resulat 
    SIGNAL CMD_Res :  T_CMD_R ; 
    SIGNAL R_Res   :  STD_LOGIC_VECTOR (23 DOWNTO 0);

    -- signaux intermediaires
    SIGNAL a_tmp   : SIGNED (23 DOWNTO 0);
    SIGNAL b_tmp   : SIGNED (23 DOWNTO 0);
    SIGNAL c_tmp   : SIGNED (23 DOWNTO 0);

    SIGNAL z_tmp   : STD_LOGIC;
	 SIGNAL fin_boucle:  STD_LOGIC;
	 SIGNAL b_tmp_bigger_than_a:  STD_LOGIC;
    -- les bus in & out
    SIGNAL busin_addr   : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busin_status : STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busin_data   : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL busout_addr  : STD_LOGIC_VECTOR( 4 DOWNTO 0);
    SIGNAL busout_status: STD_LOGIC_VECTOR( 2 DOWNTO 0);
    SIGNAL busout_data  : STD_LOGIC_VECTOR(23 DOWNTO 0);

    --Description des états
    TYPE STATE_TYPE IS (ST_READ_A,ST_READ_A_DO,ST_READ_B_DO,
                        ST_READ_B, 
		ST_COMPUTE,  -- the loop for compute
		ST_SWAP_AB, -- swap AB
		ST_DECR_B_FROM_A,
		ST_WRITE_COPY, ST_LOAD_PGCD, ST_WRITE_PGCD, ST_INIT_COMPUTE );
    SIGNAL state : STATE_TYPE;
    
BEGIN
			-- DECR_B_FROM_A WHEN ST_DECR_B_FROM_A

-------------------------------------------------------------------------------
--  Partie Opérative
-------------------------------------------------------------------------------
    busin_addr          <= busin(31 DOWNTO 27) ;
    busin_status        <= busin(26 DOWNTO 24) ;
    busin_data          <= busin(23 DOWNTO  0) ;
    busout(31 DOWNTO 27) <= busout_addr  ;
    busout(26 DOWNTO 24) <= busout_status;
    busout(23 DOWNTO  0) <= busout_data  ;

	 -- if (b==0) goto ST_WRITE;
	 -- fin_boucle <= '1' WHEN R_A = R_B ELSE '0';
	 fin_boucle <= '1' WHEN b_tmp = 0 ELSE '0';
	 -- if (b>a) swap(a,b)
	 b_tmp_bigger_than_a <= '1' WHEN b_tmp > a_tmp ELSE '0';
	 
    a_tmp <= SIGNED(R_A);
	 b_tmp <= SIGNED(R_B);
    
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
        if    ( CMD_Input = LOAD ) then
            R_input <= busin_data;
        end if;

        -- LOAD A 
        if    ( CMD_A= LOAD ) then
				R_A <= R_input;
			elsif ( CMD_A = SWAP ) then
			   R_A <= R_B;
         elsif ( CMD_A = SUB ) then
	         R_A <= std_logic_vector(a_tmp - b_tmp);
		   else
				R_A <= R_A;
        end if;
		  
        -- LOAD B
        if    ( CMD_B= LOAD ) then
				R_B <= R_input;
			elsif ( CMD_B = SWAP ) then
			   R_B <= R_A;
		   else
				R_B <= R_B;
        end if;
		  
		  if (CMD_Res = LOAD) then
				R_Res <= R_A;
		  end if;
			
	
    END IF; END PROCESS;
    	 
    busout_addr      <= R_Addr;

	 busout_status(2) <= '1' when state=ST_WRITE_COPY else '0';
	 busout_status(1) <= '1' when state=ST_WRITE_COPY else '0';
    busout_status(0) <= '1' when state=ST_WRITE_COPY else '0';
	 
    busout_data(23 DOWNTO 0) <= R_INPUT (23 DOWNTO 0) when state=ST_WRITE_COPY else R_Res (23 DOWNTO 0);

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
                      state <= ST_READ_A_DO;
                  ELSIF busin_valid  = '1' and busin_addr /= "00011" THEN
                      state <= ST_WRITE_COPY;
                  END IF; 
						
              WHEN ST_READ_A_DO =>
                  state <= ST_READ_B;
						
              WHEN ST_READ_B =>
                  IF busin_valid  = '1' and busin_addr = "00011" THEN
                      state <= ST_READ_B_DO;
                  ELSIF busin_valid  = '1' and busin_addr /= "00011" THEN
                      state <= ST_WRITE_COPY;
                  END IF; 
						
              WHEN ST_READ_B_DO =>
                  state <= ST_INIT_COMPUTE;

				  WHEN ST_INIT_COMPUTE =>
						state <= ST_COMPUTE;		
						
				  WHEN ST_COMPUTE =>
						IF fin_boucle = '1' THEN
							 state <= ST_LOAD_PGCD;
						ELSIF b_tmp_bigger_than_a='1' THEN
							state <= ST_SWAP_AB;
						ELSIF b_tmp_bigger_than_a='0' THEN
							state <= ST_DECR_B_FROM_A;
						END IF;

				  WHEN ST_LOAD_PGCD =>
						state <= ST_WRITE_PGCD;
			
              WHEN ST_WRITE_PGCD =>
                  IF busout_eated = '1' THEN
                      state  <= ST_READ_A;
                  END IF; 
			
				  WHEN ST_SWAP_AB =>
						state <= ST_COMPUTE;
					
				  WHEN ST_DECR_B_FROM_A =>
					   state <= ST_SWAP_AB;				

              WHEN ST_WRITE_COPY =>
                  IF busout_eated = '1' THEN
                      state  <= ST_READ_A;
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
        '1'     WHEN   ST_WRITE_PGCD,
        '0'     WHEN   OTHERS; 

    WITH state  SELECT CMD_Addr <=
         LOAD   WHEN   ST_READ_A,
			LOAD   WHEN   ST_READ_B,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Status <=
         LOAD   WHEN   ST_READ_A,
			LOAD   WHEN   ST_READ_B,
         NOOP   WHEN   OTHERS;

		WITH state  SELECT CMD_input <=
         LOAD   WHEN   ST_READ_A,
			LOAD   WHEN   ST_READ_B,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_A <=
         LOAD   WHEN   ST_READ_A_DO,
			SWAP   WHEN   ST_SWAP_AB,
			SUB    WHEN   ST_DECR_B_FROM_A,
         NOOP   WHEN   OTHERS; 
	
	 WITH state  SELECT CMD_B <=
         LOAD   WHEN   ST_READ_B_DO,
			SWAP   WHEN   ST_SWAP_AB,
         NOOP   WHEN   OTHERS; 

    WITH state  SELECT CMD_Res <=
			LOAD WHEN ST_LOAD_PGCD,
         NOOP   WHEN   OTHERS; 
	

END Montage;

