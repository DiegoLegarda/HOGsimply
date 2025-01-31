------------------------------------------------------------
-- Author: Victor Bastos Imbrosio Oliveira - 16/0041163
-- Affiliation: UnB Faculdade do Gama
------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity edge_detection is
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
end edge_detection;

architecture Behavioral of edge_detection is

    component FIFO_control is
        generic ( PBW : INTEGER;
                  HP : INTEGER);
        port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               start : in STD_LOGIC;
               pixel_in : in STD_LOGIC_VECTOR(PBW-1 downto 0);
               ack : out STD_LOGIC;
               fin_cel : in STD_LOGIC;
               border_out : out STD_LOGIC;
               neigh_ready : out STD_LOGIC;
               --           pixel_11 : out STD_LOGIC_VECTOR(PBW downto 0);
           pixel_12 : out STD_LOGIC_VECTOR(PBW downto 0);
--           pixel_13 : out STD_LOGIC_VECTOR(PBW downto 0);
           pixel_21 : out STD_LOGIC_VECTOR(PBW downto 0);
--           pixel_22 : out STD_LOGIC_VECTOR(PBW downto 0);
           pixel_23 : out STD_LOGIC_VECTOR(PBW downto 0);
--           pixel_31 : out STD_LOGIC_VECTOR(PBW downto 0));
           pixel_32 : out STD_LOGIC_VECTOR(PBW downto 0));

    end component;
    
    component horizontal_gradient is
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
    end component;
    
    component vertical_gradient is
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
    end component;
    
    signal s_pixel_12 : STD_LOGIC_VECTOR(PBW downto 0);
    signal s_pixel_21 : STD_LOGIC_VECTOR(PBW downto 0);
    signal s_pixel_23 : STD_LOGIC_VECTOR(PBW downto 0);
    signal s_pixel_32 : STD_LOGIC_VECTOR(PBW downto 0);
    

    
    signal s_neigh_ready : STD_LOGIC := '0';
    signal s_cont_pixel : STD_LOGIC_VECTOR(2 DOWNTO 0):=(others => '0');
    signal s_h_ready : STD_LOGIC := '0';
    signal border : STD_LOGIC := '0';
    signal s_start : STD_LOGIC := '0';
    signal h_aux_ready : STD_LOGIC := '0';
    signal s_ack : STD_LOGIC := '0';
    
    
begin
--ack_out <= s_ack;
process(clk,reset,s_ack,ack_in,h_aux_ready,border,s_cont_pixel)
begin
 if rising_edge(clk) then
   
        if reset='1' then
        ack_out<='0';
        s_start<='0';
        else
         if h_aux_ready='1'and border='0' then 
           ack_out<=ack_in;
           
           elsif h_aux_ready='1'and border='1' then 
           ack_out<=s_neigh_ready or s_ack;
           s_start<=start;
           else           
           ack_out<=s_ack;  
             
         end if;
         if  s_cont_pixel<"110010100011" then
            s_start<=start;
         elsif border='1' and s_cont_pixel<"001" then
            s_start<=start;
         else
            s_start<=ack_in;   
            
         end if;
      end if;

end if;
end process;


process(clk,reset,s_h_ready,fin_cel_edge)
begin
 if rising_edge(clk) then
   
        if reset='1' then
        h_aux_ready<='0';
        
         elsif s_h_ready='1'then 
           h_aux_ready<='1';           
         
         elsif fin_cel_edge='1' then 
           h_aux_ready<='0';            
         end if;
      end if;
end process;


cont_bits_border:process(clk,reset,s_ack,ack_in,h_aux_ready,border)
begin
 if rising_edge(clk) then
   
        if reset='1' then
        s_cont_pixel<=(others => '0');
        elsif border='1'then 
           s_cont_pixel<=std_logic_vector(unsigned(s_cont_pixel)+1);
           if   s_cont_pixel>"110010100010" then
            s_cont_pixel<=(others => '0');
           end if;
        else
             s_cont_pixel<=(others => '0');              
         end if;
      end if;
end process;

    A1: FIFO_control
    generic map(PBW => PBW,
                HP => HP)
    port map(clk => clk,
             reset => reset,
             start => s_start,
             pixel_in => pixel_in,
             ack => s_ack,
             fin_cel=>fin_cel_edge,
             border_out=>border,
             neigh_ready => s_neigh_ready,
             pixel_12 => s_pixel_12,
             pixel_21 => s_pixel_21,
             pixel_23 => s_pixel_23,
             pixel_32 => s_pixel_32);

             
    A2: horizontal_gradient
    generic map(MBW => MBW,
                PBW => PBW,
                HP => HP)
    port map(clk => clk,
             reset => reset,
             start => s_neigh_ready,
             pixel_21 => s_pixel_21,
             pixel_23 => s_pixel_23,
             h_ready => s_h_ready,
             h_pixel_out => h_pixel_out);
             h_ready<=s_h_ready;
    A3: vertical_gradient
    generic map(MBW => MBW,
                PBW => PBW,
                HP => HP)
    port map(clk => clk,
             reset => reset,
             start => s_neigh_ready,
             pixel_12 => s_pixel_12,
             pixel_32 => s_pixel_32,
             v_ready => v_ready,
             v_pixel_out => v_pixel_out);
             
end Behavioral;