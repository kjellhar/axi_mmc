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

    component mmc_core_top is
        Port ( clk : in std_logic;
               reset : in std_logic;
               irq : out std_logic;
               execute : in std_logic;
               busy : out std_logic;
               
               status_reg_o : out std_logic_vector (31 downto 0);
               
               config_reg_i : in std_logic_vector (31 downto 0);
               config_reg_o : out std_logic_vector (31 downto 0);
               config_reg_wr : in std_logic;
    
               operation_reg_i : in std_logic_vector (31 downto 0);
               operation_reg_o : out std_logic_vector (31 downto 0);
               operation_reg_wr : in std_logic;
               
               cmd_arg_reg_i : in std_logic_vector (31 downto 0);
               cmd_arg_reg_o : out std_logic_vector (31 downto 0);
               cmd_arg_reg_wr : in std_logic;
               
               respons_fifo_o : out std_logic_vector (31 downto 0);
               respons_fifo_pull : in std_logic;
               respons_fifo_empty : out std_logic;
               
               rdata_fifo_o : out std_logic_vector (31 downto 0 );
               rdata_fifo_pull : in std_logic;
               rdata_fifo_empty : out std_logic;
               
               
               -- MCC signals
               mmc_clk_o : out std_logic;
               mmc_rst_o : out std_logic;
               mmc_cmd_i : in std_logic;
               mmc_cmd_o : out std_logic;
               mmc_dat_i : in std_logic_vector (7 downto 0);
               mmc_dat_o : out std_logic_vector (7 downto 0);
               -- Auxillary MMC signals
               mmc_cpresent_i : in std_logic;
               mmc_pwr_en_o : out std_logic;
               -- MMC pin control signals
               mmc_cmd_dir : out std_logic;
               mmc_dat_dir : out std_logic
                         
               );
    end component;


    signal test_en : std_logic := '1';
    signal clk100M : std_logic := '0';
    signal reset : std_logic := '1';
    signal execute : std_logic := '0';
    signal status_reg_o : std_logic_vector (31 downto 0);
    signal config_reg_o : std_logic_vector (31 downto 0);
    signal config_reg_i : std_logic_vector (31 downto 0) := (others => '0');    
    signal config_reg_wr : std_logic := '0';
    signal operation_reg_o : std_logic_vector (31 downto 0);
    signal operation_reg_i : std_logic_vector (31 downto 0) := (others => '0');    
    signal operation_reg_wr : std_logic := '0';
    signal cmd_arg_reg_o : std_logic_vector (31 downto 0);
    signal cmd_arg_reg_i : std_logic_vector (31 downto 0) := (others => '0');    
    signal cmd_arg_reg_wr : std_logic := '0';    
    
    signal mmc_clk_o : std_logic;
    signal mmc_cmd_o : std_logic;
    signal mmc_cmd_dir : std_logic;   
    
    signal response : std_logic_vector (135 downto 0) := (others => '1'); 
    
begin

    -- DUT instantiation
    u_dut : mmc_core_top 
        Port map ( 
            clk => clk100M,
            reset => reset,
            --irq => ,
            execute => execute,
            --busy => ,            
            status_reg_o => status_reg_o,
            config_reg_i => config_reg_i,
            config_reg_o => config_reg_o,
            config_reg_wr => config_reg_wr,
            operation_reg_i => operation_reg_i,
            operation_reg_o => operation_reg_o,
            operation_reg_wr => operation_reg_wr,
            cmd_arg_reg_i => cmd_arg_reg_i,
            cmd_arg_reg_o => cmd_arg_reg_o,
            cmd_arg_reg_wr => cmd_arg_reg_wr,
            --respons_fifo_o => ,
            respons_fifo_pull => '0',
            --respons_fifo_empty => ,
            --rdata_fifo_o => ,
            rdata_fifo_pull => '0',
            --rdata_fifo_empty => ,
            -- MCC signals
            mmc_clk_o => mmc_clk_o,
            --mmc_rst_o => ,
            mmc_cmd_i => response(135),
            mmc_cmd_o => mmc_cmd_o,
            mmc_dat_i => "00000000",
            --mmc_dat_o => ,
            -- Auxillary MMC signals
            mmc_cpresent_i => '1',
            --mmc_pwr_en_o => ,
            -- MMC pin control signals
            mmc_cmd_dir => mmc_cmd_dir
            --mmc_dat_dir =>                      
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
        
        
        config_reg_i <= X"02" & X"000201";
        wait until rising_edge(clk100M);
        config_reg_wr <= '1';
        wait until rising_edge(clk100M);
        config_reg_wr <= '0';
        config_reg_i <= (others => '0');
        
        operation_reg_i <= X"00" & '0' & "1010011" & "000" & "0000" & "011" & "010011";
        wait until rising_edge(clk100M);
        operation_reg_wr <= '1';
        wait until rising_edge(clk100M);
        operation_reg_wr <= '0';
        operation_reg_i <= (others => '0');        
 
        cmd_arg_reg_i <= X"01234567";
        wait until rising_edge(clk100M);
        cmd_arg_reg_wr <= '1';
        wait until rising_edge(clk100M);
        cmd_arg_reg_wr <= '0';
        cmd_arg_reg_i <= (others => '0');       
        
        wait for 10*clk100M_per;
        wait until rising_edge(clk100M);
        execute <= '1';
        wait until rising_edge(clk100M);
        execute <= '0';
        
        wait until falling_edge(mmc_cmd_o);
        
        for i in 0 to 47 loop
            wait until rising_edge(mmc_clk_o);
        end loop;
        
        wait until rising_edge(mmc_clk_o);
        wait until rising_edge(mmc_clk_o);
        wait until rising_edge(mmc_clk_o);
        
        response <= X"73C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C1";
        
        for i in 0 to 135 loop
            wait until rising_edge(mmc_clk_o);
            response <= response (134 downto 0) & '1';
        end loop;
        
        wait for 200 ns;
        test_en <= '0';
        
        
        wait;
    
    end process;

end testbench;
