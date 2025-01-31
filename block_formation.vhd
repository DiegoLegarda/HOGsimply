----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.12.2024 15:28:37
-- Design Name: 
-- Module Name: block_formation - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Hogpack.all;

entity hog_block_histogram is
    Generic (
        NUM_BINS  : integer := 9;   -- N�mero de bins en el histograma
        BIN_WIDTH : integer := 14;  -- Ancho de cada bin
        BLOCK_SIZE : integer := 4   -- N�mero de celdas en un bloque
    );
    Port (
        clk                  : in  STD_LOGIC;                                    -- Reloj
        reset                : in  STD_LOGIC;                                    -- Reset
        block_histogram_in   : in  Histograma_bloque; -- Entrada de histograma en arreglo tridimensional
        block_valid_in       : in  STD_LOGIC;                                    -- Se�al de validez del bloque de entrada
        binarized_histogram  : out STD_LOGIC_VECTOR(BLOCK_SIZE*NUM_BINS-1 downto 0); -- Histograma binarizado
        block_valid          : out STD_LOGIC                                     -- Se�al de validez del histograma de salida
    );
end hog_block_histogram;

architecture Behavioral of hog_block_histogram is
    -- Se�ales internas
    signal binarized_block : STD_LOGIC_VECTOR(BLOCK_SIZE*NUM_BINS-1 downto 0) := (others => '0');
    signal valid_block      : STD_LOGIC := '0';
    signal s_average      : unsigned(BIN_WIDTH-1 downto 0);
--    type Histograma_bloque is array (0 to 3) of Celda;
begin

    process(clk)
        variable bin_sum : unsigned(BIN_WIDTH+4 downto 0) := (others => '0'); -- Suma de todos los bins
        variable average : unsigned(BIN_WIDTH-1 downto 0);                    -- Promedio de los bins
        variable bin_idx, cell_idx : integer;    
        variable bin_value : unsigned(14 downto 0);                              -- �ndices para celdas y bins
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset de se�ales internas
                binarized_block <= (others => '0');
                valid_block <= '0';
            elsif block_valid_in = '1' then
                -- Inicializar acumulador de suma
                bin_sum := (others => '0');

                  -- Paso 1: Sumar todos los bins del bloque
                for cell_idx in 0 to BLOCK_SIZE-1 loop
                    for bin_idx in 0 to NUM_BINS-1 loop
                        -- Extraer el valor del bin actual
                        bin_value := unsigned(block_histogram_in(cell_idx)(bin_idx));

                        -- Acumular el valor con redimensionamiento expl�cito
                        bin_sum := bin_sum + resize(bin_value, BIN_WIDTH+4);
                    end loop;
                end loop;

                -- Paso 2: Calcular promedio dividiendo entre el total de bins (BLOCK_SIZE * NUM_BINS)
                average := resize(bin_sum srl 5, BIN_WIDTH); -- srl 5 equivale a dividir por 32 (4 celdas * 9 bins)
                s_average<=average;
                -- Paso 3: Binarizar los bins compar�ndolos con el promedio
                for cell_idx in 0 to BLOCK_SIZE-1 loop
                    for bin_idx in 0 to NUM_BINS-1 loop
                        if unsigned(block_histogram_in(cell_idx)(bin_idx)) >= average then
                            binarized_block(cell_idx*NUM_BINS + bin_idx) <= '1';
                        else
                            binarized_block(cell_idx*NUM_BINS + bin_idx) <= '0';
                        end if;
                    end loop;
                end loop;

                -- Indicar que el bloque binarizado est� listo
                valid_block <= '1';
            else
                -- Desactivar la se�al de validez si no hay bloque v�lido de entrada
                valid_block <= '0';
            end if;
        end if;
    end process;

    -- Asignar se�ales de salida
    binarized_histogram <= binarized_block;
    block_valid <= valid_block;

end Behavioral;

