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
        MAX_ADDR : unsigned(15 downto 0) := to_unsigned(25344, 16)
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
    type state_type is (idle, read, write, done);
    signal next_addr, internal_addr : halfword_t;
    signal state, next_state : state_type;
    signal cnt, next_cnt : unsigned(15 downto 0) := (others => '0');

begin

    cl : process(start, state, next_state, cnt, dataR)
    begin
        
        en <= '0';
        we <= '0';
        finish <= '0';
        dataW <= (others => '0');
        addr <= (others => '0');
        next_state <= state;
        next_cnt <= cnt;
       
        case state is

            when idle =>
                if start = '1' then
                    next_state <= read;
                end if;

            when read =>
                en <= '1';
                addr <= halfword_t(cnt);
                next_state <= write;

            when write =>
                en <= '1';
                we <= '1';
                
                dataW <=  std_logic_vector(255 - unsigned(dataR(31 downto 24))) & 
                          std_logic_vector(255 - unsigned(dataR(23 downto 16))) & 
                          std_logic_vector(255 - unsigned(dataR(15 downto 8)))  &
                          std_logic_vector(255 - unsigned(dataR( 7 downto 0)));
                

                next_state <= read;
                addr <= halfword_t(cnt + MAX_ADDR);
                next_cnt <= cnt + 1;
                
                if (cnt = (MAX_ADDR - 1)) then
                    next_state <= done;
                end if;
            
            when done =>
                finish <= '1';
                next_state <= idle;
            
            when others =>
                next_state <= idle;
            
        end case;

            
    end process cl;


-- Template for a process
   seq : process(clk)
   begin
       if rising_edge(clk) then
           if reset = '1' then
                state <= idle;
                cnt <= (others => '0');
           else
                state <= next_state;
                cnt <= next_cnt;
           end if;
       end if;
   end process seq;

end rtl;
