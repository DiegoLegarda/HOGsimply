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
        NUM_BINS  : integer := 9;   -- Número de bins en el histograma
        BIN_WIDTH : integer := 14;  -- Ancho de cada bin
        BLOCK_SIZE : integer := 4   -- Número de celdas en un bloque
    );
    Port (
        clk                  : in  STD_LOGIC;                                    -- Reloj
        reset                : in  STD_LOGIC;                                    -- Reset
        block_histogram_in   : in  Histograma_bloque; -- Entrada de histograma en arreglo tridimensional
        block_valid_in       : in  STD_LOGIC;                                    -- Señal de validez del bloque de entrada
        binarized_histogram  : out STD_LOGIC_VECTOR(BLOCK_SIZE*NUM_BINS-1 downto 0); -- Histograma binarizado
        block_valid          : out STD_LOGIC                                     -- Señal de validez del histograma de salida
    );
end hog_block_histogram;

architecture Behavioral of hog_block_histogram is
    -- Señales internas
    signal binarized_block : STD_LOGIC_VECTOR(BLOCK_SIZE*NUM_BINS-1 downto 0) := (others => '0');
    signal valid_block      : STD_LOGIC := '0';
    signal s_average        : unsigned(BIN_WIDTH-1 downto 0);
    signal processing       : STD_LOGIC := '0';  -- Señal para indicar que se está procesando el bloque
    signal step_counter     : integer range 0 to 3 := 0; -- Contador de pasos para sincronizar procesos

begin

    process(clk)
        variable bin_sum : unsigned(BIN_WIDTH+4 downto 0) := (others => '0'); -- Suma de todos los bins
        variable average : unsigned(BIN_WIDTH-1 downto 0);                    -- Promedio de los bins
        variable bin_idx, cell_idx : integer;                                  
        variable bin_value : unsigned(14 downto 0);                           
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset de señales internas
                binarized_block <= (others => '0');
                valid_block <= '0';
                processing <= '0';
                step_counter <= 0;
            elsif block_valid_in = '1' and processing = '0' then
                -- Iniciar procesamiento del bloque
                processing <= '1';
                step_counter <= 0; -- Reiniciar contador de pasos
            end if;

            if processing = '1' then
                case step_counter is
                    when 0 =>
                        -- Paso 1: Inicializar acumulador de suma
                        bin_sum := (others => '0');
                        step_counter <= 1;

                    when 1 =>
                        -- Paso 2: Sumar todos los bins del bloque
                        for cell_idx in 0 to BLOCK_SIZE-1 loop
                            for bin_idx in 0 to NUM_BINS-1 loop
                                bin_value := unsigned(block_histogram_in(cell_idx)(bin_idx));
                                bin_sum := bin_sum + resize(bin_value, BIN_WIDTH+4);
                            end loop;
                        end loop;
                        step_counter <= 2;

                    when 2 =>
                        -- Paso 3: Calcular promedio dividiendo entre el total de bins (BLOCK_SIZE * NUM_BINS)
                        average := resize(bin_sum srl 5, BIN_WIDTH); -- srl 5 equivale a dividir por 32 (4 celdas * 9 bins)
                        s_average <= average;
                        step_counter <= 3;

                    when 3 =>
                        -- Paso 4: Binarizar los bins comparándolos con el promedio
                        for cell_idx in 0 to BLOCK_SIZE-1 loop
                            for bin_idx in 0 to NUM_BINS-1 loop
                                if unsigned(block_histogram_in(cell_idx)(bin_idx)) >= average then
                                    binarized_block(cell_idx*NUM_BINS + bin_idx) <= '1';
                                else
                                    binarized_block(cell_idx*NUM_BINS + bin_idx) <= '0';
                                end if;
                            end loop;
                        end loop;

                        -- Marcar bloque como válido después de completar el procesamiento
                        valid_block <= '1';
                        processing <= '0'; -- Finalizar procesamiento
                        step_counter <= 0;

                    when others =>
                        step_counter <= 0;
                end case;
            else
                -- Desactivar la señal de validez si no hay bloque válido de entrada
                valid_block <= '0';
            end if;
        end if;
    end process;

    -- Asignar señales de salida
    binarized_histogram <= binarized_block;
    block_valid <= valid_block;

end Behavioral;


