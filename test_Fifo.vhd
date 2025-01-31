----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.12.2024 22:49:40
-- Design Name: 
-- Module Name: test_Fifo - Behavioral
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
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity testbench_top_hog is
end entity testbench_top_hog;

architecture Behavioral of testbench_top_hog is
    -- Declaración del componente principal (DUT)
    component top_hog_axi
        Port (
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            s_axis_tvalid : in  STD_LOGIC;
            out_grad_valid :    out STD_LOGIC;
            s_axis_tdata  : in  STD_LOGIC_VECTOR(7 downto 0);
            s_axis_tready : out STD_LOGIC;
            m_axis_tvalid : out STD_LOGIC;
            m_axis_tdata  : out STD_LOGIC_VECTOR(15 downto 0);
            gradx  : out STD_LOGIC_VECTOR(9 downto 0); -- Histograma del bloque (36 bins x 16 bits)
            grady  : out STD_LOGIC_VECTOR(9 downto 0);
            out_magnitud        : out  STD_LOGIC_VECTOR(9 downto 0) -- magnitud
        );
    end component;

    -- Señales internas
    signal clk           : STD_LOGIC := '0';
    signal reset         : STD_LOGIC := '1';
    signal s_axis_tvalid : STD_LOGIC := '0';
    signal s_axis_tdata  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal s_axis_tready : STD_LOGIC := '0';
    signal m_axis_tvalid : STD_LOGIC := '0';
    signal m_axis_tdata  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal sgradx  : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal sgrady  : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal smagnitud  : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal sstar_ini   : std_logic:= '0';
    signal WOMenable   : std_logic:='0';
    signal sout_grad_valid  : std_logic:='0';
    

    -- Clock
    constant clk_period : time := 10 ns;

    -- Contador
    signal pixel_count : integer := 0;

    -- Archivos
    file infile_pixels     : text open READ_MODE is "pixeles.txt";
    file outfile_histogram : text open WRITE_MODE is "histograma.txt";

begin


    -- Instancia del DUT
    uut: top_hog_axi
        Port map (
            clk           => clk,
            reset         => reset,
            s_axis_tvalid => s_axis_tvalid,
            out_grad_valid=>sout_grad_valid,
            s_axis_tdata  => s_axis_tdata,
            s_axis_tready => s_axis_tready,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tdata  => m_axis_tdata,
            gradx=>sgradx,
            grady=>sgrady,
            out_magnitud=>smagnitud
        );

    -- Generador de reloj
    clk_process: process
    begin
        while true loop
            clk <= not clk;
            wait for clk_period / 2;
        end loop;
    end process;
    reset <= '0', '1' after 25 ns, '0' after 45 ns;
     sstar_ini <= '0', '1' after 55 ns, '0' after 65 ns;

--    -- Proceso principal para leer píxeles y escribir histogramas
--    main_process: process
--        variable file_line_in  : line;
--        variable file_line_out : line;
--        variable data_pixels   : integer;
--    begin
--        -- Reset inicial
--        reset <= '1';
--        wait for clk_period * 10;
--        reset <= '0';
--        wait for clk_period;
--    end process;
--        -- Inicializar variables
--        s_axis_tvalid <= '0';
--        s_axis_tdata <= (others => '0');
--        pixel_count <= 0;

--        -- Lectura de píxeles
--        while not endfile(infile_pixels) loop
--            readline(infile_pixels, file_line_in);
--            read(file_line_in, data_pixels); -- Leer entero desde archivo
--            s_axis_tdata <= std_logic_vector(to_unsigned(data_pixels, 8)); -- Convertir entero a std_logic_vector

--            -- Enviar datos al DUT
--            s_axis_tvalid <= '1';
--            wait until rising_edge(clk);

--            while s_axis_tready = '0' loop
--                wait until rising_edge(clk);
--            end loop;

--            -- Desactivar tvalid después de enviar el dato
--            s_axis_tvalid <= '0';
--            wait until rising_edge(clk);

--            -- Comprobar si hay datos disponibles para escribir el histograma
--            if m_axis_tvalid = '1' then
--                hwrite(file_line_out, m_axis_tdata);
--                writeline(outfile_histogram, file_line_out);
--            end if;

--            -- Incrementar contador de píxeles
--            pixel_count <= pixel_count + 1;
--        end loop;

--        -- Cierre de archivos
--        file_close(infile_pixels);
--        file_close(outfile_histogram);


--        -- Finalización
--        report "Lectura completada y histograma generado" severity note;
--        wait;
--    end process;



  romX: process(clk)
        file infile_pixel: text is in "pixeles.txt";  --test en Binario
        variable inline_pixel: line;
        variable data_pixel: std_logic_vector(7 downto 0); -- Ajustar tamaño
    begin
        if rising_edge(clk) then
--            sstart <= '0';
    if reset='1' then
        pixel_count <=0;
    end if;
    s_axis_tvalid <= '0';
            if not endfile(infile_pixel) then
                if sstar_ini = '1' or s_axis_tready = '1'  then
                    s_axis_tvalid <= '1';
                    readline(infile_pixel, inline_pixel);
                    read(inline_pixel, data_pixel);
                    s_axis_tdata <= data_pixel;
--                    sstart <= '1';
                    if reset='0' then
                    pixel_count <= pixel_count + 1;
                    end if;
                end if;
            elsif endfile(infile_pixel) then
                report "End of pixel file" severity note;
            end if;
        end if;
    end process;

WOMenable <= sout_grad_valid;

    wom_out: process(clk)
        variable out_line: line;
        file out_file: text is out "gradx.txt";
        file out_file2: text is out "grady.txt";
        file out_file3: text is out "magnitud.txt";
    begin
        if rising_edge(clk) then
            if WOMenable = '1' then
                write(out_line, sgradx);
                writeline(out_file, out_line);
                write(out_line, sgrady);
                writeline(out_file2, out_line);
                write(out_line, smagnitud);
                writeline(out_file3, out_line);
            end if;
        end if;
    end process;


end architecture Behavioral;
