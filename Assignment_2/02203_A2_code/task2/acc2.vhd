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
    generic (
        MAX_ADDR : unsigned(15 downto 0) := to_unsigned(25344, 16);
        MAX_ROW : unsigned(15 downto 0) := to_unsigned(288, 16);
        MAX_COL : unsigned(15 downto 0) := to_unsigned(88, 16);
        MAX_PIMAGE_ADDR : unsigned(15 downto 0) := to_unsigned(50688, 16)
    );
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
-- The desription of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc is

    -- All internal signals are defined here
    type state_type is (idle, read_R0, read_R1, read_R2, read_R2_wait,
        write, compute_edge_FH, compute_edge_SH, shift_matrix, done);
    type pixel_matrix_type is array (0 to 2, 0 to 5) of std_logic_vector(7 downto 0);
    type computed_pixels_type is array (0 to 3) of std_logic_vector(7 downto 0);

    signal next_dataW, internal_dataW : word_t;
    signal next_addr, internal_addr : halfword_t;
    signal state, next_state : state_type;
    signal dx_0, dx_1, dx_2, dx_3, dy_0, dy_1, dy_2, dy_3 : std_logic_vector(7 downto 0);
    signal dn_0, dn_1, dn_2, dn_3 : std_logic_vector(7 downto 0);
    signal pixel_matrix : pixel_matrix_type;
    signal computer_pixels : computed_pixels_type;
    signal next_col, next_row : unsigned(15 downto 0) := (others => '0');
    signal col, row : unsigned(15 downto 0) := (others => '0');

    signal half_select : bit_t := '0';

    constant TWO : signed(7 downto 0) := to_signed(2, 8);
    constant THRESHOLD : unsigned(7 downto 0) := to_unsigned(255, 8); -- Example threshold value

    function min(a : unsigned; b : unsigned) return unsigned is
    begin
        if a < b then
            return a;
        else
            return b;
        end if;
    end function;

    -- Function to compute dx for a given row and column
    function compute_dx(pixel_matrix : in pixel_matrix_type; row : integer; col : integer) return std_logic_vector is
        variable dx : signed(15 downto 0);
        variable s13, s11, s23, s21, s33, s31 : integer;
    begin
        s13 := to_integer(unsigned(pixel_matrix(row - 1, col + 1)));
        s11 := to_integer(unsigned(pixel_matrix(row - 1, col - 1)));
        s23 := to_integer(unsigned(pixel_matrix(row, col + 1)));
        s21 := to_integer(unsigned(pixel_matrix(row, col - 1)));
        s33 := to_integer(unsigned(pixel_matrix(row + 1, col + 1)));
        s31 := to_integer(unsigned(pixel_matrix(row + 1, col - 1)));

        dx := to_signed((s13 - s11) + 2 * (s23 - s21) + (s33 - s31), 16);
        return std_logic_vector(resize(dx, 8));
    end function;

    -- Function to compute dy for a given row and column
    function compute_dy(pixel_matrix : in pixel_matrix_type; row : integer; col : integer) return std_logic_vector is
        variable dy : signed(15 downto 0);
        variable s11, s31, s12, s32, s13, s33 : integer;
    begin
        s11 := to_integer(unsigned(pixel_matrix(row - 1, col - 1)));
        s31 := to_integer(unsigned(pixel_matrix(row + 1, col - 1)));
        s12 := to_integer(unsigned(pixel_matrix(row - 1, col)));
        s32 := to_integer(unsigned(pixel_matrix(row + 1, col)));
        s13 := to_integer(unsigned(pixel_matrix(row - 1, col + 1)));
        s33 := to_integer(unsigned(pixel_matrix(row + 1, col + 1)));

        dy := to_signed((s11 - s31) + 2 * (s12 - s32) + (s13 - s33), 16);
        return std_logic_vector(resize(dy, 8));
    end function;

    -- Function to compute dn (magnitude of gradient)
    function compute_dn(dx : in std_logic_vector; dy : in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(min(unsigned(resize(abs(signed(dx)) + abs(signed(dy)), 8)), THRESHOLD));
    end function;

begin

    -- Update the cl process to use internal signals
    cl : process (start, state, next_state, next_addr, next_dataW, col, row, half_select, dataR)
    begin

        next_state <= state;
        en <= '0';
        we <= '0';
        finish <= '0';
        next_col <= col;
        next_row <= row;

        case state is

            when idle =>
                if start = '1' then
                    next_state <= read_R0;
                end if;

            when read_R0 =>
                en <= '1';
                addr <= std_logic_vector(to_unsigned(to_integer(row) * 88 + to_integer(col), addr'length));
                next_state <= read_R1;

            when read_R1 =>
                en <= '1';
                addr <= std_logic_vector(to_unsigned(to_integer(row + 1) * 88 + to_integer(col), addr'length));
                next_state <= read_R2;

                if col < 1 then
                    pixel_matrix(0, 0) <= dataR(7 downto 0);
                    pixel_matrix(0, 1) <= dataR(15 downto 8);
                    pixel_matrix(0, 2) <= dataR(23 downto 16);
                    pixel_matrix(0, 3) <= dataR(31 downto 24);
                else
                    pixel_matrix(0, 2) <= dataR(7 downto 0);
                    pixel_matrix(0, 3) <= dataR(15 downto 8);
                    pixel_matrix(0, 4) <= dataR(23 downto 16);
                    pixel_matrix(0, 5) <= dataR(31 downto 24);
                end if;

            when read_R2 =>
                en <= '1';
                addr <= std_logic_vector(to_unsigned(to_integer(row + 2) * 88 + to_integer(col), addr'length));
                next_state <= read_R2_wait;

                if col < 1 then
                    pixel_matrix(1, 0) <= dataR(7 downto 0);
                    pixel_matrix(1, 1) <= dataR(15 downto 8);
                    pixel_matrix(1, 2) <= dataR(23 downto 16);
                    pixel_matrix(1, 3) <= dataR(31 downto 24);
                else
                    pixel_matrix(1, 2) <= dataR(7 downto 0);
                    pixel_matrix(1, 3) <= dataR(15 downto 8);
                    pixel_matrix(1, 4) <= dataR(23 downto 16);
                    pixel_matrix(1, 5) <= dataR(31 downto 24);
                end if;

            when read_R2_wait =>
                if col < 1 then
                    pixel_matrix(2, 0) <= dataR(7 downto 0);
                    pixel_matrix(2, 1) <= dataR(15 downto 8);
                    pixel_matrix(2, 2) <= dataR(23 downto 16);
                    pixel_matrix(2, 3) <= dataR(31 downto 24);
                else
                    pixel_matrix(2, 2) <= dataR(7 downto 0);
                    pixel_matrix(2, 3) <= dataR(15 downto 8);
                    pixel_matrix(2, 4) <= dataR(23 downto 16);
                    pixel_matrix(2, 5) <= dataR(31 downto 24);
                end if;

                if half_select = '0' then
                    next_state <= compute_edge_FH;
                else
                    next_state <= compute_edge_SH;
                end if;

            when compute_edge_FH =>
                if col < 1 then
                    -- Ignore first column (no padding in that implementation)
                    dn_0 <= pixel_matrix(1, 0);

                    dx_1 <= compute_dx(pixel_matrix, 1, 1);
                    dy_1 <= compute_dy(pixel_matrix, 1, 1);
                    dn_1 <= compute_dn(dx_1, dy_1);

                    dx_2 <= compute_dx(pixel_matrix, 1, 2);
                    dy_2 <= compute_dy(pixel_matrix, 1, 2);
                    dn_2 <= compute_dn(dx_2, dy_2);
                else
                    dx_0 <= compute_dx(pixel_matrix, 1, 2);
                    dy_0 <= compute_dy(pixel_matrix, 1, 2);
                    dn_0 <= compute_dn(dx_0, dy_0);

                    dx_1 <= compute_dx(pixel_matrix, 1, 3);
                    dy_1 <= compute_dy(pixel_matrix, 1, 3);
                    dn_1 <= compute_dn(dx_1, dy_1);

                    dx_2 <= compute_dx(pixel_matrix, 1, 4);
                    dy_2 <= compute_dy(pixel_matrix, 1, 4);
                    dn_2 <= compute_dn(dx_2, dy_2);
                end if;

                if col = MAX_COL - 1 then
                    dn_3 <= pixel_matrix(1, 5);
                    next_state <= write;
                    next_col <= col + 1;
                else
                    next_state <= shift_matrix;
                    half_select <= '1';
                end if;

            when shift_matrix =>
                if col < 1 then
                    pixel_matrix(0, 0) <= pixel_matrix(0, 2);
                    pixel_matrix(1, 0) <= pixel_matrix(1, 2);
                    pixel_matrix(2, 0) <= pixel_matrix(2, 2);
                    pixel_matrix(0, 1) <= pixel_matrix(0, 3);
                    pixel_matrix(1, 1) <= pixel_matrix(1, 3);
                    pixel_matrix(2, 1) <= pixel_matrix(2, 3);
                else
                    pixel_matrix(0, 0) <= pixel_matrix(0, 4);
                    pixel_matrix(1, 0) <= pixel_matrix(1, 4);
                    pixel_matrix(2, 0) <= pixel_matrix(2, 4);
                    pixel_matrix(0, 1) <= pixel_matrix(0, 5);
                    pixel_matrix(1, 1) <= pixel_matrix(1, 5);
                    pixel_matrix(2, 1) <= pixel_matrix(2, 5);
                end if;
                next_col <= col + 1;
                next_state <= read_R0;

            when compute_edge_SH =>
                -- Computing for second case
                dx_3 <= compute_dx(pixel_matrix, 1, 1);
                dy_3 <= compute_dy(pixel_matrix, 1, 1);
                dn_3 <= compute_dn(dx_3, dy_3);

                half_select <= '0';
                next_state <= write;

            when write =>
                en <= '1';
                we <= '1';

                dataW <= dn_3 & dn_2 & dn_1 & dn_0;
                addr <= std_logic_vector(to_unsigned(
                        to_integer(row + 1) * 88 + to_integer(col - 1) + to_integer(MAX_ADDR), addr'length
                        ));

                if row = MAX_ROW - 3 and col = MAX_COL then
                    next_state <= done;
                elsif col = MAX_COL then
                    next_col <= (others => '0');
                    next_row <= row + 1;
                    next_state <= read_R0;
                else
                    next_state <= compute_edge_FH;
                end if;

            when done =>
                finish <= '1';
                next_state <= idle;

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
        elsif rising_edge(clk) then
            state <= next_state;
            col <= next_col;
            row <= next_row;
        end if;

    end process seq;

end rtl;