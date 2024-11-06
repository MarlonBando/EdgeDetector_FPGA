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
        MAX_ADDR : unsigned(15 downto 0) := to_unsigned(25343, 16);
        MAX_ROW  : unsigned(15 downto 0) := to_unsigned(288, 16);
        MAX_COL  : unsigned(15 downto 0) := to_unsigned(352, 16)
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
    type state_type is (idle, read_R0, read_R1, read_R2, write, compute_edge, compute_edge_RP, done);
    type pixel_matrix_type is array (0 to 2, 0 to 3) of std_logic_vector(7 downto 0);

    signal next_dataW : word_t;
    signal next_addr : halfword_t;
    signal state, next_state : state_type;
    signal dx_LP, dx_RP, dy_LP, dy_RP : std_logic_vector(7 downto 0);
    signal dn_LP, dn_RP : std_logic_vector(7 downto 0);
    signal pixel_matrix : pixel_matrix_type;
    signal next_col, next_row : unsigned(15 downto 0) := (others => '0');
    signal col, row : unsigned(15 downto 0) := (others => '0');
    
    -- Define internal signals for addr and dataW
    signal internal_addr : halfword_t := (others => '0');
    signal internal_dataW : word_t := (others => '0');

    constant TWO : signed(7 downto 0) := to_signed(2, 8);

begin

    -- Update the cl process to use internal signals
    cl : process(start, state, next_state, next_addr, next_dataW)
    begin
        next_state <= state;
        en <= '0';
        we <= '0';

        -- Use internal signals as default assignments
        next_addr <= internal_addr;
        next_dataW <= internal_dataW;
        next_col <= col;
        next_row <= row;
        dx_LP <= (others => '0');
        dx_RP <= (others => '0');
        dy_LP <= (others => '0');
        dy_RP <= (others => '0');
        dn_LP <= (others => '0');
        dn_RP <= (others => '0');
        
        case state is

            when idle =>
                if start = '1' then
                    next_state <= read_R0;
                end if;

            when read_R0 =>
                en <= '1';
                next_addr <= halfword_t(col + row * 88);
                
                pixel_matrix(0,0) <= dataR(31 downto 24);
                pixel_matrix(0,1) <= dataR(23 downto 16);
                pixel_matrix(0,2) <= dataR(15 downto 8);
                pixel_matrix(0,3) <= dataR(7 downto 0);
                
                if (row < 2) then
                    next_state <= read_R1;
                else
                    next_state <= compute_edge;    
                end if;

                if (row = 287) then
                    next_col <= next_col + 1;
                    next_row <= (others => '0');
                else
                    next_row <= next_row + 1;
                end if;
                
            when read_R1 =>
                en <= '1';
                next_addr <= halfword_t(col + row * 88);

                pixel_matrix(1,0) <= dataR(31 downto 24);
                pixel_matrix(1,1) <= dataR(23 downto 16);
                pixel_matrix(1,2) <= dataR(15 downto 8);
                pixel_matrix(1,3) <= dataR(7 downto 0);
                
                next_state <= read_R2;
                next_row <= next_row + 1;
                
            when read_R2 =>
                en <= '1';
                next_addr <= halfword_t(col + row * 88);
                
                pixel_matrix(2,0) <= dataR(31 downto 24);
                pixel_matrix(2,1) <= dataR(23 downto 16);
                pixel_matrix(2,2) <= dataR(15 downto 8);
                pixel_matrix(2,3) <= dataR(7 downto 0);
                
                next_state <= compute_edge;
                next_row <= next_row + 1;

            when compute_edge =>
                dx_LP <= std_logic_vector(
                         signed(pixel_matrix(0,2)) - signed(pixel_matrix(0,0)) +
                         TWO * (signed(pixel_matrix(1,2)) - signed(pixel_matrix(1,0))) +
                         signed(pixel_matrix(2,2)) - signed(pixel_matrix(2,0))
                         );

                dy_LP <= std_logic_vector(
                         signed(pixel_matrix(0,0)) - signed(pixel_matrix(2,0)) + 
                         TWO * (signed(pixel_matrix(0,1)) - signed(pixel_matrix(2,1))) + 
                         signed(pixel_matrix(0,2)) - signed(pixel_matrix(2,2))
                         );

                dn_LP <= std_logic_vector(
                         abs(signed(dx_LP)) + abs(signed(dy_LP))
                         );
                      
                dx_RP <= std_logic_vector(
                         signed(pixel_matrix(0,3)) - signed(pixel_matrix(0,1)) +
                         TWO * (signed(pixel_matrix(1,3)) - signed(pixel_matrix(1,1))) +
                         signed(pixel_matrix(2,3)) - signed(pixel_matrix(2,1))
                         );

                dy_RP <= std_logic_vector(
                         signed(pixel_matrix(0,1)) - signed(pixel_matrix(2,1)) + 
                         TWO * (signed(pixel_matrix(0,2)) - signed(pixel_matrix(2,2))) + 
                         signed(pixel_matrix(0,3)) - signed(pixel_matrix(2,3))
                         );

                dn_RP <= std_logic_vector(
                         abs(signed(dx_RP)) + abs(signed(dy_RP))
                         );

                next_state <= write;

            when write =>
                en <= '1';
                we <= '1';

                next_dataW <= pixel_matrix(1,0)   & 
                              dn_LP               & 
                              dn_RP               &
                              pixel_matrix(1,3);
                
                next_addr <= halfword_t(col + (row - 1) * 88 + MAX_ADDR);
                
                if row = MAX_ROW - 1 and col = MAX_COL - 1 then
                    finish <= '1';
                    next_state <= idle;
                else
                    next_state <= read_R0;
                end if;

            when others =>
                next_state <= idle;
        end case;
    end process cl;

    -- Update the seq process to use internal signals
    seq : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= idle;
                internal_addr <= (others => '0');
                internal_dataW <= (others => '0');
                col <= (others => '0');
                row <= (others => '0');
                finish <= '0';
                en <= '0';
            else
                state <= next_state;
                internal_addr <= next_addr;
                internal_dataW <= next_dataW;
                col <= next_col;
                row <= next_row;
            end if;
        end if;
    end process seq;

    -- Drive the output ports with internal signals
    addr <= internal_addr;
    dataW <= internal_dataW;

end rtl;
