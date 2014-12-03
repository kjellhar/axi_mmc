----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2014 02:00:27 PM
-- Design Name: 
-- Module Name: mmc_dat_if - rtl
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

entity mmc_dat_if is
    Port ( clk : in std_logic;
           clk_en : in std_logic;
           reset : in std_logic
           
           
           );
end mmc_dat_if;

architecture rtl of mmc_dat_if is
    component mmc_dataline is
        Port ( clk : in std_logic;
               reset : in std_logic;
               clk_en : in std_logic;
               dat_dir : in std_logic;
               load_shift : in std_logic;
               shift_en : in std_logic;
               crc16_clear : in std_logic;
               crc16_en : in std_logic;
               txdata_i : in std_logic_vector (7 downto 0);
               rxdata_o : out std_logic_vector (7 downto 0);
               mmc_dat_i : in std_logic;
               mmc_dat_o : out std_logic);
    end component;
    
    type bytearray is array (7 downto 0) of std_logic_vector (7 downto 0);
    
    signal dat_dir : std_logic;
    signal load_shift : std_logic;
    signal crc16_clear : std_logic;
    signal crc16_en : std_logic;
    signal shift_en : std_logic_vector (7 downto 0);
    signal mmc_dat_i : std_logic_vector (7 downto 0);
    signal mmc_dat_o : std_logic_vector (7 downto 0);
    signal txdata_i : bytearray;
    signal rxdata_o : bytearray;
    
begin

    

    u_mmc_datlines : for i in 0 to 7 generate
        u_mmc_datline : mmc_dataline
            Port map ( 
                clk => clk,
                reset => reset,
                clk_en => clk_en,
                dat_dir => dat_dir,
                load_shift => load_shift,
                shift_en => shift_en(i),
                crc16_clear => crc16_clear,
                crc16_en => crc16_en,
                txdata_i => txdata_i(i),
                rxdata_o => rxdata_o(i),
                mmc_dat_i => mmc_dat_i (i),
                mmc_dat_o => mmc_dat_o (i));
end generate;

end rtl;
