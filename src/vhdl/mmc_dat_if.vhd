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
           mmc_clk_rise : in std_logic;
           reset : in std_logic;
           
           trigger_block_i : in std_logic;
           block_finished_o : out std_logic;
           
           bus_width : in std_logic_vector (1 downto 0);
           
           data_fifo_out_i : in std_logic_vector (31 downto 0);
           data_fifo_out_wr_i : in std_logic;
           data_fifo_out_full_o : out std_logic;
           
           data_fifo_in_o : out std_logic_vector (31 downto 0);
           data_fifo_in_rd_i : in std_logic;
           data_fifo_in_empty_o : out std_logic;
           
           dat_out_o : out std_logic_vector (7 downto 0);
           dat_in_i : in std_logic_vector (7 downto 0);
           dat_dir_i : in std_logic_vector
           
           );
end mmc_dat_if;

architecture rtl of mmc_dat_if is

    COMPONENT mmc_dat_fifo
        PORT (
            clk : IN STD_LOGIC;
            srst : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC
        );
    END COMPONENT;

    signal byte_counter : integer range 0 to 513 := 0;
    signal bit_counter : integer range 0 to 7 := 7;
    
    signal shift_en : std_logic := '0';
    
    signal dat0_shiftreg : std_logic_vector (7 downto 0) := (others => '1');
    signal dat0_byte : std_logic_vector (7 downto 0);
    
begin

    dat_out_o(0) <= dat0_shiftreg(7);

    -- 8bit shift register (DAT0)
    process
    begin
        wait until rising_edge(clk) and shift_en='1' and mmc_clk_rise='1';
        
        if bit_counter=7 then
            bit_counter <= bit_counter - 1;
                if dat_in_mode='1' then
                    dat0_shiftreg <= dat0_shiftreg (6 downto 0) & dat_in_i(0);
                else
                    dat0_shiftreg <= dat0_byte;
                end if;
        elsif bit_counter /= 0 then
            bit_counter <= bit_counter - 1;
            dat0_shiftreg <= dat0_shiftreg (6 downto 0) & dat_in_i(0);
            
        elsif bit_counter = 0 then
            bit_counter <= 7;
            dat0_shiftreg <= dat0_shiftreg (6 downto 0) & dat_in_i(0); 
                       
        end if;
    end process;
    
    -- block control module
    process
    begin
        wait until rising_edge(clk) and clk_en='1';
        
        
        
        
        
    end process;
    
    

    mmc_dat_out_fifo : mmc_dat_fifo
      PORT MAP (
        clk => clk,
        srst => reset,
        din => data_fifo_out_i,
        wr_en => data_fifo_out_wr_i,
        rd_en => rd_en,
        dout => dout,
        full => data_fifo_out_full_o,
        empty => empty
      );
      
    mmc_dat_in_fifo : mmc_dat_fifo
        PORT MAP (
          clk => clk,
          srst => reset,
          din => din,
          wr_en => wr_en,
          rd_en => data_fifo_in_rd_i,
          dout => data_fifo_in_o,
          full => full,
          empty => data_fifo_in_empty_o
        );      

end rtl;
