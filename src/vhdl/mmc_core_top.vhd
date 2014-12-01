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
--              [0]     - Module enable  
--
--
--          operation_reg (RW):
--              [22:16] - Cmd CRC7 (used if bit 9 is 0)
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
use WORK.mmc_core_pkg.all;

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

    component mmc_cmd_if is
        Port ( clk : in std_logic;
               clk_en : in std_logic;
               reset : in std_logic;
               
               mmc_cmd_i : in std_logic;
               mmc_cmd_o : out std_logic;
               
               send_cmd_trigger_i : in std_logic;
               receive_cmd_trigger_i : in std_logic;
               send_cmd_busy_o : out std_logic;
               receive_cmd_busy_o : out std_logic;
               
               crc7_calc_en_i : in std_logic;
               
               response_i : in std_logic_vector (2 downto 0);
               
               cmd_shift_outval_i : in std_logic_vector (47 downto 0);
               cmd_shift_inval_o : out std_logic_vector (135 downto 0);
               mmc_crc7_out_o : out std_logic_vector (6 downto 0)
               );
    end component;
    
    component mmc_clk_manager is
        Port ( clk : in std_logic;
               clk_en : in std_logic;
               reset : in std_logic;
               prescaler : in std_logic_vector (7 downto 0);
               mmc_clk : out std_logic;
               mmc_clk_rise : out std_logic;
               mmc_clk_fall : out std_logic);
    end component;    


    -- State variables
    type state_t is (
        INACTIVE,
        IDLE,
        INIT_SEND_CMD,
        START_SEND_CMD,
        SEND_CMD,
        START_RESP,
        WAIT_FOR_RESP);
        

    signal state : state_t := INACTIVE;
    signal nextstate : state_t;


    -- Clock Enable signals
    signal mmc_clk_en : std_logic;
    signal mmc_clk_fall : std_logic;
    signal mmc_clk_rise : std_logic;
    
    -- Internal control signals
    signal response : std_logic_vector (2 downto 0);
    signal cmd_index : std_logic_vector (5 downto 0);
    signal crc7_preset : std_logic_vector (6 downto 0);
    signal send_cmd_busy : std_logic := '0';
    signal send_cmd_trigger : std_logic := '0';
    signal receive_cmd_busy : std_logic := '0';
    signal receive_cmd_trigger : std_logic := '0';
    signal cmd_shift_outval : std_logic_vector (47 downto 0);
    signal prescaler : std_logic_vector (7 downto 0);
    signal module_enable : std_logic;
    signal mmc_crc7_out : std_logic_vector (6 downto 0);
    signal crc7_calc_en : std_logic;


    -- Register
    signal status_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal config_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal operation_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal cmd_arg_reg : std_logic_vector (31 downto 0) := (others => '0');
    signal respons_fifo : std_logic_vector (31 downto 0) := (others => '0');
    signal rdata_fifo : std_logic_vector (31 downto 0) := (others => '0');
    
    
    -- Internal MMC signals
    signal mmc_clk : std_logic := '0';   
    
    signal cmd_shift_in : std_logic_vector (135 downto 0);


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
    cmd_index <= operation_reg (5 downto 0);
    response <= operation_reg (8 downto 6);
    crc7_preset <= operation_reg (22 downto 16);
    prescaler <= config_reg (31 downto 24);
    module_enable <= config_reg(0);
    crc7_calc_en <= config_reg(9);
    
    cmd_shift_outval <= "01" & cmd_index & cmd_arg_reg & crc7_preset & '1';
    
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
        
        if reset='1' or module_enable='0' then
            state <= INACTIVE;
        else
            state <= nextstate;
        end if;
    end process;
    
    -- State machine logic
    process (state, execute, send_cmd_busy, response, receive_cmd_busy)
    begin
        -- default values for outputs
        nextstate <= state;
        mmc_clk_en <= '1';
        send_cmd_trigger <= '0';
        receive_cmd_trigger <= '0';
        mmc_cmd_dir <= '0';     -- Default to input
        
        -- Next state and output logic
        case state is
            when INACTIVE =>
                if module_enable='1' then
                    nextstate <= IDLE;
                end if;
                mmc_clk_en <= '0';
        
            when IDLE =>
                if execute='1' then
                    nextstate <= INIT_SEND_CMD;
                end if;
                
            when INIT_SEND_CMD =>
                if send_cmd_busy='0' then
                    nextstate <= START_SEND_CMD;
                end if;
                
            when START_SEND_CMD =>
                send_cmd_trigger <= '1';
                mmc_cmd_dir <= '1';
                if send_cmd_busy='1' then
                    nextstate <= SEND_CMD;
                end if;                

            when SEND_CMD =>
                mmc_cmd_dir <= '1';
                if send_cmd_busy='0' then
                    if response=RESP_NONE then
                        nextstate <= IDLE;
                    else
                        nextstate <= START_RESP;
                    end if;
                end if;
            
            when START_RESP =>
                receive_cmd_trigger <= '1';
                
                if receive_cmd_busy='1' then            
                    nextstate <= WAIT_FOR_RESP;
                end if;
                
            when WAIT_FOR_RESP =>
                if receive_cmd_busy='0' then
                    nextstate <= IDLE;
                end if;
                        
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



    u_mmc_clk_manager : mmc_clk_manager 
        Port map ( 
        clk => clk,
        clk_en => mmc_clk_en,
        reset => reset,
        prescaler => prescaler,
        mmc_clk => mmc_clk,
        mmc_clk_rise => mmc_clk_rise,
        mmc_clk_fall => mmc_clk_fall
        );

    u_mmc_cmd_if : mmc_cmd_if 
        Port map ( 
            clk => clk,
            clk_en => mmc_clk_rise,
            reset => reset,
            
            mmc_cmd_i => mmc_cmd_i,
            mmc_cmd_o => mmc_cmd_o,
            
            send_cmd_trigger_i => send_cmd_trigger,
            receive_cmd_trigger_i => receive_cmd_trigger,
            send_cmd_busy_o => send_cmd_busy,
            receive_cmd_busy_o => receive_cmd_busy,
            
            crc7_calc_en_i => crc7_calc_en,
            
            response_i => response,
            
            cmd_shift_outval_i => cmd_shift_outval,
            cmd_shift_inval_o => cmd_shift_in,
            mmc_crc7_out_o => mmc_crc7_out        
            );


end rtl;
