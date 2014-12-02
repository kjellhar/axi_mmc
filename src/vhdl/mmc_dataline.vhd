----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/02/2014 08:29:37 AM
-- Design Name: 
-- Module Name: mmc_dataline - rtl
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

entity mmc_dataline is
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
end mmc_dataline;

architecture rtl of mmc_dataline is
    component mmc_crc16 is
        Port ( clk : in std_logic;
               clk_en : in std_logic;
               reset : in std_logic;
               enable : in std_logic;
               
               serial_in : in std_logic;
               crc16_out : out std_logic_vector (15 downto 0)
               );
    end component;


    signal bit_counter : integer range 0 to 7;

    signal shift_reg : std_logic_vector (7 downto 0) := (others => '1');
    signal shift_en : std_logic := '0';
    
    signal crc16 : std_logic_vector (15 downto 0);
    signal crc16_serial_in : std_logic;
    
begin

    crc16_serial_in <= mmc_dat_i when dat_dir='0' else shift_reg(7);
    
    -- Shift register
    mmc_dat_o <= shift_reg(7);
    process
    begin
        wait until rising_edge(clk);
        
        if clk_en='1' then
            if load_shift='1' then
                shift_reg <= txdata_i;
            elsif shift_en='1' then
                shift_reg <= shift_reg (6 downto 0) & mmc_dat_i;
            end if;
        end if;
    end process;


    u_mmc_crc16 : mmc_crc16
        Port map ( 
            clk => clk,
            clk_en => clk_en,
            reset => crc16_clear,
            enable => crc16_en,
            
            serial_in => crc16_serial_in,
            crc16_out => crc16
            );

end rtl;
