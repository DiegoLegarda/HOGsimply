----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Diego Legarda
-- GAMMA UNB

-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Hogpack.all;

entity hog_cell_histogram_with_fifo is
    Generic (
        NUM_BINS  : integer := 9;   -- Número de bins en el histograma
        BIN_WIDTH : integer := 16;  -- Ancho de cada bin
        FIFO_SIZE : integer := 16 ;   -- Tamaño del FIFO (16 histograma, mudar a 8 histogramas)
        IMG_WIDTH    : integer := 32; -- Ancho de la imagen con padding
        CELL_SIZE    : integer := 8  -- Tamaño de la celda
    );
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        ready_histo   : out STD_LOGIC;
        grad_x_in       : in  STD_LOGIC_VECTOR(9 downto 0); -- Gradiente X
        grad_y_in       : in  STD_LOGIC_VECTOR(9 downto 0); -- Gradiente Y
        magnitud        : out  STD_LOGIC_VECTOR(9 downto 0); -- magnitud
        grad_valid_in   : in  STD_LOGIC;                   -- Validez del gradiente
        fifo_histograms : out Histograma_fifo_type; -- Todos los histogramas
        fifo_valid      : out STD_LOGIC;                   -- Señal FIFO válida
        Celda           : out std_logic_vector(3 downto 0)
    );
end hog_cell_histogram_with_fifo;

architecture Behavioral of hog_cell_histogram_with_fifo is

    type tan_theta_array is array(0 to NUM_BINS) of integer;


 
        signal Histograma_fifo : Histograma_fifo_type;

    -- Señales internas
--    signal fifo_reg : fifo_type := (others => (others => (others => '0')));
    signal write_ptr : integer range 0 to FIFO_SIZE-1 := 0;
    signal pixel_counter_x : integer range 0 to 7 := 0;
    signal pixel_counter_y : integer range 0 to 7 := 0;
    signal histogram_complete : STD_LOGIC := '0';
    signal mag_complete : STD_LOGIC := '0';
    signal bin_complete : STD_LOGIC := '0';
    signal calc_complete : STD_LOGIC := '0';
    signal s_start : STD_LOGIC := '0';
    signal lock : STD_LOGIC := '0';
    signal s_mag: std_logic_vector(9 downto 0) := (others => '0');
    
    signal aux_a, aux_b : unsigned(7 downto 0);
    signal aux_result,aux_mag:unsigned(15 downto 0);
    
    signal abs_Gx, abs_Gy: std_logic_vector(9 downto 0);
    signal s_bin: integer range 0 to 8 := 0;
    signal contador: integer range 0 to 3 := 0;
    signal a, b: std_logic_vector(9 downto 0);
    signal temp1, temp2: std_logic_vector(9 downto 0);
    signal calc_counter: integer := 0;
    constant CALC_LATENCY: integer := 3;
    
    
    --variables para determinar celda
    -- Constantes internas
    constant CELLS_PER_ROW : integer := IMG_WIDTH / CELL_SIZE;

    -- Señales internas
    signal x_counter        : integer range 0 to IMG_WIDTH-1 := 0; -- Contador de píxeles en x
    signal y_counter        : integer range 0 to IMG_WIDTH-1 := 0; -- Contador de píxeles en y
    signal cell_x_counter   : integer range 0 to CELLS_PER_ROW-1 := 0; -- Contador de celdas en x
    signal prev_cell_x_counter   : integer range 0 to CELLS_PER_ROW-1 := 0; -- Contador de celdas en x
    signal cell_y_counter   : integer range 0 to CELLS_PER_ROW-1 := 0; -- Contador de celdas en y
    signal cell_idx         : integer range 0 to (CELLS_PER_ROW * CELLS_PER_ROW) - 1 := 0; -- �?ndice de celda
    signal prev_cell_idx         : integer range 0 to (CELLS_PER_ROW * CELLS_PER_ROW) - 1 := 0; -- �?ndice de celda
    signal cell_histogram_ready : STD_LOGIC := '0';
    signal grad_x : signed(9 downto 0);
    signal grad_y : signed(9 downto 0);
--    signal tan_theta : tan_theta_array;
   

    -- Constante de tangentes escaladas
    constant TAN_THETA : tan_theta_array := (
    0,      -- tan(0°)   * 1024
    376,    -- tan(20°)  * 1024
    839,    -- tan(40°)  * 1024
    1494,   -- tan(60°)  * 1024
    2792,   -- tan(80°)  * 1024
    -2792,  -- tan(100°) * 1024
    -1494,  -- tan(120°) * 1024
    -839,   -- tan(140°) * 1024
    -376,   -- tan(160°) * 1024
    0       -- tan(180°) * 1024
);



    -- Función para clasificar bin con implementación optimizada
--function fast_classify_bin(
--    grad_x : signed(9 downto 0);
--    grad_y : signed(9 downto 0);
--    tan_theta : tan_theta_array
--) return integer is
--    variable gx_scaled, gy_scaled : integer;
--    variable bin : integer := 0;
--    variable ratio : integer;
--begin
    
--    -- Caso vertical: gx = 0
--    if grad_x = 0 then
--        if grad_y >= 0 then
--            bin := 4;
--        else
--            bin := 4;
--        end if;
--        return bin;
--    end if;

--    -- Caso horizontal: gy = 0
--    if grad_y = 0 then
--        if grad_x >= 0 then
--            bin := 0;
--        else
--            bin := 8;
--        end if;
--        return bin;
--    end if;

--    -- Escalar gradientes
--    gx_scaled := to_integer(abs(grad_x));
--    gy_scaled := to_integer(abs(grad_y));
    
--    -- Calcular la proporción gy/gx * 1024
--    if gx_scaled=0 then
--    ratio:=1000000;
--    else
--    ratio := (gy_scaled * 1024) / gx_scaled;
--    end if;
--    -- Cuadrante 1 y 2 (0-180)
--    if grad_y >= 0 then
--        for i in 0 to 8 loop
--            if ratio >= abs(tan_theta(i)) and ratio < abs(tan_theta(i+1)) then
--                if grad_x >= 0 then
--                    bin := i;  -- Cuadrante 1
--                else
--                    bin := 8 - i;  -- Cuadrante 2
--                end if;
--                exit;
--            end if;
--        end loop;
--    -- Cuadrante 3 y 4 (180-360)
--   -- Cuadrante 3 y 4 (180-360)
--else
--    if ratio >= abs(tan_theta(4)) then  -- Si el ratio es mayor que tan(80°)
--        bin := 4;
--    else
--        for i in 0 to 8 loop
--            if ratio >= abs(tan_theta(i)) and ratio < abs(tan_theta(i+1)) then
--                if grad_x < 0 then
--                    bin := i;  -- Cuadrante 3
--                else
--                    bin := 8 - i;  -- Cuadrante 4
--                end if;
--                exit;
--            end if;
--        end loop;
--    end if;
--end if;

--    return bin;
--end function;



begin
    ready_histo<=mag_complete;
    -- Proceso principal de cálculo de histograma
    process(clk,grad_valid_in)
       
        variable magnitude : unsigned(9 downto 0);
       
    begin
        if rising_edge(clk) then
            -- Reset global
            if reset = '1' then
--                fifo_reg <= (others => (others => (others => '0')));
          
--                current_histogram <= (others => (others => '0'));
                pixel_counter_x <= 0;
                pixel_counter_y <= 0;
                
                
                calc_counter <= 0;
                mag_complete<='0';
                s_start<='0';
                
              
            else
                mag_complete<='0';
               -- s_start<='0';
                -- Proceso de cálculo de histograma
                if grad_valid_in = '1' then
                s_start<='1';
                end if;
                    if s_start='1' then
                    
                    calc_counter <= calc_counter + 1;
                    if grad_x_in(8) = '1' then
                        abs_Gx <= std_logic_vector(unsigned(not(grad_x_in)) + 1);
                    else
                        abs_Gx <= grad_x_in;
                    end if;

                    if grad_y_in(8) = '1' then
                        abs_Gy <= std_logic_vector(unsigned(not(grad_y_in)) + 1);
                    else
                        abs_Gy <= grad_y_in;
                    end if;

                    -- Determine a and b
                    if unsigned(abs_Gx) > unsigned(abs_Gy) then
                        a <= abs_Gx;
                        b <= abs_Gy;
                    else
                        a <= abs_Gy;
                        b <= abs_Gx;
                    end if;

                    -- Approximate 0.875 * a as a - (a >> 3)
                    temp1 <= std_logic_vector(unsigned(a) - (unsigned(a) srl 3));

                    -- Approximate 0.5 * b as b >> 1
                    temp2 <= std_logic_vector(unsigned(b) srl 1);
                    if calc_counter = CALC_LATENCY then
                        calc_counter <= 0;
                        mag_complete<='1';
                        s_start<='0';
                        if unsigned(temp1) + unsigned(temp2) > unsigned(a) then
                                s_mag <= std_logic_vector(unsigned(temp1) + unsigned(temp2));
                            else
                                s_mag <= a;
                            end if;
                         magnitude:=unsigned(s_mag);
                    end if;
                    
--                    smag<=magnitude;
----                    bin_index := fast_classify_bin(
--                        signed(grad_x_in), 
--                        signed(grad_y_in),
--                        TAN_THETA
--                    );
                    
                
                else
                    -- Mantener señales cuando no hay entrada válida
--                    histogram_complete <= '0';
--                    fifo_valid <= '0';
                end if;
            end if;
        end if;
    end process;
    
    
  Calculo_bin: process(clk)
    variable gx_scaled, gy_scaled : integer;
    variable bin : integer range 0 to 8 := 0;
    variable ratio : integer;
begin
    if rising_edge(clk) then
        -- Caso vertical: gx = 0
        if reset='1' then
            bin:=0;
            bin_complete<='0';
        else
         bin_complete<='0';
              if grad_valid_in = '1' then
                        if signed(grad_x_in) = 0 then
                            if signed(grad_y_in) >= 0 then
                                bin := 4;
                            else
                                bin := 4;
                            end if;
                        -- Caso horizontal: gy = 0
                        elsif signed(grad_y_in) = 0 then
                            if signed(grad_x_in) >= 0 then
                                bin := 0;
                            else
                                bin := 8;
                            end if;
                        else
                            -- Escalar gradientes
                            gx_scaled := to_integer(abs(signed(grad_x_in)));
                            gy_scaled := to_integer(abs(signed(grad_y_in)));
                            
                            -- Calcular la proporci�n gy/gx * 1024
                            if gx_scaled = 0 then
                                ratio := 1000000;
                            else
                                ratio := (gy_scaled * 1024) / gx_scaled;
                            end if;
                            
                            -- Cuadrante 1 y 2 (0-180)
                            if signed(grad_y_in) >= 0 then
                                for i in 0 to 8 loop
                                    if ratio >= abs(TAN_THETA(i)) and ratio < abs(TAN_THETA(i+1)) then
                                        if signed(grad_x_in) >= 0 then
                                            bin := i;  -- Cuadrante 1
                                        else
                                            bin := 8 - i;  -- Cuadrante 2
                                        end if;
                                        exit;
                                    end if;
                                end loop;
                            -- Cuadrante 3 y 4 (180-360)
                            else
                                if ratio >= abs(TAN_THETA(4)) then  -- Si el ratio es mayor que tan(80�)
                                    bin := 4;
                                else
                                    for i in 0 to 8 loop
                                        if ratio >= abs(TAN_THETA(i)) and ratio < abs(TAN_THETA(i+1)) then
                                            if signed(grad_x_in) < 0 then
                                                bin := i;  -- Cuadrante 3
                                            else
                                                bin := 8 - i;  -- Cuadrante 4
                                            end if;
                                            exit;
                                        end if;
                                    end loop;
                                end if;
                            end if;
                        end if;
                        
                        -- Asignar resultado al bin final
                        s_bin <= bin;
                        bin_complete<='1';
                    
                   end if; --fin del condicional de  grad_valid_in
              end if;  --fin del else general
    end if;
end process;


--Proceso que cuentas hasta 16 celdas
cont_celdas: process(clk, grad_valid_in, reset)
begin    
if rising_edge(clk) then
        if reset = '1' then
            x_counter <= 0;
            y_counter <= 0;
            cell_x_counter <= 0;
            cell_y_counter <= 0;
            cell_idx <= 0;
            histogram_complete <= '0';
            contador<=0;
            lock<='0';
            prev_cell_idx<=0;
            prev_cell_x_counter<=0;            
        else
            lock<='0';        
            if grad_valid_in = '1' then
                histogram_complete <= '0';                
                -- Incrementar x_counter
                if x_counter = IMG_WIDTH - 1 then
                    x_counter <= 0;
                    -- Incrementar y_counter
                    if y_counter = IMG_WIDTH - 1 then
                        y_counter <= 0;
                    else
                        y_counter <= y_counter + 1;
                    end if;
                else
                    x_counter <= x_counter + 1;
                end if;
    
                -- Actualizar contadores de celdas
                if (x_counter mod CELL_SIZE) = CELL_SIZE - 1 then
                    if cell_x_counter = CELLS_PER_ROW - 1 then
                        cell_x_counter <= 0;
                    else
                        cell_x_counter <= cell_x_counter + 1;
                    end if;
                end if;
    
                if (y_counter mod CELL_SIZE) = CELL_SIZE - 1 and x_counter = IMG_WIDTH - 1 then
                    if cell_y_counter = CELLS_PER_ROW - 1 then
                        cell_y_counter <= 0;
                    else
                        cell_y_counter <= cell_y_counter + 1;
                    end if;
                end if;
    
                -- Calcular el índice de celda
                cell_idx <= cell_y_counter * CELLS_PER_ROW + cell_x_counter;
            end if;
            
            --proceso para determinar histograma completo
            if cell_idx=8 or cell_idx=12 or cell_idx=15 then
                if cell_x_counter=1 and prev_cell_x_counter <= 0 then
                    contador<=contador+1; --contador de celdas
                    if (contador mod 3)=0 then  --se�al para inciar binarizaci� de bloques
                    lock<='1';                    
                    else
                    lock<='0';
               end if; 
                end if;
                if(cell_idx/=prev_cell_idx) then
                histogram_complete <= '1';
                     contador<=0;           
                end if;
                 
                prev_cell_idx<=cell_idx;
            end if;                                                               
            prev_cell_x_counter <= cell_x_counter;             
        end if;
end if;
end process;

--activaBinarizacion:process(clk,histogram_complete)
--begin
--    if rising_edge(clk) then
--        if reset = '1' then
--            lock<='0';
--        else
--            if histogram_complete='1' then
--                lock<=not lock;
--            end if;
--        end if;
--    end if;
--end process;

--Proceso que cuenta hasta 8 celdas dentro de la FIFO
---- Proceso que controla el contador de celdas dentro de la FIFO
--cont_celdas: process(clk, grad_valid_in, reset)
--begin
--    if reset = '1' then
--        -- Reiniciar todos los contadores e �ndices
--        x_counter <= 0;
--        y_counter <= 0;
--        cell_x_counter <= 0;
--        cell_y_counter <= 0;
--        cell_idx <= 0;
--        write_ptr <= 0;
--        cell_histogram_ready <= '0';
--    elsif rising_edge(clk) then
--        if grad_valid_in = '1' then
--            -- Incrementar x_counter y y_counter (coordenadas de p�xeles)
--            if x_counter = IMG_WIDTH - 1 then
--                x_counter <= 0;
--                if y_counter = IMG_WIDTH - 1 then
--                    y_counter <= 0;
--                else
--                    y_counter <= y_counter + 1;
--                end if;
--            else
--                x_counter <= x_counter + 1;
--            end if;

--            -- Actualizar contadores de celdas en X y Y
--            if (x_counter mod CELL_SIZE) = CELL_SIZE - 1 then
--                if cell_x_counter = CELLS_PER_ROW - 1 then
--                    cell_x_counter <= 0;
--                else
--                    cell_x_counter <= cell_x_counter + 1;
--                end if;
--            end if;

--            if (y_counter mod CELL_SIZE) = CELL_SIZE - 1 and x_counter = IMG_WIDTH - 1 then
--                if cell_y_counter = CELLS_PER_ROW - 1 then
--                    cell_y_counter <= 0;
--                else
--                    cell_y_counter <= cell_y_counter + 1;
--                end if;
--            end if;

--            -- Detectar si la celda actual est� completa
--            if (x_counter mod CELL_SIZE) = CELL_SIZE - 1 and 
--               (y_counter mod CELL_SIZE) = CELL_SIZE - 1 then
--                cell_histogram_ready <= '1'; -- Indicar que la celda est� completa

--                -- Calcular el �ndice de la celda y actualizar `write_ptr` cuando se llena
--                if cell_y_counter * CELLS_PER_ROW + cell_x_counter < FIFO_SIZE then
--                    cell_idx <= cell_y_counter * CELLS_PER_ROW + cell_x_counter;
--                else
--                    -- Rotar el puntero de escritura si FIFO est� llena
--                    cell_idx <= write_ptr;
--                    write_ptr <= (write_ptr + 1) mod FIFO_SIZE;
--                end if;
--            else
--                cell_histogram_ready <= '0'; -- La celda no est� completa
--            end if;
--        end if;
--    end if;
--end process;



ingreso_histograma:process(clk, grad_valid_in, reset, mag_complete, s_bin, cell_idx)
    variable bin_lower, bin_upper : integer;
    variable half_mag : unsigned(9 downto 0);
begin
    if rising_edge(clk) then
        if reset = '1' then
            Histograma_fifo <= (others => (others => (others => '0')));
            calc_complete<='0';            
        elsif mag_complete = '1'  then --teniendo en cuenta el processo mas lento calculo de magnitud
            calc_complete<='0';
            -- Distribuir mitad de la magnitud en dos bines adyacentes
            bin_lower := s_bin;
            bin_upper := (s_bin + 1) mod 9;            
            half_mag := unsigned(s_mag) srl 1;  -- Dividir magnitud entre 2
            
             if cell_idx < 16 then
                Histograma_fifo(cell_idx)(s_bin) <= 
                    std_logic_vector(unsigned(Histograma_fifo(cell_idx)(s_bin)) + unsigned(s_mag));
            end if;
        end if;
    end if;
end process;


magnitud<=s_mag;
fifo_histograms<=Histograma_fifo;
fifo_valid <= lock;
celda<=std_logic_vector(to_unsigned(cell_idx,4));
end Behavioral;

