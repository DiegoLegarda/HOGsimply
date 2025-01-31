-------------------------------------------------
-- Company:       GRACO-UnB
-- Engineer:      DANIEL MAURICIO MUÑOZ ARBOLEDA
-- 
-- Create Date:   27-Jun-2023 
-- Design name:   FPUs
-- Module name:   fpupack
-- Description:   This package defines types, subtypes and constants
-- Automatically generated using the vFPUgen.m v1.0
-------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package fpupack is

constant FRAC_WIDTH : integer := 23;
constant EXP_WIDTH : integer := 8;
constant FP_WIDTH : integer:= FRAC_WIDTH+EXP_WIDTH+1;

constant bias : std_logic_vector(EXP_WIDTH-1 downto 0) := "01111111";
constant int_bias : integer := 127;
constant int_alin : integer := 255;
constant EXP_DF : std_logic_vector(EXP_WIDTH-1 downto 0) := "10000010";
constant bias_MAX : std_logic_vector(EXP_WIDTH-1 downto 0) := "10000110";
constant bias_MIN : std_logic_vector(EXP_WIDTH-1 downto 0) := "01110101";
constant EXP_ONE: std_logic_vector(EXP_WIDTH-1 downto 0):= (others => '1');
constant EXP_INF : std_logic_vector(EXP_WIDTH-1 downto 0) := "11111111";

constant s_one : std_logic_vector(FP_WIDTH-1 downto 0) := "00111111100000000000000000000000";
constant s_ten : std_logic_vector(FP_WIDTH-1 downto 0) := "01000001001000000000000000000000";
constant s_twn : std_logic_vector(FP_WIDTH-1 downto 0) := "01000001101000000000000000000000";
constant s_hundred : std_logic_vector(FP_WIDTH-1 downto 0) := "01000010110010000000000000000000";
constant s_pi : std_logic_vector(FP_WIDTH-1 downto 0) := "01000000010010010000111111011010";
constant s_3pi2 : std_logic_vector(FP_WIDTH-1 downto 0) := "01000000100101101100101111100011";
constant s_2pi : std_logic_vector(FP_WIDTH-1 downto 0) := "01000000110010010000111111011010";

constant P	: std_logic_vector(FP_WIDTH-1 downto 0) := "00111111000110110111010011101101"; --PROD[cos(atan(1/2^i))]
constant s_pid2 : std_logic_vector(FP_WIDTH-1 downto 0) := "00111111110010010000111111011010";
constant s_2dpi : std_logic_vector(FP_WIDTH-1 downto 0) := "00111111001000101111100110000011";

constant Phyp	: std_logic_vector(FP_WIDTH-1 downto 0) := "00111111100110100100000111101000"; --PROD[cosh(atanh(1/2^i))]
constant log2e	: std_logic_vector(FP_WIDTH-1 downto 0) := "00111111101110001010101000111011";
constant ilog2e	: std_logic_vector(FP_WIDTH-1 downto 0) := "00111111001100010111001000010111";
constant d_043 	: std_logic_vector(FP_WIDTH-1 downto 0) := "00111101001100001000100110100000";

constant MAX_ITER_CORDIC : std_logic_vector(4 downto 0):= "10100";
constant MAX_POLY_MACKLR : std_logic_vector(3 downto 0):= "0011";

constant OneM: std_logic_vector(FRAC_WIDTH downto 0) := "100000000000000000000000";
constant Zero: std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
constant Inf: std_logic_vector(FP_WIDTH-1 downto 0) := "01111111100000000000000000000000";
constant NaN: std_logic_vector(FP_WIDTH-1 downto 0) := "01111111110000000000000000000000";
constant TSed: POSITIVE := 15;
constant Niter: POSITIVE := 3;

end fpupack;

package body fpupack is
end fpupack;
