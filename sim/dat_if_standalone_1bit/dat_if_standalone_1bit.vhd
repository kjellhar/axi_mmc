----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2014 09:07:43 PM
-- Design Name: 
-- Module Name: dat_if_standalone_1bit - testbench
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

entity dat_if_standalone_1bit is
--  Port ( );
end dat_if_standalone_1bit;

architecture testbench of dat_if_standalone_1bit is

    constant clk100M_per : time := 10 ns;

    component mmc_dat_if is
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
    end component;


    signal test_en : std_logic := '1';
    signal clk100M : std_logic := '0';
    signal reset : std_logic := '1';
    
    signal clk_en : std_logic := '0';
    
    signal receive_dat_trigger : std_logic := '0';
    signal transmit_dat_trigger : std_logic := '0';
    signal dat_block_finished : std_logic;
    signal bus_width : std_logic_vector (1 downto 0) := "00";
    signal data_fifo_out : std_logic_vector (31 downto 0);
    signal data_fifo_out_wr : std_logic := '0';
    signal data_fifo_out_full : std_logic;
    signal data_fifo_in : std_logic_vector (31 downto 0) := X"00000000";
    signal data_fifo_in_rd : std_logic := '0';
    signal data_fifo_in_empty : std_logic;
    signal dat_out : std_logic_vector (7 downto 0);
    signal dat_in : std_logic_vector (7 downto 0) := X"00";

    
begin


    u_dut : mmc_dat_if
        Port map ( 
            clk => clk,
            clk_en => clk_en,
            reset => reset,
            receive_dat_trigger_i => receive_dat_trigger,
            transmit_dat_trigger_i => transmit_dat_trigger,
            dat_block_finished_o => dat_block_finished,
            bus_width_i => bus_width,
            data_fifo_out_i => data_fifo_out,
            data_fifo_out_wr_i => data_fifo_out_wr,
            data_fifo_out_full_o => data_fifo_out_full,
            data_fifo_in_o => data_fifo_in,
            data_fifo_in_rd_i => data_fifo_in_rd,
            data_fifo_in_empty_o => data_fifo_in_empty,
            dat_out_o => dat_out,
            dat_in_i => dat_in            
            );



    -- Clock generator
    process
    begin
        if test_en='1' then
            clk100M <= '1', '0' after clk100M_per/2;
            wait for clk100M_per;
        else
            wait;
        end if;
    end process;
    
    
    -- Testbench stimuli
    process
    begin
        test_en <= '1';
        reset <= '1';
        wait for 100 ns;
        
        reset <= '0';
        wait for 10*clk100M_per;
        wait until rising_edge(clk100M);
        
 
        
        wait for 200 ns;
        test_en <= '0';
        
        
        wait;
    
    end process;

end testbench;
