------------------------------------------------------------
-- Author: Diego Legarda 04/11/2022
-- Affiliation: UnB Faculdade do Gama
------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vertical_gradient is
    generic ( MBW : INTEGER;
              PBW : INTEGER;
              HP : INTEGER);
    port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start : in STD_LOGIC;
           pixel_12 : in STD_LOGIC_VECTOR(PBW downto 0);
           pixel_32 : in STD_LOGIC_VECTOR(PBW downto 0);
           v_ready : out STD_LOGIC;
           v_pixel_out : out STD_LOGIC_VECTOR(PBW+1 downto 0));
end vertical_gradient;

architecture Behavioral of vertical_gradient is

   
	-- Neighborhood pixels
	signal s_pixel_12 : STD_LOGIC_VECTOR(PBW downto 0) := (others => '0');
	signal s_pixel_32 : STD_LOGIC_VECTOR(PBW downto 0) := (others => '0');

	
	
	-- Sum results
    signal sv_pixel_out : SIGNED(PBW+1 downto 0) := (others => '0');
    
    -- Control signals
    signal s_v_ready : STD_LOGIC := '0'; -- Indicates when a vertical output is ready.

begin

    s_pixel_12 <= pixel_12;--std_logic_vector(unsigned(not(pixel_11))+1);
    s_pixel_32 <= pixel_32;

    
    process(reset,clk,start)
    begin
        if reset = '1' then
            sv_pixel_out <= (others => '0');
            s_v_ready <= '0';
        elsif rising_edge(clk) then
            s_v_ready <= '0';
            if start = '1' then
                sv_pixel_out <=signed(STD_LOGIC_VECTOR(UNSIGNED('0'&s_pixel_12)- UNSIGNED('0'&s_pixel_32)));
                s_v_ready <= '1';
            end if;
        end if;
    end process;
    
   

    v_ready <= s_v_ready;
    v_pixel_out <= STD_LOGIC_VECTOR(sv_pixel_out);

end Behavioral;
