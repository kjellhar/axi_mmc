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
    
    type block_state_t is (
        IDLE,
        RX_START_BIT,
        RX_DATA_BLOCK,
        RX_CRC1,
        RX_CRC2,
        TX_START_BIT,
        TX_DATA_BLOCK,
        TX_CRC1,
        TX_CRC2
    );
    
    signal block_state : block_state_t := IDLE;
    signal next_block_state : block_state_t;

    signal byte_counter : integer range 0 to 511 := 0;
    signal bit_counter : integer range 0 to 7 := 7;
    
    signal shift_en : std_logic := '0';
    
    signal dat0_shiftreg : std_logic_vector (7 downto 0) := (others => '1');
    signal dat0_byte : std_logic_vector (7 downto 0);
    
begin

    dat_out_o(0) <= dat0_shiftreg(7);
    dat_out_o(7 downto 1) <= "1111111";

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
        
        if reset='1' then
            block_state <= IDLE;
        
        else
            block_state <= next_block_state;
            
        end if;
    end process;
    
    process
    begin
        next_block_state <= block_state;
        
        case block_state is
            when IDLE =>
                if trigger_block_i='1' then
                    if dat_dir_i='1' then
                        next_block_state <= TX_START_BIT;
                    else
                        next_block_state <= RX_START_BIT;
                    end if;
                end if;
                
            when RX_START_BIT =>
                if dat_in_i(0)='0' then
                    next_block_state <= RX_DATA_BLOCK;
                end if;
                
            when RX_DATA_BLOCK =>
                if byte_counter=511 then
                    next_block_state <= RX_CRC1;
                end if;
            
            when RX_CRC1 =>
                next_block_state <= RX_CRC2;
                
            when RX_CRC2 =>
                next_block_state <= IDLE;
                
            when TX_START_BIT =>
                next_block_state <= TX_DATA_BLOCK;
                
            when TX_DATA_BLOCK =>
                if byte_counter=511 then
                    next_block_state <= TX_CRC1;
                end if;
            
            when TX_CRC1 =>
                next_block_state <= TX_CRC2;
                
            when TX_CRC2 =>
                next_block_state <= IDLE;
            when default =>
            
        end case;
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
