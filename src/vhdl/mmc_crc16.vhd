----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2014 10:27:20 AM
-- Design Name: 
-- Module Name: mmc_crc16 - rtl
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

entity mmc_crc16 is
    Port ( clk : in std_logic;
           clk_en : in std_logic;
           reset : in std_logic;
           enable : in std_logic;
           
           serial_in : in std_logic;
           crc16_out : out std_logic_vector (15 downto 0)
           );
end mmc_crc16;

architecture rtl of mmc_crc16 is
    signal crc_reg : std_logic_vector (15 downto 0) := (others => '0');

begin

    crc16_out <= crc_reg;
 
    process
    begin
        wait until rising_edge(clk);
        
        if reset='1' then
            crc_reg <= (others => '0');
        
        elsif enable='1' and clk_en='1' then
            crc_reg(0) <= crc_reg(15) xor serial_in;
            crc_reg(1) <= crc_reg(0);
            crc_reg(2) <= crc_reg(1);
            crc_reg(3) <= crc_reg(2);
            crc_reg(4) <= crc_reg(3);
            crc_reg(5) <= crc_reg(4) xor crc_reg(15) xor serial_in;
            crc_reg(6) <= crc_reg(5);
            crc_reg(7) <= crc_reg(6);
            crc_reg(8) <= crc_reg(7);
            crc_reg(9) <= crc_reg(8);
            crc_reg(10) <= crc_reg(9);
            crc_reg(11) <= crc_reg(10);
            crc_reg(12) <= crc_reg(11) xor crc_reg(15) xor serial_in;
            crc_reg(13) <= crc_reg(12);
            crc_reg(14) <= crc_reg(13);
            crc_reg(15) <= crc_reg(14);
            
        end if;
    end process;

end rtl;
