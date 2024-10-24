-- -----------------------------------------------------------------------------
--
--  Title      :  Edge-Detection design project - task 2.
--             :
--  Developers :  Michele Bandini - s243121@student.dtu.dk
--             :  Myrsini Gkolemi - s233091@student.dtu.dk
--             :  Christopher Mardones-Andersen - s205119@student.dtu.dk
--             :
--  Purpose    :  This design contains an entity for the accelerator that must be build
--             :  in task two of the Edge Detection design project. It contains an
--             :  architecture skeleton for the entity as well.
--             :
--  Revision   :  1.0   ??-??-??     Final version
--             :
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- The entity for task two. Notice the additional signals for the memory.
-- reset is active high.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity acc is
    generic(
        MAX_ADDR : unsigned := 25343
    );
    port(
        clk    : in  bit_t;             -- The clock.
        reset  : in  bit_t;             -- The reset signal. Active high.
        addr   : out halfword_t;        -- Address bus for data.
        dataR  : in  word_t;            -- The data bus.
        dataW  : out word_t;            -- The data bus.
        en     : out bit_t;             -- Request signal for data.
        we     : out bit_t;             -- Read/Write signal for data.
        start  : in  bit_t;
        finish : out bit_t
    );
end acc;

--------------------------------------------------------------------------------
-- The desription of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc is

-- All internal signals are defined here
    type state_type is (idle, read, write, invert, done);
    signal data_r, data_w, next_data_r, next_data_w : word_t;
    signal next_reg_addr, reg_addr : halfword_t;
    signal state, next_state : state_type;

begin

    cl : process(start, state, next_state, next_reg_addr, data_r, data_w, next_data_r, next_data_w)
    begin
        next_state <= state;
        next_reg_addr <= reg_addr;
        next_data_r <= data_r;
        next_data_w <= data_w;
        en <= '0';
        we <= '0';
        
        
        case state is

            when idle =>
                if start = '1' then
                    next_state <= read;
                end if;

            when read =>
                en <= '1';
                next_data_r <= dataR;
                next_state <= invert;
                addr <= next_reg_addr;
           
            
            when invert =>
                next_data_w <=  std_logic_vector(255 - unsigned(dataR(31 downto 24))) & 
                                std_logic_vector(255 - unsigned(dataR(23 downto 16))) & 
                                std_logic_vector(255 - unsigned(dataR(15 downto 8)))  &
                                std_logic_vector(255 - unsigned(dataR( 7 downto 0)));

            when write =>
                en <= '1';
                we <= '1';
                next_reg_addr <= halfword_t(unsigned(next_reg_addr) + 1);
                -- TODO: write in the second block of the memory, addr + MAX_ADDR
                next_data_w <= (others => '0');
                next_state <= read;
                addr <= reg_addr + MAX_ADDR;
                
                if (unsigned(MAX_ADDR) - unsigned(reg_addr) = 0) then
                    next_state <= done;
                else
                    next_state <= read;
                end if;
                
                
            when done =>

        end case;

            
    end process cl;


-- Template for a process
   seq : process(clk)
   begin
       if rising_edge(clk) then
           if reset = '1' then
                state <= idle;
                reg_addr <= (others => '0');
                data_r <= (others => '0');
                data_w <= (others => '0');
           else
                state <= next_state;
                reg_addr <= next_reg_addr;
                data_r <= next_data_r;
                data_w <= next_data_w;

           end if;
       end if;
   end process seq;

end rtl;
