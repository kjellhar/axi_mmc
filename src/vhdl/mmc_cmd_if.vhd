----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2014 09:11:16 AM
-- Design Name: 
-- Module Name: mmc_cmd_if - rtl
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
           
           send_cmd_trigger_i : in std_logic;
           receive_cmd_trigger_i : in std_logic;
           send_cmd_busy_o : out std_logic;
           receive_cmd_busy_o : out std_logic;
           
           response_i : in std_logic_vector (2 downto 0);
           
           cmd_shift_outval_i : in std_logic_vector (47 downto 0);
           cmd_shift_inval_o : out std_logic_vector (135 downto 0);
           
           mmc_crc7_out_o : out std_logic_vector (6 downto 0)
           );
end mmc_cmd_if;

architecture rtl of mmc_cmd_if is
    component mmc_crc7 is
        Port ( clk : in std_logic;
               clk_en : in std_logic;
               reset : in std_logic;
               enable : in std_logic;
               
               serial_in : in std_logic;
               crc7_out : out std_logic_vector (6 downto 0)
               );
    end component;



    signal cmd_shift_out : std_logic_vector (47 downto 0) := (others => '1');
    signal cmd_shift_in : std_logic_vector (135 downto 0) := (others => '1');
    
    signal send_cmd_busy : std_logic := '0';
    signal receive_cmd_busy : std_logic := '0';
        
    signal crc7_en : std_logic := '0';
    signal crc7_source : std_logic;
    signal crc7_out : std_logic_vector (6 downto 0);
    
begin

    cmd_shift_inval_o <= cmd_shift_in;
    receive_cmd_busy_o <= receive_cmd_busy;
    send_cmd_busy_o <= send_cmd_busy;
    mmc_cmd_o <= cmd_shift_out (47);
    mmc_crc7_out_o <= crc7_out;
    

    --MMC CMD out 
    process
        variable bit_counter : integer range 0 to 47 := 0;
    begin
        wait until rising_edge(clk);
        
        if reset='1' then
            bit_counter := 0;
        
        elsif clk_en='1' then
            if send_cmd_trigger_i='1' and receive_cmd_busy='0' then
                cmd_shift_out <= cmd_shift_outval_i;
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
            receive_cmd_busy <= '0';
            
        elsif clk_en='1' then
            if receive_cmd_trigger_i='1' and send_cmd_busy='0' then
                receive_cmd_busy <= '1';
                cmd_shift_in <= (others => '1');
            
            elsif receive_cmd_busy='1' then
                cmd_shift_in <= cmd_shift_in (134 downto 0) & mmc_cmd_i;
                
                if response_i=RESP_R2 and cmd_shift_in(134)='0' then
                    receive_cmd_busy <= '0';

                elsif response_i/=RESP_R2 and cmd_shift_in(46)='0' then
                        receive_cmd_busy <= '0';
 
                end if;
            end if;                
        end if;      
    end process;
    
    crc7_source <= cmd_shift_out (47) when send_cmd_busy='1' else
                   mmc_cmd_i when receive_cmd_busy='1' else
                   '0';
                   
    crc7_en <= '1' when send_cmd_busy='1' else
               '1' when receive_cmd_busy='1' else
               '0';
               
               

    u_mmc_crc7 : mmc_crc7
        Port map ( 
            clk => clk,
            clk_en => clk_en,
            reset => reset,
            enable => crc7_en,
            
            serial_in => crc7_source,
            crc7_out => crc7_out
            );

end rtl;
