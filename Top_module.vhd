----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.12.2024 09:03:48
-- Design Name: 
-- Module Name: Top_module - Behavioral
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

entity top_hog_axi is
    Port (
        clk           : in  STD_LOGIC;                    -- Reloj
        reset         : in  STD_LOGIC;                    -- Reset
        s_axis_tvalid : in  STD_LOGIC;                    -- AXI Stream valid
        s_axis_tdata  : in  STD_LOGIC_VECTOR(7 downto 0); -- Entrada de p√≠xel (8 bits)
        s_axis_tready : out STD_LOGIC;                    -- AXI Stream ready
        out_grad_valid :    out STD_LOGIC;                    -- AXI Stream ready
        m_axis_tvalid : out STD_LOGIC;                    -- AXI Stream valid (salida)
        m_axis_tdata  : out STD_LOGIC_VECTOR(15 downto 0); -- Histograma del bloque (36 bins x 16 bits)
        gradx  : out STD_LOGIC_VECTOR(9 downto 0); -- Histograma del bloque (36 bins x 16 bits)
        grady  : out STD_LOGIC_VECTOR(9 downto 0); -- Histograma del bloque (36 bins x 16 bits)
        out_magnitud        : out  STD_LOGIC_VECTOR(9 downto 0) -- magnitud
    );
end top_hog_axi;

architecture Behavioral of top_hog_axi is
    -- Se√±ales internas
    signal grad_x, grad_y : STD_LOGIC_VECTOR(9 downto 0); -- Gradientes de Sobel
    signal grad_valid     : STD_LOGIC;                   -- Gradientes v√°lidos
    signal fifo_histograms : Histograma_fifo_type; -- FIFO de histogramas (8 celdas)
    signal fifo_valid     : STD_LOGIC;                   -- Se√±al FIFO v√°lida
    signal cell_histogram : STD_LOGIC_VECTOR(144-1 downto 0);   -- Histograma actual de celda
    signal block_histogram : STD_LOGIC_VECTOR(575 downto 0);    -- Histograma del bloque
    signal block_valid     : STD_LOGIC;                  -- Bloque v√°lido
    signal s_ready_histo    : STD_LOGIC;           
    signal s_start_bina    : STD_LOGIC;           
    
    signal serialized_histogram : STD_LOGIC_VECTOR(15 downto 0); -- Ancho reducido.
    signal serialized_valid : STD_LOGIC := '0';
    signal serialization_index : integer range 0 to 35 := 0;      

    -- √?ndice para selecci√≥n de histogramas en FIFO
    signal cell_index : integer range 0 to 7 := 0;
    
     constant HP : INTEGER := 34;
     constant PBW : INTEGER := 8;
     signal s_fin_cel_edge :  STD_LOGIC;
     signal s_hready : STD_LOGIC := '0';
     signal s_vready : STD_LOGIC := '0';
     signal s_lock_ultimo_bloque : STD_LOGIC := '0';
     signal s_celda : STD_LOGIC_vector(3 downto 0);     
     signal s_binarized_histogram : STD_LOGIC_vector(35 downto 0);     
     signal s_contador : integer range 0 to 9;     
--     type Histograma_bloque is array (0 to 3) of Celda;
     signal s_hist_bloque : Histograma_bloque;
    -- Componentes
--    component fifo_sobel
--        Port (
--            clk           : in  STD_LOGIC;
--            reset         : in  STD_LOGIC;
--            ready_histo   : in  STD_LOGIC;
--            s_axis_tvalid : in  STD_LOGIC;
--            s_axis_tdata  : in  STD_LOGIC_VECTOR(7 downto 0);
--            s_axis_tready : out STD_LOGIC;
--            grad_x_out    : out STD_LOGIC_VECTOR(8 downto 0);
--            grad_y_out    : out STD_LOGIC_VECTOR(8 downto 0);
--            grad_valid_out : out STD_LOGIC
--        );
--    end component;

component edge_detection is
    generic ( MBW : INTEGER;
              PBW : INTEGER;
              HP : INTEGER);
    port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start : in STD_LOGIC;
           pixel_in : in STD_LOGIC_VECTOR(PBW-1 downto 0);
           ack_out : out STD_LOGIC; -- Flag that indicates next input can be sent.
           ack_in : in STD_LOGIC; --vem do coridc
           fin_cel_edge : in STD_LOGIC;
           h_ready : out STD_LOGIC;
           v_ready : out STD_LOGIC;
           h_pixel_out : out STD_LOGIC_VECTOR(PBW+1 downto 0);
           v_pixel_out : out STD_LOGIC_VECTOR(PBW+1 downto 0));
end component;

    component hog_cell_histogram_with_fifo
        Generic (
            NUM_BINS  : integer := 9;
            BIN_WIDTH : integer := 16;
            FIFO_SIZE : integer := 8
        );
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            ready_histo   : out  STD_LOGIC;
            grad_x_in       : in  STD_LOGIC_VECTOR(9 downto 0);
            grad_y_in       : in  STD_LOGIC_VECTOR(9 downto 0);
            magnitud        : out  STD_LOGIC_VECTOR(9 downto 0); -- magnitud
            grad_valid_in   : in  STD_LOGIC;
            fifo_histograms : out Histograma_fifo_type; -- Todos los histogramas
            fifo_valid      : out STD_LOGIC;
            Celda           : out std_logic_vector(3 downto 0)
        );
    end component;

    component hog_block_histogram
         Generic (
        NUM_BINS  : integer := 9;   -- N˙mero de bins en el histograma
        BIN_WIDTH : integer := 16;  -- Ancho de cada bin
        BLOCK_SIZE : integer := 4   -- N˙mero de celdas en un bloque
    );
    Port (
        clk                  : in  STD_LOGIC;                                    -- Reloj
        reset                : in  STD_LOGIC;                                    -- Reset
        block_histogram_in   : in  Histograma_bloque; -- Entrada de histograma en arreglo tridimensional
        block_valid_in       : in  STD_LOGIC;                                    -- SeÒal de validez del bloque de entrada
        binarized_histogram  : out STD_LOGIC_VECTOR(BLOCK_SIZE*NUM_BINS-1 downto 0); -- Histograma binarizado
        block_valid          : out STD_LOGIC                                     -- SeÒal de validez del histograma de salida
    );
     end component;

begin
    
    --sinais para teste
    out_grad_valid<=s_ready_histo;
    gradx<=grad_x;
    grady<=grad_y;
    
    -- Instancia del m√≥dulo FIFO Sobel
--    fifo_sobel_inst : fifo_sobel
--        Port map (
--            clk           => clk,
--            reset         => reset,
--            ready_histo => s_ready_histo,
--            s_axis_tvalid => s_axis_tvalid,
--            s_axis_tdata  => s_axis_tdata,
--            s_axis_tready => s_axis_tready,
--            grad_x_out    => grad_x,
--            grad_y_out    => grad_y,
--            grad_valid_out => grad_valid
--        );

U_sobel: edge_detection 
    generic map(MBW => PBW,
                PBW => PBW,
                HP => HP)
    port map(clk => clk,
             reset => reset,
             start => s_axis_tvalid,
             pixel_in => s_axis_tdata,
             ack_out=>s_axis_tready,
             ack_in=>s_ready_histo,
             fin_cel_edge=>s_fin_cel_edge,
             h_ready => grad_valid,
             v_ready => s_vready ,
             h_pixel_out => grad_x,
             v_pixel_out => grad_y
             ); 


    -- Instancia del m√≥dulo HOG Cell Histogram con FIFO
 hog_cell_histogram_inst : hog_cell_histogram_with_fifo
        Generic map (
            NUM_BINS  => 9,
            BIN_WIDTH => 16,
            FIFO_SIZE => 8
        )
        Port map (
            clk             => clk,
            reset           => reset,
            ready_histo => s_ready_histo,
            grad_x_in       => grad_x,
            grad_y_in       => grad_y,
            grad_valid_in   => grad_valid,
            fifo_histograms => fifo_histograms,
            fifo_valid      => fifo_valid,
            celda           =>s_celda,
            magnitud        =>out_magnitud
        );

    -- Selecci√≥n del histograma actual del FIFO
--    cell_histogram <= fifo_histograms(144*(cell_index+1)-1 downto 144*cell_index);

    -- Instancia del m√≥dulo HOG Block Formation
    hog_block_histogram_inst : hog_block_histogram
        Generic map (
            NUM_BINS  => 9,
            BIN_WIDTH => 16
        )
        Port map (
            clk             => clk,
            reset           => reset,
            block_histogram_in  => s_hist_bloque,
            block_valid_in      => s_start_bina,
            binarized_histogram => s_binarized_histogram,
            block_valid     => block_valid            
        );
     
--     Proceso para separacion de bloques
blocos: process(clk,reset,s_celda,s_ready_histo)
begin
if rising_edge(clk) then
    if reset='1' then
    s_contador<=0;
    s_start_bina<='0';
    s_lock_ultimo_bloque<='0'; 
    
    else
        s_start_bina<='0';
        if fifo_valid='1' then
            s_contador<=s_contador+1;
             if s_contador=2 then
                s_hist_bloque(0)<=fifo_histograms(0);
                s_hist_bloque(1)<=fifo_histograms(1);
                s_hist_bloque(2)<=fifo_histograms(4);
                s_hist_bloque(3)<=fifo_histograms(5);
--                s_start_bina<='1';
             end if;
             if s_contador=3 then
                s_hist_bloque(0)<=fifo_histograms(1);
                s_hist_bloque(1)<=fifo_histograms(2);
                s_hist_bloque(2)<=fifo_histograms(5);
                s_hist_bloque(3)<=fifo_histograms(6);
--                s_start_bina<='1';
             end if;
             if s_contador=4 then
                s_hist_bloque(0)<=fifo_histograms(2);
                s_hist_bloque(1)<=fifo_histograms(3);
                s_hist_bloque(2)<=fifo_histograms(6);
                s_hist_bloque(3)<=fifo_histograms(7);
--                s_start_bina<='1';
             end if;
             if s_contador=5 then
                s_hist_bloque(0)<=fifo_histograms(4);
                s_hist_bloque(1)<=fifo_histograms(5);
                s_hist_bloque(2)<=fifo_histograms(8);
                s_hist_bloque(3)<=fifo_histograms(9);
--                s_start_bina<='1';
             end if;
             if s_contador=6 then
                s_hist_bloque(0)<=fifo_histograms(5);
                s_hist_bloque(1)<=fifo_histograms(6);
                s_hist_bloque(2)<=fifo_histograms(9);
                s_hist_bloque(3)<=fifo_histograms(10);
--                s_start_bina<='1';
             end if;
             if s_contador=7 then
                s_hist_bloque(0)<=fifo_histograms(6);
                s_hist_bloque(1)<=fifo_histograms(7);
                s_hist_bloque(2)<=fifo_histograms(10);
                s_hist_bloque(3)<=fifo_histograms(11);
--                s_start_bina<='1';
             end if;
             if s_contador=12 then
                s_hist_bloque(0)<=fifo_histograms(8);
                s_hist_bloque(1)<=fifo_histograms(9);
                s_hist_bloque(2)<=fifo_histograms(12);
                s_hist_bloque(3)<=fifo_histograms(13);
--                s_start_bina<='1';
             end if;
             if s_contador=13 then
                s_hist_bloque(0)<=fifo_histograms(9);
                s_hist_bloque(1)<=fifo_histograms(10);
                s_hist_bloque(2)<=fifo_histograms(13);
                s_hist_bloque(3)<=fifo_histograms(14);
--                s_start_bina<='1';
             end if;--           
             if s_contador>1 and s_contador<14 then
                s_start_bina<='1';
             end if;             
        end if;           
    end if;
    if s_ready_histo='1' and s_contador=20 then
                if s_lock_ultimo_bloque='1' then
                    s_hist_bloque(0)<=fifo_histograms(10);
                    s_hist_bloque(1)<=fifo_histograms(11);
                    s_hist_bloque(2)<=fifo_histograms(14);
                    s_hist_bloque(3)<=fifo_histograms(15);
                    s_start_bina<='1';
                    end if;
           s_lock_ultimo_bloque<='1';
        end if;
end if;    
end process;
     
        
        -- SerializaciÛn de los datos de salida
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                serialized_histogram <= (others => '0');
                serialized_valid <= '0';
                serialization_index <= 0;
            elsif block_valid = '1' then
                serialized_histogram <= block_histogram((serialization_index+1)*16-1 downto serialization_index*16);
                serialization_index <= (serialization_index + 1) mod 36;
                serialized_valid <= '1';
            else
                serialized_valid <= '0';
            end if;
        end if;
    end process;

    -- Salidas optimizadas
    m_axis_tvalid <= serialized_valid;
    m_axis_tdata <= serialized_histogram;

--    -- Salida del flujo AXI
--    m_axis_tvalid <= block_valid;
--    m_axis_tdata  <= block_histogram;

end Behavioral;
