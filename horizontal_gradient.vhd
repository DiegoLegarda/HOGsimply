------------------------------------------------------------
-- Author: Diego Antonio Legarda Cordoba - 28/10/2022
-- Affiliation: UnB Faculdade do Gama
------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity horizontal_gradient is
    generic ( MBW : INTEGER; 
              PBW : INTEGER;
              HP : INTEGER);
    port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start : in STD_LOGIC;
           pixel_21 : in STD_LOGIC_VECTOR(PBW downto 0);
           pixel_23 : in STD_LOGIC_VECTOR(PBW downto 0);
           h_ready : out STD_LOGIC;
           h_pixel_out : out STD_LOGIC_VECTOR(PBW+1 downto 0));
end horizontal_gradient;

architecture Behavioral of horizontal_gradient is

    
	
	-- Neighborhood pixels
	signal s_pixel_21 : STD_LOGIC_VECTOR(PBW downto 0) := (others => '0');
	signal s_pixel_23 : STD_LOGIC_VECTOR(PBW downto 0) := (others => '0');
	signal sh_pixel_out :signed(PBW+1 downto 0);
    
    -- Control signals
    signal s_h_ready : STD_LOGIC := '0'; -- Indicates when a horizontal output is ready.

begin

    s_pixel_21 <= pixel_21;
    s_pixel_23 <= pixel_23;
  
    
    process(reset,clk,start)
    begin
        if reset = '1' then
           sh_pixel_out <= (others => '0');
            s_h_ready <= '0';
        elsif rising_edge(clk) then
            s_h_ready <= '0';
            if start = '1' then
                sh_pixel_out <=signed(STD_LOGIC_VECTOR(UNSIGNED('0'&s_pixel_21)- UNSIGNED('0'&s_pixel_23)));
                s_h_ready <= '1';
            end if;
        end if;
    end process;
        
    h_ready <= s_h_ready;
    h_pixel_out <= STD_LOGIC_VECTOR(sh_pixel_out);
    
end Behavioral;
