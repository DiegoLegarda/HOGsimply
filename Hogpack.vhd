
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use work.fpupack.all;

package hogpack is

--constant max_num_in : integer := 15;
--constant max_num_h : integer := 15;
--constant max_num_out : integer := 15;

--constant numi : integer range 0 to max_num_in := 4;
--constant numh : integer range 1 to max_num_h := 4;
--constant numo : integer range 1 to max_num_out := 3;

--type array_in is array (0 to numi-1) of std_logic_vector(FP_WIDTH-1 downto 0);
--type array_h is array (0 to numh-1) of std_logic_vector(FP_WIDTH-1 downto 0);
--type array_out is array (0 to numo-1) of std_logic_vector(FP_WIDTH-1 downto 0);

--constant maxiter : integer range 0 to numi := (numi/2)-1;

 -- Arreglo fifo
              -- Definir el tipo para los 9 bines dentro de una celda (cada bin es un std_logic_vector(14 downto 0))
        type Celda is array (0 to 8) of std_logic_vector(14 downto 0);
        
        -- Definir el tipo para el histograma que tiene 8 celdas
        type Histograma_fifo_type is array (0 to 15) of Celda;
		
		-- Definir el tipo para el histograma que tiene 8 celdas
        type Histograma_bloque is array (0 to 3) of Celda;

type array_hog is array (0 to 8) of std_logic_vector(15 downto 0);
type array_hog_norm is array (0 to 35) of std_logic_vector(16 downto 0);
type array_bloq is array (0 to 35) of std_logic_vector(15 downto 0);

end hogpack;

package body hogpack is
end hogpack;
