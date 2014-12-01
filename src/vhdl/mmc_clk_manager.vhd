----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2014 09:41:53 AM
-- Design Name: 
-- Module Name: mmc_clk_manager - rtl
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mmc_clk_manager is
    Port ( clk : in std_logic;
           clk_en : in std_logic;
           reset : in std_logic;
           prescaler : in std_logic_vector (7 downto 0);
           mmc_clk : out std_logic;
           mmc_clk_rise : out std_logic;
           mmc_clk_fall : out std_logic);
end mmc_clk_manager;

architecture rtl of mmc_clk_manager is
    signal mmc_clk_i : std_logic := '0';
    signal mmc_clk_rise_i : std_logic := '0';
    signal mmc_clk_fall_i : std_logic := '0';

begin
    mmc_clk <= mmc_clk_i;
    mmc_clk_rise <= mmc_clk_rise_i;
    mmc_clk_fall <= mmc_clk_fall_i;

    -- MMC clock manager
    process
        variable pre_counter : integer range 0 to 2**8-1 := 0;
        
    begin
        wait until rising_edge(clk);

        if clk_en='1' then
            mmc_clk_rise_i <= '0';
            mmc_clk_fall_i <= '0';
            
            if pre_counter=0 then
                pre_counter := TO_INTEGER(unsigned(prescaler));
                
                if mmc_clk_i='0' then
                    mmc_clk_i <= '1';
                    mmc_clk_rise_i <= '1';
                else
                    mmc_clk_i <= '0';
                    mmc_clk_fall_i <= '1';
                end if;
                
            else
                pre_counter := pre_counter - 1;
                
            end if;
        end if;       
    end process;
end rtl;
