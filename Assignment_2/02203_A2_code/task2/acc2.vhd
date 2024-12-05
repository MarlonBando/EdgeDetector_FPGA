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
    port (
        clk : in bit_t; -- The clock.
        reset : in bit_t; -- The reset signal. Active high.
        addr : out halfword_t; -- Address bus for data.
        dataR : in word_t; -- The data bus.
        dataW : out word_t; -- The data bus.
        en : out bit_t; -- Request signal for data.
        we : out bit_t; -- Read/Write signal for data.
        start : in bit_t;
        finish : out bit_t
    );
end acc;

--------------------------------------------------------------------------------
-- The description of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc is

    -- All internal signals are defined here
    type state_type is (idle, read_R0, read_R1, read_R2, compute_edge_FH, compute_edge_SH, write, done);
    type pixel_matrix_type is array (0 to 2, 0 to 5) of std_logic_vector(7 downto 0);

    signal state, next_state, last_state : state_type;
    signal dx_0, dx_1, dx_2, dx_3, dy_0, dy_1, dy_2, dy_3 : signed(15 downto 0);
    signal dn_0, dn_1, dn_2, dn_3 : std_logic_vector(7 downto 0);
    signal next_dx_0, next_dx_1, next_dx_2, next_dx_3 : signed(15 downto 0);
    signal next_dy_0, next_dy_1, next_dy_2, next_dy_3 : signed(15 downto 0);
    signal next_dn_0, next_dn_1, next_dn_2, next_dn_3 : std_logic_vector(7 downto 0);
    signal pixel_matrix : pixel_matrix_type;
    signal next_pixel_matrix : pixel_matrix_type;
    signal next_col, next_row : unsigned(15 downto 0) := (others => '0');
    signal col, row : unsigned(15 downto 0) := (others => '0');

    signal half_select : bit_t := '0';
    signal next_half_select : bit_t := '0';
    signal finish_internal : bit_t := '0';

    constant THRESHOLD : unsigned(15 downto 0) := to_unsigned(255, 16);

    constant MAX_ADDR : unsigned(15 downto 0) := to_unsigned(25344, 16);
    constant MAX_ROW : unsigned(15 downto 0) := to_unsigned(288, 16);
    constant MAX_COL : unsigned(15 downto 0) := to_unsigned(88, 16);
    constant MAX_PIMAGE_ADDR : unsigned(15 downto 0) := to_unsigned(50688, 16);

    -- Function to compute dx for a given row and column
    function compute_dx(pixel_matrix : in pixel_matrix_type; row : integer; col : integer) return signed is
        variable dx : signed(23 downto 0);
        variable s13, s11, s23, s21, s33, s31 : signed(11 downto 0);
    begin
        s13 := signed("0000" & pixel_matrix(row - 1, col + 1));
        s11 := signed("0000" & pixel_matrix(row - 1, col - 1));
        s23 := signed("0000" & pixel_matrix(row, col + 1));
        s21 := signed("0000" & pixel_matrix(row, col - 1));
        s33 := signed("0000" & pixel_matrix(row + 1, col + 1));
        s31 := signed("0000" & pixel_matrix(row + 1, col - 1));

        dx := (s13 - s11) + 2 * (s23 - s21) + (s33 - s31);
        return dx(15 downto 0);
    end function;

    -- Function to compute dy for a given row and column
    function compute_dy(pixel_matrix : in pixel_matrix_type; row : integer; col : integer) return signed is
        variable dy : signed(23 downto 0);
        variable s11, s31, s12, s32, s13, s33 : signed(11 downto 0);
    begin
        s11 := signed("0000" & pixel_matrix(row - 1, col - 1));
        s31 := signed("0000" & pixel_matrix(row + 1, col - 1));
        s12 := signed("0000" & pixel_matrix(row - 1, col));
        s13 := signed("0000" & pixel_matrix(row - 1, col + 1));
        s32 := signed("0000" & pixel_matrix(row + 1, col));
        s33 := signed("0000" & pixel_matrix(row + 1, col + 1));

        dy := (s11 - s31) + 2 * (s12 - s32) + (s13 - s33);
        return dy(15 downto 0);
    end function;

    -- Function to compute dn (magnitude of gradient)
    function compute_dn(dx : in signed; dy : in signed) return std_logic_vector is
        variable dn : unsigned(15 downto 0);
    begin
        -- Normalize by a factor of 4
        dn := unsigned((abs(dx) + abs(dy)) srl 2);
        if dn > 255 then
            dn := THRESHOLD; -- Clamp to threshold
        end if;
        return std_logic_vector(dn(7 downto 0)); -- Return 8-bit result
    end function;

begin

    -- Update the cl process to use internal signals
    cl : process (start, state, next_state, last_state, col, row, half_select, dataR, pixel_matrix, dx_0, dy_0,
        dx_1, dy_1, dx_2, dy_2, dx_3, dy_3, dn_0, dn_1, dn_2, dn_3, finish_internal, next_col, next_row,
        next_dx_0, next_dy_0, next_dx_1, next_dy_1, next_dx_2, next_dy_2, next_dx_3, next_dy_3,
        next_dn_0, next_dn_1, next_dn_2, next_dn_3, next_pixel_matrix, next_half_select)
    begin

        en <= '0';
        we <= '0';
        finish <= finish_internal;
        dataW <= (others => '0');
        addr <= (others => '0');

        next_state <= state;
        next_col <= col;
        next_row <= row;
        next_dx_0 <= dx_0;
        next_dy_0 <= dy_0;
        next_dx_1 <= dx_1;
        next_dy_1 <= dy_1;
        next_dx_2 <= dx_2;
        next_dy_2 <= dy_2;
        next_dx_3 <= dx_3;
        next_dy_3 <= dy_3;
        next_dn_0 <= dn_0;
        next_dn_1 <= dn_1;
        next_dn_2 <= dn_2;
        next_dn_3 <= dn_3;
        next_pixel_matrix <= pixel_matrix;
        next_half_select <= half_select;

        case state is

            when idle =>
                if start = '1' then
                    next_state <= read_R0;
                end if;

            when read_R0 =>
                en <= '1';
                addr <= std_logic_vector(to_unsigned(to_integer(row) * 88 + to_integer(col), addr'length));
                next_state <= read_R1;

                -- Shift matrix once compute_edge_FH has occurred and half_select = 1
                if half_select = '1' then
                    if (col - 1) < 1 then
                        next_pixel_matrix(0, 0) <= pixel_matrix(0, 2);
                        next_pixel_matrix(1, 0) <= pixel_matrix(1, 2);
                        next_pixel_matrix(2, 0) <= pixel_matrix(2, 2);
                        next_pixel_matrix(0, 1) <= pixel_matrix(0, 3);
                        next_pixel_matrix(1, 1) <= pixel_matrix(1, 3);
                        next_pixel_matrix(2, 1) <= pixel_matrix(2, 3);
                    else
                        next_pixel_matrix(0, 0) <= pixel_matrix(0, 4);
                        next_pixel_matrix(1, 0) <= pixel_matrix(1, 4);
                        next_pixel_matrix(2, 0) <= pixel_matrix(2, 4);
                        next_pixel_matrix(0, 1) <= pixel_matrix(0, 5);
                        next_pixel_matrix(1, 1) <= pixel_matrix(1, 5);
                        next_pixel_matrix(2, 1) <= pixel_matrix(2, 5);
                    end if;
                end if;

            when read_R1 =>
                en <= '1';
                addr <= std_logic_vector(to_unsigned(to_integer(row + 1) * 88 + to_integer(col), addr'length));
                next_state <= read_R2;
                -- Read the data for row 1, in case of first column then populate from 0 column
                -- As the window slides, populate from offset 2
                if col < 1 then
                    next_pixel_matrix(0, 0) <= dataR(7 downto 0);
                    next_pixel_matrix(0, 1) <= dataR(15 downto 8);
                    next_pixel_matrix(0, 2) <= dataR(23 downto 16);
                    next_pixel_matrix(0, 3) <= dataR(31 downto 24);
                else
                    next_pixel_matrix(0, 2) <= dataR(7 downto 0);
                    next_pixel_matrix(0, 3) <= dataR(15 downto 8);
                    next_pixel_matrix(0, 4) <= dataR(23 downto 16);
                    next_pixel_matrix(0, 5) <= dataR(31 downto 24);
                end if;

            when read_R2 =>
                en <= '1';
                addr <= std_logic_vector(to_unsigned(to_integer(row + 2) * 88 + to_integer(col), addr'length));
                -- Similar as before, this time for row 0
                if col < 1 then
                    next_pixel_matrix(1, 0) <= dataR(7 downto 0);
                    next_pixel_matrix(1, 1) <= dataR(15 downto 8);
                    next_pixel_matrix(1, 2) <= dataR(23 downto 16);
                    next_pixel_matrix(1, 3) <= dataR(31 downto 24);
                else
                    next_pixel_matrix(1, 2) <= dataR(7 downto 0);
                    next_pixel_matrix(1, 3) <= dataR(15 downto 8);
                    next_pixel_matrix(1, 4) <= dataR(23 downto 16);
                    next_pixel_matrix(1, 5) <= dataR(31 downto 24);
                end if;
                -- half_select variable signifies if we are computing
                -- first_half: (1,1) (1,2) when col = 0 else (1, 2), (1,3), (1,4)
                -- second_half: (1,1)
                if half_select = '0' then
                    next_state <= compute_edge_FH;
                else
                    next_state <= compute_edge_SH;
                end if;

            when compute_edge_FH =>
                if col < 1 then
                    -- If the previous state was read_R2, then 
                    -- read the four first pixels of the last row needed for the kernel computation
                    if last_state = read_R2 then
                        next_pixel_matrix(2, 0) <= dataR(7 downto 0);
                        next_pixel_matrix(2, 1) <= dataR(15 downto 8);
                        next_pixel_matrix(2, 2) <= dataR(23 downto 16);
                        next_pixel_matrix(2, 3) <= dataR(31 downto 24);
                    end if;
                    -- Ignore the first column
                    -- (1, 0)
                    next_dn_0 <= (others => '0');
                    -- (1, 1)
                    next_dx_1 <= compute_dx(next_pixel_matrix, 1, 1);
                    next_dy_1 <= compute_dy(next_pixel_matrix, 1, 1);
                    next_dn_1 <= compute_dn(next_dx_1, next_dy_1);
                    -- (1, 2)
                    next_dx_2 <= compute_dx(next_pixel_matrix, 1, 2);
                    next_dy_2 <= compute_dy(next_pixel_matrix, 1, 2);
                    next_dn_2 <= compute_dn(next_dx_2, next_dy_2);

                else
                    -- If the previous state was read_R2, then 
                    -- read the four next pixels (offset 2) of the last row needed for the kernel computation
                    if last_state = read_R2 then
                        next_pixel_matrix(2, 2) <= dataR(7 downto 0);
                        next_pixel_matrix(2, 3) <= dataR(15 downto 8);
                        next_pixel_matrix(2, 4) <= dataR(23 downto 16);
                        next_pixel_matrix(2, 5) <= dataR(31 downto 24);
                    end if;
                    -- (1, 2)
                    next_dx_0 <= compute_dx(next_pixel_matrix, 1, 2);
                    next_dy_0 <= compute_dy(next_pixel_matrix, 1, 2);
                    next_dn_0 <= compute_dn(next_dx_0, next_dy_0);
                    -- (1, 3)
                    next_dx_1 <= compute_dx(next_pixel_matrix, 1, 3);
                    next_dy_1 <= compute_dy(next_pixel_matrix, 1, 3);
                    next_dn_1 <= compute_dn(next_dx_1, next_dy_1);
                    -- (1, 4)
                    next_dx_2 <= compute_dx(next_pixel_matrix, 1, 4);
                    next_dy_2 <= compute_dy(next_pixel_matrix, 1, 4);
                    next_dn_2 <= compute_dn(next_dx_2, next_dy_2);
                end if;
                -- We increment the col to continue the calculations
                next_col <= col + 1;

                if col = MAX_COL - 1 then
                    -- If it is the last column, then we skip the calculation of the last gradient and
                    -- resume to the write state
                    next_dn_3 <= (others => '0');
                    next_state <= write;
                else
                    next_half_select <= '1';
                    -- If not then we enable half select, and go back to reading
                    next_state <= read_R0;
                end if;

            when compute_edge_SH =>
                -- Computing for second case
                next_pixel_matrix(2, 2) <= dataR(7 downto 0);
                next_pixel_matrix(2, 3) <= dataR(15 downto 8);
                next_pixel_matrix(2, 4) <= dataR(23 downto 16);
                next_pixel_matrix(2, 5) <= dataR(31 downto 24);
                --- Compute one more pixel, as we write 4 by 4 to memory
                next_dx_3 <= compute_dx(next_pixel_matrix, 1, 1);
                next_dy_3 <= compute_dy(next_pixel_matrix, 1, 1);
                next_dn_3 <= compute_dn(next_dx_3, next_dy_3);
                -- Disable half-select, the next compute should be the first half of pixels
                next_half_select <= '0';
                next_state <= write;

            when write =>
                -- Signals to enable writing
                en <= '1';
                we <= '1';

                dataW <= dn_3 & dn_2 & dn_1 & dn_0;
                -- We write at row + 1 as we have skipped the first row
                addr <= std_logic_vector(to_unsigned(
                        to_integer(row + 1) * 88 + to_integer(col - 1) + to_integer(MAX_ADDR), addr'length
                        ));
                -- We stop at MAX_ROW - 3, as we process the center pixels with the kernel and we skip the last row
                if row = MAX_ROW - 3 and col = MAX_COL then
                    next_state <= done;
                    -- When we have reached the end of a row (last column), we increment the current row and set back the col to 0
                    -- We are ready to read a new row
                elsif col = MAX_COL then
                    next_col <= (others => '0');
                    next_row <= row + 1;
                    next_state <= read_R0;
                else
                    -- If not at the end of a row or column, then continue with computing
                    next_state <= compute_edge_FH;
                end if;

            when done =>
                if start = '1' then
                    -- We enable finish to signify the end of the process
                    finish <= '1';
                    next_state <= done;
                else
                    next_state <= idle;
                end if;

            when others =>
                next_state <= idle;
        end case;
    end process cl;

    -- Update the seq process to use internal signals
    seq : process (clk, reset)
    begin
        if reset = '1' then
            state <= idle;
            col <= (others => '0');
            row <= (others => '0');
            half_select <= '0';
            dx_0 <= (others => '0');
            dy_0 <= (others => '0');
            dx_1 <= (others => '0');
            dy_1 <= (others => '0');
            dx_2 <= (others => '0');
            dy_2 <= (others => '0');
            dx_3 <= (others => '0');
            dy_3 <= (others => '0');
            dn_0 <= (others => '0');
            dn_1 <= (others => '0');
            dn_2 <= (others => '0');
            dn_3 <= (others => '0');
            pixel_matrix <= (others => (others => (others => '0')));
            finish_internal <= '0'; -- Reset finish signal
        elsif rising_edge(clk) then
            state <= next_state;
            last_state <= state;
            col <= next_col;
            row <= next_row;
            half_select <= next_half_select;
            dx_0 <= next_dx_0;
            dy_0 <= next_dy_0;
            dx_1 <= next_dx_1;
            dy_1 <= next_dy_1;
            dx_2 <= next_dx_2;
            dy_2 <= next_dy_2;
            dx_3 <= next_dx_3;
            dy_3 <= next_dy_3;
            dn_0 <= next_dn_0;
            dn_1 <= next_dn_1;
            dn_2 <= next_dn_2;
            dn_3 <= next_dn_3;
            pixel_matrix <= next_pixel_matrix;

            if state = done then
                finish_internal <= '1';
            end if;
        end if;

    end process seq;

end rtl;
