----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2014 09:25:56 AM
-- Design Name: 
-- Module Name: mmc_core_pkg - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package mmc_core_pkg is

    -- Response encoding
    constant RESP_NONE  : std_logic_vector(2 downto 0)  := "000";
    constant RESP_R1    : std_logic_vector(2 downto 0)  := "001";
    constant RESP_R1B   : std_logic_vector(2 downto 0)  := "010";
    constant RESP_R2    : std_logic_vector(2 downto 0)  := "011";
    constant RESP_R3    : std_logic_vector(2 downto 0)  := "100";
    constant RESP_R4    : std_logic_vector(2 downto 0)  := "101";
    constant RESP_R5    : std_logic_vector(2 downto 0)  := "110";
end mmc_core_pkg;