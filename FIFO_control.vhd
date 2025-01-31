------------------------------------------------------------
-- Author: Diego Legarda - 31/10/2022
-- Affiliation: UnB Faculdade do Gama
------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FIFO_control is
    generic ( PBW : INTEGER;
              HP : INTEGER);
    port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start : in STD_LOGIC;
           pixel_in : in STD_LOGIC_VECTOR(PBW-1 downto 0);
           ack : out STD_LOGIC;
           fin_cel : in STD_LOGIC;
           border_out : out STD_LOGIC;
           neigh_ready : out STD_LOGIC; -- Indicates when a valid neighborhood is ready for operation.
--           pixel_11 : out STD_LOGIC_VECTOR(PBW downto 0);
           pixel_12 : out STD_LOGIC_VECTOR(PBW downto 0);
--           pixel_13 : out STD_LOGIC_VECTOR(PBW downto 0);
           pixel_21 : out STD_LOGIC_VECTOR(PBW downto 0);
--           pixel_22 : out STD_LOGIC_VECTOR(PBW downto 0);
           pixel_23 : out STD_LOGIC_VECTOR(PBW downto 0);
--           pixel_31 : out STD_LOGIC_VECTOR(PBW downto 0));
           pixel_32 : out STD_LOGIC_VECTOR(PBW downto 0));
--           pixel_33 : out STD_LOGIC_VECTOR(PBW downto 0));
end FIFO_control;

architecture Behavioral of FIFO_control is

    -- Storage signals
    signal s_pixel_in : STD_LOGIC_VECTOR(PBW-1 downto 0) := (others => '0');
    signal s_FIFO_reg : STD_LOGIC_VECTOR((((2*HP)+3)*PBW)-1 downto 0) := (others => '0'); -- FIFO register to store necessary pixels. We need to store 2 rows and three pixels to form a neighborhood.

    -- Control signals
    signal s_ack : STD_LOGIC := '0'; -- Indicates when another input can be sent.
    signal s_fin_cel : STD_LOGIC := '0'; -- Indicates when another input can be sent.
    signal s_neigh_ready : STD_LOGIC := '0';
    signal FIFO_ready : STD_LOGIC := '0'; -- Indicates when FIFO register is full and ready for operations.
    signal FIFO_counter : INTEGER range 0 to ((2*HP)+3)-1 := 0; -- Counts the number of elements on FIFO register.
    signal border : STD_LOGIC := '0'; -- Indicates when an invalid pixel has been reached.
    signal row_counter : INTEGER range 0 to HP-1 := 0; -- Counts the number of horizontal pixels.

begin
border_out<=border;
    s_pixel_in <= pixel_in;
    s_fin_cel<=fin_cel;
    -- Process to acumulate input pixels on FIFO register.
	-- This process concatenates the current input pixel with whats already
	-- on the register, acumulating pixels to form a neighborhood
	-- and distribute them after for further calculations.
    FIFO_structure: process(reset,clk,start,s_fin_cel)
    begin
        if reset = '1' then
            s_FIFO_reg <= (others => '0');
            s_ack <= '0';            
        elsif rising_edge(clk) then
            s_ack <= '0';
            if s_fin_cel='1' then
                s_FIFO_reg <= (others => '0');
                s_ack <= '0';
            end if;
            if start = '1'  then                
                s_FIFO_reg <= s_pixel_in & s_FIFO_reg((((2*HP)+3)*PBW)-1 downto PBW);
                s_ack <= '1';
             end if;
        end if;
    end process;

    -- Counts to the first time that FIFO is full and ready
    -- to start gradient calculations.
    FIFO_ready_counter: process(reset,clk,start,FIFO_ready,s_fin_cel)
    begin
        if reset = '1' then
            FIFO_counter <= 0;
            FIFO_ready <= '0';
            
        elsif rising_edge(clk) then  
            if s_fin_cel='1' then
                FIFO_counter <= 0;
                FIFO_ready <= '0';
            end if;                        
            if ((start = '1') and (FIFO_ready = '0'))  then
               if FIFO_counter = ((2*HP)+3)-1 then
                    FIFO_ready <= '1';
                else                    
                    FIFO_counter <= FIFO_counter + 1;
                end if;
                
            end if;
        end if;
    end process;

    border_control: process(reset,clk,s_ack,row_counter,s_fin_cel)
    begin
        if reset = '1' then
            row_counter <= 0;
            border <= '0';
        elsif rising_edge(clk) then
            if s_fin_cel='1' then
                row_counter <= 0;
                border <= '0';
            end if;        
            if (s_ack = '1') and (FIFO_ready = '1') then
                if row_counter = (HP-2)-1 then -- This one indicates the pixel next to the one in the border, critical for calculation.
                    row_counter <= row_counter + 1;
                    border <= '1';
                elsif row_counter = HP-1 then -- This one is the pixel on the border.
                    row_counter <= 0;
                    border <= '0';
                else
                    row_counter <= row_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    neighborhood_control: process(reset,clk,s_ack,FIFO_ready,border,s_fin_cel)
    begin
        if reset = '1' then
            s_neigh_ready <= '0';
        elsif rising_edge(clk) then
            s_neigh_ready <= '0';
            if s_fin_cel='1' then
                s_neigh_ready <= '0';
            end if;
            if (s_ack = '1') and (FIFO_ready = '1') then
                if border = '0' then
                    s_neigh_ready <= '1';
                elsif border = '1' then
                    s_neigh_ready <= '0';
                end if;
            end if;
        end if;
    end process;
    
    ack <= s_ack;
    neigh_ready <= s_neigh_ready;
    
    -- Get each part of the FIFO register that contains the corresponding pixel for the matrix position.
    -- Concatenate with a zero to prevent erros during SIGNED conversion later on.
--    pixel_11 <= STD_LOGIC_VECTOR('0'&s_FIFO_reg(PBW-1 downto 0)); -- reg(7 downto 0).
    pixel_12 <= STD_LOGIC_VECTOR('0' & s_FIFO_reg((2*PBW)-1 downto PBW)); -- reg(15 downto 8).
--    pixel_13 <= STD_LOGIC_VECTOR('0'&s_FIFO_reg((3*PBW)-1 downto 2*PBW)); -- reg(23 downto 16).
    
   pixel_21 <= STD_LOGIC_VECTOR('0' & s_FIFO_reg(((HP+1)*PBW)-1 downto ((HP+1)*PBW)-PBW)); -- reg(519 downto 512).
--    pixel_22 <= STD_LOGIC_VECTOR('0' & s_FIFO_reg(((HP+2)*PBW)-1 downto ((HP+2)*PBW)-PBW)); -- reg(527 downto 520).
   pixel_23 <= STD_LOGIC_VECTOR('0' & s_FIFO_reg(((HP+3)*PBW)-1 downto ((HP+3)*PBW)-PBW)); -- reg(535 downto 528).
    
--    pixel_31 <= STD_LOGIC_VECTOR('0'&s_FIFO_reg((((2*HP)+1)*PBW)-1 downto (((2*HP)+1)*PBW)-PBW)); -- reg(1031 downto 1024).
    pixel_32 <= STD_LOGIC_VECTOR('0' & s_FIFO_reg((((2*HP)+2)*PBW)-1 downto (((2*HP)+2)*PBW)-PBW)); -- reg(1039 downto 1032).
--    pixel_33 <= STD_LOGIC_VECTOR('0' & s_FIFO_reg((((2*HP)+3)*PBW)-1 downto (((2*HP)+3)*PBW)-PBW)); -- reg(1047 downto 1040).
    
end Behavioral;
