----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2014 09:11:16 AM
-- Design Name: 
-- Module Name: mmc_cmd_if - Behavioral
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
use WORK.mmc_core_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mmc_cmd_if is
    Port ( clk : in std_logic;
           clk_en : in std_logic;
           reset : in std_logic;
           
           mmc_cmd_i : in std_logic;
           mmc_cmd_o : out std_logic;
           
           send_cmd_trigger : in std_logic;
           receive_cmd_trigger : in std_logic;
           send_cmd_busy : out std_logic;
           receive_cmd_busy : out std_logic;
           
           response : in std_logic_vector (2 downto 0);
           
           cmd_shift_outval : in std_logic_vector (47 downto 0);
           cmd_shift_inval : out std_logic_vector (135 downto 0)
           
           );
end mmc_cmd_if;

architecture Behavioral of mmc_cmd_if is

    signal cmd_shift_out : std_logic_vector (47 downto 0);
    signal cmd_shift_in : std_logic_vector (135 downto 0);
    
    signal receive_cmd_busy_i : std_logic := '0';
    
begin

    cmd_shift_inval <= cmd_shift_in;
    receive_cmd_busy <= receive_cmd_busy_i;
    mmc_cmd_o <= cmd_shift_out (47);

    --MMC CMD out 
    process
        variable bit_counter : integer range 0 to 47 := 0;
    begin
        wait until rising_edge(clk);
        
        if reset='1' then
            bit_counter := 0;
            cmd_shift_out <= (others => '1');
        
        elsif clk_en='1' then
            if send_cmd_trigger='1' then
                cmd_shift_out <= cmd_shift_outval;
                bit_counter := 47;
                send_cmd_busy <= '1';       
        
            else
                cmd_shift_out <= cmd_shift_out (46 downto 0) & '1';
                
                if bit_counter = 0 then                
                    send_cmd_busy <= '0';
                
                else 
                    bit_counter := bit_counter - 1;
                    send_cmd_busy <= '1';
                end if;
            end if;
        end if;
        
    end process;

    -- MMC CMD in
    process
    begin
        wait until rising_edge(clk);
        
        if reset='1' then
            receive_cmd_busy_i <= '0';
            
        elsif clk_en='1' then
            if receive_cmd_trigger='1' then
                receive_cmd_busy_i <= '1';
                cmd_shift_in <= (others => '1');
            
            elsif receive_cmd_busy_i='1' then
                cmd_shift_in <= cmd_shift_in (134 downto 0) & mmc_cmd_i;
                
                if response=RESP_R2 and cmd_shift_in(134)='0' then
                    receive_cmd_busy_i <= '0';

                elsif response/=RESP_R2 and cmd_shift_in(46)='0' then
                        receive_cmd_busy_i <= '0';
 
                end if;
            end if;                
        end if;      
    end process;



end Behavioral;
