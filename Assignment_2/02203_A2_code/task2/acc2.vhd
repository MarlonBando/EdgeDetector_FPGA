-- -----------------------------------------------------------------------------
--
--  Title      :  Edge-Detection design project - task 2.
--             :
--  Developers :  Michele Bandini - s243121@student.dtu.dk
--             :  YOUR NAME HERE - s??????@student.dtu.dk
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
    type state_type is (idle, read, write, invert, increment_addr, done);
    signal reg_addr, next_reg_addr, data_r, data_w, next_data_r, next_data_w : word_t;
    signal state, next_state : state_type;
    signal next_byte,current_byte : std_logic_vector(1 downto 0);

begin

    cl : process(start, state, next_state, reg_addr, next_reg_addr, data_r, data_w, next_data_r, next_data_w)
    begin
        next_state <= state;
        next_reg_addr <= reg_addr;
        next_data_r <= data_r;
        next_data_w <= data_w;
        next_byte <= current_byte;
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

            when invert =>
                case current_byte is
                    when "00" => 
                        next_byte <= "01";
                        next_data_w <= data_w + (255 - dataR(31 downto 24));
                        next_state <= shift;
                    when "01" => 
                        next_byte <= "10";
                        next_data_w <= data_w + (255 - dataR(23 downto 16));
                        next_state <= shift;
                    when "10" => 
                        next_byte <= "11";
                        next_data_w <= data_w + (255 - dataR(15 downto 8));
                        next_state <= shift;
                    when "11" => 
                        next_byte <= "00";
                        next_data_w <= data_w + (255 - dataR(7 downto 0));
                        next_state <= write;
                    when others => 
                        next_byte <= "00";
                        next_data_w <= (others => '0');
                        next_state <= idle;
                end case;
                
            
            when shift =>
                next_data_w <= data_w sll 8;
                next_state <= invert;

            when write =>
                en <= '1';
                we <= '1';
                next_reg_addr <= reg_addr + 1;
                next_state <= read;
                next_data_w <= (others => '0');
                -- TODO: check last register and move to done

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
                current_byte <= next_byte;

           end if;
       end if;
   end process seq;

end rtl;
