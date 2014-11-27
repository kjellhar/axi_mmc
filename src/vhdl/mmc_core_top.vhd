----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2014 07:09:05 PM
-- Design Name: 
-- Module Name: mmc_core_top - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
--      The MMC core is designed so it should be quite simple to
--      adapt it to any bus sytem. It uses a range of registers 
--      for interfacing. A bus wrapper must take care of address
--      decoding and bus protocol. The internal control signals are
--      very simple. 
--
--
--      Register definitions
--
--          status_reg (R):
--
--          config_reg (RW):
--              [31:24] - MMC clock prescaler:  f_mmc = f_in/(2*(1+pre))
--
--          operation_reg (RW):
--              [12]    - Read/Write multiple sectors
--              [11]    - Write data
--              [10]    - Read data
--              [9]     - Append CRC7 to command
--              [8:6]   - Response
--              [5:0]   - Command index
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


entity mmc_core_top is
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
end mmc_core_top;

architecture rtl of mmc_core_top is
    -- State variables
    type state_t is (
        INACTIVE,
        IDLE,
        SEND_CMD,
        WAIT_FOR_R1B,
        WAIT_FOR_RX);
        
    -- Response encoding
    constant RESP_NONE  : std_logic_vector(2 downto 0)  := "000";
    constant RESP_R1    : std_logic_vector(2 downto 0)  := "001";
    constant RESP_R1B   : std_logic_vector(2 downto 0)  := "010";
    constant RESP_R2    : std_logic_vector(2 downto 0)  := "011";
    constant RESP_R3    : std_logic_vector(2 downto 0)  := "100";
    constant RESP_R4    : std_logic_vector(2 downto 0)  := "101";
    constant RESP_R5    : std_logic_vector(2 downto 0)  := "110";
        
    signal state : state_t := INACTIVE;
    signal nextstate : state_t;


    -- Clock Enable signals
    signal mmc_clk_en : std_logic := '0';
    signal mmc_clk_fall : std_logic := '0';
    signal mmc_clk_rise : std_logic := '0';
    
    -- Internal control signals
    signal response : std_logic_vector (2 downto 0);
    signal send_cmd_finished : std_logic := '0';


    -- Register
    signal status_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal config_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal operation_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal cmd_arg_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal respons_fifo : std_logic_vector (31 downto 0) := (others => '0');
    signal rdata_fifo : std_logic_vector (31 downto 0) := (others => '0');
    
    
    -- Internal MMC signals
    signal mmc_clk : std_logic := '0';
    
    -- Shift register
    signal cmd_shift_in : std_logic_vector (7 downto 0);
    signal cmd_shift_out : std_logic_vector (7 downto 0);
    signal dat0_shift_in : std_logic_vector (7 downto 0);
    signal dat0_shift_out : std_logic_vector (7 downto 0);
    signal dat1_shift_in : std_logic_vector (7 downto 0);
    signal dat1_shift_out : std_logic_vector (7 downto 0);
    signal dat2_shift_in : std_logic_vector (7 downto 0);
    signal dat2_shift_out : std_logic_vector (7 downto 0);
    signal dat3_shift_in : std_logic_vector (7 downto 0);
    signal dat3_shift_out : std_logic_vector (7 downto 0);
    signal dat4_shift_in : std_logic_vector (7 downto 0);
    signal dat4_shift_out : std_logic_vector (7 downto 0);
    signal dat5_shift_in : std_logic_vector (7 downto 0);
    signal dat5_shift_out : std_logic_vector (7 downto 0);
    signal dat6_shift_in : std_logic_vector (7 downto 0);
    signal dat6_shift_out : std_logic_vector (7 downto 0);
    signal dat7_shift_in : std_logic_vector (7 downto 0);
    signal dat7_shift_out : std_logic_vector (7 downto 0);
    

begin

    -- Connect outputs
    status_reg_o <= status_reg;
    config_reg_o <= config_reg;
    operation_reg_o <= operation_reg;
    cmd_arg_reg_o <= cmd_arg_reg;
    respons_fifo_o <= respons_fifo;
    rdata_fifo_o <= rdata_fifo;
    mmc_clk_o <= mmc_clk;

    -- Connect config register to control signals
    response <= operation_reg(8 downto 6);
    
    -- Register block
    process
    begin
        wait until rising_edge(clk);

        if config_reg_wr='1' then
            config_reg <= config_reg_i;
        end if;

        if operation_reg_wr='1' then
            operation_reg <= operation_reg_i;
        end if;
        
        if cmd_arg_reg_wr='1' then
            cmd_arg_reg <= cmd_arg_reg_i;
        end if;
    end process;





    -- State machine flip-flops
    process
    begin
        wait until rising_edge(clk);
        
        if reset='1' then
            state <= IDLE;
        else
            state <= nextstate;
        end if;
    end process;
    
    -- State machine logic
    process
    begin
        -- default values for outputs
        nextstate <= state;
        mmc_clk_en <= '1';
        
        -- Next state and output logic
        case state is
            when INACTIVE =>
                if execute='1' then
                    nextstate <= IDLE;
                end if;
                
                mmc_clk_en <= '0';
        
            when IDLE =>
                if execute='1' then
                    nextstate <= SEND_CMD;
                end if;
            
            when SEND_CMD =>
                if send_cmd_finished='1' then
                    if response=RESP_R1B then
                        nextstate <= WAIT_FOR_R1B;
                    elsif response=RESP_NONE then
                        nextstate <= IDLE;
                    else
                        nextstate <= WAIT_FOR_RX;
                    end if;
                end if;
            
            when WAIT_FOR_RX =>
            
            when WAIT_FOR_R1B =>
            
--            when GET_R1 =>
            
--            when GET_R1B =>
            
--            when GET_R2 =>
            
--            when GET_R3 =>
            
--            when GET_R4 =>
            
--            when GET_R5 =>
            
            when others =>
                nextstate <= INACTIVE;
                
                -- Output error signal    
            
        end case;
    
    
    end process;


    -- MMC clock manager
    process
        variable pre_counter : integer range 0 to 2**8-1 := 0;
        
    begin
        wait until rising_edge(clk);
        
        if reset='1' then
            mmc_clk <= '0';
            pre_counter := 0;
            mmc_clk_rise <= '0';
            mmc_clk_fall <= '0';
            
        elsif mmc_clk_en='1' then
            mmc_clk_rise <= '0';
            mmc_clk_fall <= '0';
            
            if pre_counter=0 then
                pre_counter := TO_INTEGER(unsigned(config_reg (31 downto 24)));
                
                if mmc_clk='0' then
                    mmc_clk <= '1';
                    mmc_clk_rise <= '1';
                else
                    mmc_clk <= '0';
                    mmc_clk_fall <= '1';
                end if;
                
            else
                pre_counter := pre_counter - 1;
                
            end if;
        end if;       
    end process;


end rtl;
