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
           reset : in std_logic;
           
           receive_dat_trigger_i : in std_logic;
           transmit_dat_trigger_i : in std_logic;
           dat_block_finished_o : out std_logic;
           
           bus_width_i : in std_logic_vector (1 downto 0);
           
           data_fifo_out_i : in std_logic_vector (31 downto 0);
           data_fifo_out_wr_i : in std_logic;
           data_fifo_out_full_o : out std_logic;
           
           data_fifo_in_o : out std_logic_vector (31 downto 0);
           data_fifo_in_rd_i : in std_logic;
           data_fifo_in_empty_o : out std_logic;
           
           dat_out_o : out std_logic_vector (7 downto 0);
           dat_in_i : in std_logic_vector (7 downto 0)
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
            empty : OUT STD_LOGIC;
            data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
        );
    END COMPONENT;
    
    component mmc_crc16 is
        Port ( clk : in std_logic;
               clk_en : in std_logic;
               reset : in std_logic;
               enable : in std_logic;
               
               serial_in : in std_logic;
               crc16_out : out std_logic_vector (15 downto 0)
               );
    end component;
    
    
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
    signal bit_counter : integer range 0 to 31 := 31;
    
    signal shift_en : std_logic := '0';
    
    signal data_fifo_out_rd_en : std_logic := '0';
    signal data_fifo_out_dout : std_logic_vector (31 downto 0);
    signal data_fifo_out_empty : std_logic;
    signal data_fifo_out_count : std_logic_vector (9 downto 0);
    signal data_fifo_in_din : std_logic_vector (31 downto 0);
    signal data_fifo_in_wr_en : std_logic;
    signal data_fifo_out_full : std_logic;
    signal data_fifo_in_count : std_logic_vector (9 downto 0);
    
    signal crc16_clear : std_logic;
    signal crc16_en : std_logic;
    signal crc16_serial_in : std_logic;
    signal crc16 : std_logic_vector (15 downto 0);
    
    signal dat0_shiftreg : std_logic_vector (31 downto 0) := (others => '1');
    signal dat0_word : std_logic_vector (31 downto 0);
    
    
begin

    dat_out_o(0) <= dat0_shiftreg(31);
    dat_out_o(7 downto 1) <= "1111111";
    
    dat0_word <= data_fifo_out_dout (7 downto 0) &
                 data_fifo_out_dout (15 downto 8) &
                 data_fifo_out_dout (23 downto 16) &
                 data_fifo_out_dout (31 downto 24);

    data_fifo_in_din <=  dat0_shiftreg (7 downto 1) & dat_in_i(0) &
                         dat0_shiftreg (15 downto 8) &
                         dat0_shiftreg (23 downto 16) &
                         dat0_shiftreg (31 downto 24); 
    

    -- 8bit shift register (DAT0)
    process
    begin
        wait until rising_edge(clk) and shift_en='1';
        
        data_fifo_out_rd_en <= '0';
        data_fifo_in_wr_en <= '0';
        
        if bit_counter=31 then
            bit_counter <= bit_counter - 1;
                if block_state=RX_DATA_BLOCK then
                    dat0_shiftreg <= dat0_shiftreg (30 downto 0) & dat_in_i(0);
                else
                    dat0_shiftreg <= dat0_word;
                    data_fifo_out_rd_en <= '1';
                end if;
        elsif bit_counter /= 0 then
            bit_counter <= bit_counter - 1;
            dat0_shiftreg <= dat0_shiftreg (30 downto 0) & dat_in_i(0);
            
        elsif bit_counter = 0 then
            bit_counter <= 31;
            dat0_shiftreg <= dat0_shiftreg (30 downto 0) & dat_in_i(0); 
            
            if block_state=RX_DATA_BLOCK then
                data_fifo_in_wr_en <= '1';
            end if;
                       
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
    
    process (block_state, transmit_dat_trigger_i, receive_dat_trigger_i, dat_in_i, byte_counter)
    begin
        next_block_state <= block_state;
        
        case block_state is
            when IDLE =>
                if transmit_dat_trigger_i='1' then
                    next_block_state <= TX_START_BIT;
                elsif receive_dat_trigger_i='1' then
                    next_block_state <= RX_START_BIT;
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
                
            when others =>
            
        end case;
    end process;
    
    
    

    mmc_dat_out_fifo : mmc_dat_fifo
      PORT MAP (
        clk => clk,
        srst => reset,
        din => data_fifo_out_i,
        wr_en => data_fifo_out_wr_i,
        rd_en => data_fifo_out_rd_en,
        dout => data_fifo_out_dout,
        full => data_fifo_out_full_o,
        empty => data_fifo_out_empty,
        data_count => data_fifo_out_count
      );
      
    mmc_dat_in_fifo : mmc_dat_fifo
        PORT MAP (
          clk => clk,
          srst => reset,
          din => data_fifo_in_din,
          wr_en => data_fifo_in_wr_en,
          rd_en => data_fifo_in_rd_i,
          dout => data_fifo_in_o,
          full => data_fifo_out_full,
          empty => data_fifo_in_empty_o,
          data_count => data_fifo_in_count
        );      

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
