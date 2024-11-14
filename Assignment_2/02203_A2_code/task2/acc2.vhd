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
        IMG_WIDTH : unsigned(15 downto 0) := to_unsigned(352, 16);
        IMG_HEIGHT : unsigned(15 downto 0) := to_unsigned(352, 16)
    );
    port(
        clk    : in  bit_t;             -- The clock.
        reset  : in  bit_t;             -- The reset signal. Active high.
        addr   : out halfword_t;        -- Address bus for data.
        dataR  : in  word_t;            -- The data bus.
        dataW  : out word_t;            -- The data bus.
        en     : out bit_t;             -- Request signal for data.
        we     : out bit_t;             -- Read/Write signal for data.
        queueR : in word_t;
        queueW : out word_t; 
        start  : in  bit_t;
        finish : out bit_t
    );
end acc;

--------------------------------------------------------------------------------
-- The desription of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc is

-- All internal signals are defined here
    type state_type is (idle, read, compute_and_write);
    signal data_r, data_w, next_data_w : word_t;
    signal next_reg_addr, reg_addr : halfword_t;
    signal state, next_state : state_type;

    signal matrix_first_word, matrix_second_word, matrix_third_word : word_t;
    signal matrix_first_word_addr, matrix_second_word_addr, matrix_third_word_addr : word_t;
    signal first_half_word, second_half_word,third_half_word : halfword_t;
    signal first_read : bit_t;

    signal cursor_x, cursor_y : halfword_t;
    signal next_cursor_x, next_cursor_y : halfword_t;

    -- Registers to store pixel data for convolution operations
    signal b_00_r1, b_00_r2, b_00_r3,  b_01_r1, b_01_r2, b_01_r3 : word_t;    
    signal b_10_r1, b_10_r2, b_10_r3,  b_11_r1, b_11_r2, b_11_r3 : word_t;
    signal next_b_00_r1, next_b_00_r2, next_b_00_r3, next_b_01_r1, next_b_01_r2, next_b_01_r3 : word_t;
    signal next_b_10_r1, next_b_10_r2, next_b_10_r3, next_b_11_r1, next_b_11_r2, next_b_11_r3 : word_t;

    signal next_counter, counter : unsigned(0 to 3);

    type sobel_matrix is array (0 to 2, 0 to 2) of integer range -2 to 2;
    constant sobel_x : sobel_matrix := ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1));
    constant sobel_y : sobel_matrix := ((-1, -2, -1), (0, 0, 0), (1, 2, 1));



begin

    cl : process(start, state, next_state, next_reg_addr, data_r, data_w, next_data_w)
    begin
        next_state <= state;
        next_reg_addr <= reg_addr;
        next_data_w <= data_w;

        en <= '0';
        we <= '0';
        -- reg_addr <= cursor_x + cursor_y;
        dataW <= data_w;

        next_cursor_x <= cursor_x;
        next_cursor_y <= cursor_y;
        next_counter <= counter;


        
        
        case state is

            when idle =>
                if start = '1' then
                    next_state <= read;
                end if;
            
            when read =>
                en <= '1';
                case counter is
                    when "0000" =>  -- 0
                        next_cursor_x <= std_logic_vector(unsigned(cursor_x) + to_unsigned(1, 16));
                        addr <= std_logic_vector(unsigned(cursor_x) + unsigned(cursor_y));
                        next_counter <= counter + 1;

                    when "0001" =>  -- 1
                        next_cursor_y <= std_logic_vector(unsigned(cursor_y) + IMG_WIDTH);
                        next_b_00_r1 <= dataR;
                        next_counter <= counter + 1;
                        
                    when "0010" =>
                        next_cursor_x <= std_logic_vector(unsigned(cursor_x) + to_unsigned(1, 16));
                        next_b_01_r1 <= dataR;
                        next_counter <= counter + 1;
                    
                    when "0011" =>
                        next_cursor_y <= std_logic_vector(unsigned(cursor_y) + IMG_WIDTH);
                        next_b_00_r2 <= dataR;
                        next_counter <= counter + 1;
                    
                    when "0100" =>
                        next_cursor_x <= std_logic_vector(unsigned(cursor_x) + to_unsigned(1, 16));
                        next_b_01_r2 <= dataR;
                        next_counter <= counter + 1;
                    
                    when "0101" =>
                        next_cursor_y <= std_logic_vector(unsigned(cursor_y) + IMG_WIDTH);
                        next_b_00_r3 <= dataR;
                        next_counter <= counter + 1;

                    when "0110" =>
                        next_cursor_x <= std_logic_vector(unsigned(cursor_x) + to_unsigned(1, 16));
                        next_b_01_r3 <= dataR;
                        next_counter <= counter + 1;

                    when "0111" =>
                        next_cursor_y <= std_logic_vector(unsigned(cursor_y) + IMG_WIDTH);
                        next_b_10_r1 <= dataR;
                        next_counter <= counter + 1;

                    when "1000" =>
                        next_cursor_x <= std_logic_vector(unsigned(cursor_x) + to_unsigned(1, 16));
                        next_b_11_r1 <= dataR;
                        next_state <= compute_and_write;
                    
                    when "1001" =>
                        next_cursor_y <= std_logic_vector(unsigned(cursor_y) + IMG_WIDTH);
                        next_b_10_r2 <= dataR;
                        next_counter <= counter + 1;

                    when "1010" =>
                        next_cursor_x <= std_logic_vector(unsigned(cursor_x) + to_unsigned(1, 16));
                        next_b_11_r2 <= dataR;
                        next_counter <= counter + 1;

                    when "1011" =>
                        next_cursor_y <= std_logic_vector(unsigned(cursor_y) + IMG_WIDTH);
                        next_b_10_r3 <= dataR;
                        next_counter <= counter + 1;

                    when "1100" =>
                        next_b_11_r3 <= dataR;
                        next_counter <= "0000";
                        next_state <= compute_and_write;
                    
                    when others =>
                        next_state <= idle;
                end case;    
            
            when compute_and_write =>
                -- Perform convolution with Sobel operator
                -- Multiply the 3x3 neighborhood of pixels with sobel_x and sobel_y
                -- Sum the results to get the gradient in x and y directions
                -- Compute the magnitude of the gradient and write it to the memory

                -- Example of convolution operation (simplified):
                -- gradient_x <= sobel_x(0,0) * b_00_r1 + sobel_x(0,1) * b_00_r2 + sobel_x(0,2) * b_00_r3 +
                --               sobel_x(1,0) * b_01_r1 + sobel_x(1,1) * b_01_r2 + sobel_x(1,2) * b_01_r3 +
                --               sobel_x(2,0) * b_10_r1 + sobel_x(2,1) * b_10_r2 + sobel_x(2,2) * b_10_r3;
                -- gradient_y <= sobel_y(0,0) * b_00_r1 + sobel_y(0,1) * b_00_r2 + sobel_y(0,2) * b_00_r3 +
                --               sobel_y(1,0) * b_01_r1 + sobel_y(1,1) * b_01_r2 + sobel_y(1,2) * b_01_r3 +
                --               sobel_y(2,0) * b_10_r1 + sobel_y(2,1) * b_10_r2 + sobel_y(2,2) * b_10_r3;
                -- magnitude <= sqrt(gradient_x * gradient_x + gradient_y * gradient_y);

                -- Write the magnitude to the memory
                -- dataW <= magnitude;


                -- Write enable and address setup
                en <= '1';
                we <= '1';

                next_b_00_r2(15 downto 8) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r1(7  downto 0)))   * sobel_x(0,0) + 
                        to_integer(signed(b_00_r1(23 downto 16)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r2(7  downto 0)))   * sobel_x(1,0) + 
                        to_integer(signed(b_00_r2(23 downto 16)))  * sobel_x(1,2) +
                        to_integer(signed(b_00_r3(7  downto 0)))   * sobel_x(2,0) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r1(7  downto 0)))   * sobel_y(0,0) + 
                        to_integer(signed(b_00_r3(7  downto 0)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r1(15 downto 8)))   * sobel_y(0,1) + 
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_y(2,1) +
                        to_integer(signed(b_00_r1(23 downto 16)))  * sobel_y(0,2) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_y(2,2)
                    )
                ),8));

                next_b_00_r2(23 downto 16) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r1(15 downto 8)))   * sobel_x(0,0) + 
                        to_integer(signed(b_00_r1(31 downto 24)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r2(15 downto 8)))   * sobel_x(1,0) + 
                        to_integer(signed(b_00_r2(31 downto 24)))  * sobel_x(1,2) +
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_x(2,0) + 
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r1(15 downto 8)))   * sobel_y(0,0) + 
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r1(23 downto 16)))  * sobel_y(0,1) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_y(2,1) +
                        to_integer(signed(b_00_r1(31 downto 24)))  * sobel_y(0,2) + 
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_y(2,2)
                    )
                ), 8));

                next_b_00_r2(31 downto 24) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r1(23 downto 16)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r1(7 downto 0)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r2(23 downto 16)))   * sobel_x(1,0) + 
                        to_integer(signed(b_01_r2(7 downto 0)))  * sobel_x(1,2) +
                        to_integer(signed(b_00_r3(23 downto 16)))   * sobel_x(2,0) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r1(23 downto 16)))   * sobel_y(0,0) + 
                        to_integer(signed(b_00_r3(23 downto 16)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r1(31 downto 24)))  * sobel_y(0,1) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_y(2,1) +
                        to_integer(signed(b_01_r1(7 downto 0)))  * sobel_y(0,2) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_y(2,2)
                    )
                ), 8));

                next_b_01_r2(7 downto 0) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r1(31 downto 24)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r1(15 downto 8)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r2(31 downto 24)))   * sobel_x(1,0) + 
                        to_integer(signed(b_01_r2(15 downto 8)))  * sobel_x(1,2) +
                        to_integer(signed(b_00_r3(31 downto 24)))   * sobel_x(2,0) + 
                        to_integer(signed(b_01_r3(15 downto 8)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r1(31 downto 24)))   * sobel_y(0,0) + 
                        to_integer(signed(b_00_r3(31 downto 24)))   * sobel_y(2,0) +
                        to_integer(signed(b_01_r1(7 downto 0)))  * sobel_y(0,1) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_y(2,1) +
                        to_integer(signed(b_01_r1(15 downto 8)))  * sobel_y(0,2) + 
                        to_integer(signed(b_01_r3(15 downto 8)))  * sobel_y(2,2)
                    )
                ), 8));

                next_b_00_r3(15 downto 8) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r2(7  downto 0)))   * sobel_x(0,0) + 
                        to_integer(signed(b_00_r2(23 downto 16)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r3(7  downto 0)))   * sobel_x(1,0) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_x(1,2) +
                        to_integer(signed(b_10_r1(7  downto 0)))   * sobel_x(2,0) + 
                        to_integer(signed(b_10_r1(23 downto 16)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r2(7  downto 0)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r1(7  downto 0)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r2(15 downto 8)))   * sobel_y(0,1) + 
                        to_integer(signed(b_10_r1(15 downto 8)))   * sobel_y(2,1) +
                        to_integer(signed(b_00_r2(23 downto 16)))  * sobel_y(0,2) + 
                        to_integer(signed(b_10_r1(23 downto 16)))  * sobel_y(2,2)
                    )
                ),8));

                next_b_00_r3(23 downto 16) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r1(15 downto 8)))   * sobel_x(0,0) + 
                        to_integer(signed(b_00_r1(31 downto 24)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r2(15 downto 8)))   * sobel_x(1,0) + 
                        to_integer(signed(b_00_r2(31 downto 24)))  * sobel_x(1,2) +
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_x(2,0) + 
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r1(15 downto 8)))   * sobel_y(0,0) + 
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r1(23 downto 16)))  * sobel_y(0,1) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_y(2,1) +
                        to_integer(signed(b_00_r1(31 downto 24)))  * sobel_y(0,2) + 
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_y(2,2)
                    )
                ),8));

                next_b_00_r3(31 downto 24) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r1(23 downto 5)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r1(7 downto 0)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r2(23 downto 5)))   * sobel_x(1,0) + 
                        to_integer(signed(b_01_r2(7 downto 0)))  * sobel_x(1,2) +
                        to_integer(signed(b_00_r3(23 downto 5)))   * sobel_x(2,0) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r1(23 downto 16)))   * sobel_y(0,0) + 
                        to_integer(signed(b_00_r3(23 downto 16)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r1(31 downto 24)))  * sobel_y(0,1) + 
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_y(2,1) +
                        to_integer(signed(b_01_r1(7 downto 0)))  * sobel_y(0,2) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_y(2,2)
                    )
                ),8));

                next_b_01_r3(7 downto 0) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r2(31 downto 24)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r2(15 downto 8)))  * sobel_x(0,2) +
                        to_integer(signed(b_00_r3(31 downto 24)))   * sobel_x(1,0) + 
                        to_integer(signed(b_01_r3(15 downto 8)))  * sobel_x(1,2) +
                        to_integer(signed(b_10_r1(31 downto 24)))   * sobel_x(2,0) + 
                        to_integer(signed(b_11_r1(15 downto 8)))  * sobel_x(2,2)
                    ) +
                    (
                        to_integer(signed(b_00_r2(23 downto 16)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r1(23 downto 16)))   * sobel_y(2,0) +
                        to_integer(signed(b_00_r2(31 downto 24)))  * sobel_y(0,1) + 
                        to_integer(signed(b_10_r1(31 downto 24)))  * sobel_y(2,1) +
                        to_integer(signed(b_10_r2(7 downto 0)))  * sobel_y(0,2) + 
                        to_integer(signed(b_11_r1(7 downto 0)))  * sobel_y(2,2)
                    )
                ),8));


                next_b_10_r1(15 downto 8) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r3(7  downto 0)))   * sobel_x(0,0) + 
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_x(0,3) +
                        to_integer(signed(b_10_r1(7  downto 0)))   * sobel_x(1,0) + 
                        to_integer(signed(b_10_r1(23 downto 16)))  * sobel_x(1,3) +
                        to_integer(signed(b_10_r2(7  downto 0)))   * sobel_x(2,0) + 
                        to_integer(signed(b_10_r2(23 downto 16)))  * sobel_x(2,3)
                    ) +
                    (
                        to_integer(signed(b_00_r3(7  downto 0)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r2(7  downto 0)))   * sobel_y(0,3) +
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_y(1,0) + 
                        to_integer(signed(b_10_r2(15 downto 8)))   * sobel_y(1,3) +
                        to_integer(signed(b_00_r3(23 downto 16)))  * sobel_y(2,0) + 
                        to_integer(signed(b_10_r2(23 downto 16)))  * sobel_y(2,3)
                    )
                ),8));

                next_b_10_r1(23 downto 16) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r3(15  downto 8)))   * sobel_x(0,0) + 
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_x(0,3) +
                        to_integer(signed(b_10_r1(15  downto 8)))   * sobel_x(1,0) + 
                        to_integer(signed(b_10_r1(31 downto 24)))  * sobel_x(1,3) +
                        to_integer(signed(b_10_r2(15  downto 8)))   * sobel_x(2,0) + 
                        to_integer(signed(b_10_r2(31 downto 24)))  * sobel_x(2,3)
                    ) +
                    (
                        to_integer(signed(b_00_r3(15 downto 8)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r2(15 downto 8)))   * sobel_y(0,3) +
                        to_integer(signed(b_00_r3(23 downto 16)))   * sobel_y(1,0) + 
                        to_integer(signed(b_10_r2(23 downto 16)))   * sobel_y(1,3) +
                        to_integer(signed(b_00_r3(31 downto 24)))  * sobel_y(2,0) + 
                        to_integer(signed(b_10_r2(31 downto 24)))  * sobel_y(2,3)
                    )
                ),8));
                
                next_b_10_r1(31 downto 24) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r3(23  downto 15)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_x(0,3) +
                        to_integer(signed(b_10_r1(23  downto 15)))   * sobel_x(1,0) + 
                        to_integer(signed(b_11_r1(7 downto 0)))  * sobel_x(1,3) +
                        to_integer(signed(b_10_r2(23  downto 15)))   * sobel_x(2,0) + 
                        to_integer(signed(b_11_r2(7 downto 0)))  * sobel_x(2,3)
                    ) +
                    (
                        to_integer(signed(b_00_r3(23  downto 15)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r2(23  downto 15)))   * sobel_y(0,3) +
                        to_integer(signed(b_00_r3(31 downto 24)))   * sobel_y(1,0) + 
                        to_integer(signed(b_10_r2(31 downto 24)))   * sobel_y(1,3) +
                        to_integer(signed(b_10_r3(7 downto 0)))  * sobel_y(2,0) + 
                        to_integer(signed(b_11_r2(7 downto 0)))  * sobel_y(2,3)
                    )
                ),8));

                next_b_10_r1(31 downto 24) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r3(23  downto 15)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r3(7 downto 0)))  * sobel_x(0,3) +
                        to_integer(signed(b_10_r1(23  downto 15)))   * sobel_x(1,0) + 
                        to_integer(signed(b_11_r1(7 downto 0)))  * sobel_x(1,3) +
                        to_integer(signed(b_10_r2(23  downto 15)))   * sobel_x(2,0) + 
                        to_integer(signed(b_11_r2(7 downto 0)))  * sobel_x(2,3)
                    ) +
                    (
                        to_integer(signed(b_00_r3(23  downto 15)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r2(23  downto 15)))   * sobel_y(0,3) +
                        to_integer(signed(b_00_r3(31 downto 24)))   * sobel_y(1,0) + 
                        to_integer(signed(b_10_r2(31 downto 24)))   * sobel_y(1,3) +
                        to_integer(signed(b_10_r3(7 downto 0)))  * sobel_y(2,0) + 
                        to_integer(signed(b_11_r2(7 downto 0)))  * sobel_y(2,3)
                    )
                ),8));

                next_b_11_r1(7 downto 0) <= std_logic_vector(to_unsigned(abs(
                    (
                        to_integer(signed(b_00_r3(31  downto 24)))   * sobel_x(0,0) + 
                        to_integer(signed(b_01_r3(15 downto 8)))  * sobel_x(0,3) +
                        to_integer(signed(b_10_r1(31  downto 24)))   * sobel_x(1,0) + 
                        to_integer(signed(b_11_r1(15 downto 8)))  * sobel_x(1,3) +
                        to_integer(signed(b_10_r2(31  downto 24)))   * sobel_x(2,0) + 
                        to_integer(signed(b_11_r2(15 downto 8)))  * sobel_x(2,3)
                    ) +
                    (
                        to_integer(signed(b_00_r3(31  downto 24)))   * sobel_y(0,0) + 
                        to_integer(signed(b_10_r2(31  downto 24)))   * sobel_y(0,3) +
                        to_integer(signed(b_10_r3(7 downto 0)))   * sobel_y(1,0) + 
                        to_integer(signed(b_11_r2(7 downto 0)))   * sobel_y(1,3) +
                        to_integer(signed(b_10_r3(15 downto 8)))  * sobel_y(2,0) + 
                        to_integer(signed(b_11_r2(15 downto 8)))  * sobel_y(2,3)
                    )
                ),8));


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
                reg_addr <= (others => '0');
                data_r <= (others => '0');
                data_w <= (others => '0');

                cursor_x <= (others => '0');
                cursor_y <= (others => '0');

                read_all <= '0';
           else
                state <= next_state;
                reg_addr <= next_reg_addr;
                data_w <= next_data_w;

                cursor_x <= next_cursor_x;
                cursor_y <= next_cursor_y;

                b_00_r1 <= next_b_00_r1;
                b_00_r2 <= next_b_00_r2;
                b_00_r3 <= next_b_00_r3;
                b_01_r1 <= next_b_01_r1;
                b_01_r2 <= next_b_01_r2;
                b_01_r3 <= next_b_01_r3;
                b_10_r1 <= next_b_10_r1;
                b_10_r2 <= next_b_10_r2;
                b_10_r3 <= next_b_10_r3;
                b_11_r1 <= next_b_11_r1;
                b_11_r2 <= next_b_11_r2;
                b_11_r3 <= next_b_11_r3;

           end if;
       end if;
   end process seq;

end rtl;
