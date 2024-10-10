-- -----------------------------------------------------------------------------
--
--  Title      :  Edge-Detection design project - task 2.
--             :
--  Developers :  YOUR NAME HERE - s??????@student.dtu.dk
--             :  YOUR NAME HERE - s??????@student.dtu.dk
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
    type state_type is (idle, read, write,invert, increment_addr, done);
    signal reg_addr, next_reg_addr, data_r, data_w, next_data_r, next_data_w : word_t;
    signal state, next_state : state_type;

begin

    cl : process(start, state, next_state, reg_addr, next_reg_addr, data_r, data_w, next_data_r, next_data_w)
    begin
        next_state <= state;
        next_reg_addr <= reg_addr;
        next_data_r <= data_r;
        next_data_w <= data_w;
        en <= '0';
        we <= '0';


        case(state) is

            when idle =>
                if start = ´1' then
                    next_state <= read;
                end if;

            when read =>
                en <= '1';
                next_data_r <= dataR;
                

            when invert =>
                    

            when write =>

            when done =>
            



        end case;

            
    end process cl;


-- Template for a process
   seq : process(clk, reset)
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
