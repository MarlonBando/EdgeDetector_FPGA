-- -----------------------------------------------------------------------------
--
--  Title      :  Controller to manange the picture transfer to and from the PC.
--             :
--  Developers :  Luca Pezzarossa - lpez@dtu.dk
--             :
--  Revision   :  1.0    15-09-17    Initial version
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    generic(
        MEMORY_ADDR_SIZE : integer := 16
    );
    port(
        clk                : in  std_logic;
        reset              : in  std_logic;

        -- tx and rx are form the fsm poiont of view rx <= tx
        data_stream_tx     : out std_logic_vector(7 downto 0);
        data_stream_tx_stb : out std_logic;
        data_stream_tx_ack : in  std_logic;
        data_stream_rx     : in  std_logic_vector(7 downto 0);
        data_stream_rx_stb : in  std_logic;

        mem_en             : out std_logic;
        mem_we             : out std_logic;
        mem_addr           : out std_logic_vector(MEMORY_ADDR_SIZE-1 downto 0);
        mem_dw             : out std_logic_vector(31 downto 0);
        mem_dr             : in  std_logic_vector(31 downto 0)
    );
end controller;

architecture rtl of controller is
    constant ADDR_COUNT_SIZE           : integer                                := MEMORY_ADDR_SIZE; -- The size of the memory address counter
    constant ADDR_COUNT_MIN            : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(0, ADDR_COUNT_SIZE); -- Initial address of the memory
    constant ADDR_COUNT_DOWNLOAD_START : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(0, ADDR_COUNT_SIZE); -- First pixel address of the memory for the download image
    constant ADDR_COUNT_DOWNLOAD_END   : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(25343, ADDR_COUNT_SIZE); -- Last pixel address of the memory for the download image
    constant ADDR_COUNT_UPLOAD_START   : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(25344, ADDR_COUNT_SIZE); -- First pixel address of the memory for the upload image
    constant ADDR_COUNT_UPLOAD_END     : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(50687, ADDR_COUNT_SIZE); -- Last pixel address of the memory for the upload image
    constant ADDR_COUNT_MAX            : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(65535, ADDR_COUNT_SIZE); -- Final address of the memory

    type state_type is (START, WAIT_AND_CHECK_COMMAND, REPLY_TEST, CLEAR,
                        DOWNLOAD_B0, DOWNLOAD_B1, DOWNLOAD_B2, DOWNLOAD_B3, STORE_DOWNLOAD,
                        UPLOAD_B0, UPLOAD_B1, UPLOAD_B2, UPLOAD_B3, UPLOAD_WAIT, UPLOAD_CHECK);
    signal state, state_next : state_type;

    signal data_buffer, data_buffer_next : std_logic_vector(31 downto 0);
    signal addr_count, addr_count_next : unsigned(15 downto 0);

begin
    mem_addr <= std_logic_vector(addr_count);
    mem_dw   <= data_buffer;

    process(state, data_stream_tx_ack, data_stream_rx, data_stream_rx_stb, addr_count, mem_dr, data_buffer)
    begin
        data_stream_tx     <= (others => '0');
        data_stream_tx_stb <= '0';
        state_next         <= state;
        data_buffer_next   <= data_buffer;
        addr_count_next    <= addr_count;
        mem_en             <= '0';
        mem_we             <= '0';

        case state is
            when START =>
                data_buffer_next <= (others => '0');
                addr_count_next  <= ADDR_COUNT_MIN;
                state_next       <= CLEAR;

            when CLEAR =>
                -- store data in memory
                mem_en <= '1';
                mem_we <= '1';
                if (addr_count = ADDR_COUNT_MAX) then
                    state_next <= WAIT_AND_CHECK_COMMAND;
                else
                    addr_count_next <= addr_count + 1;
                    state_next      <= CLEAR;
                end if;

            when WAIT_AND_CHECK_COMMAND =>
                if data_stream_rx_stb = '0' then
                    -- nothing to read
                    state_next <= WAIT_AND_CHECK_COMMAND;
                else
                    --read the content and act
                    if data_stream_rx = x"74" then --ascii = t
                        state_next <= REPLY_TEST;
                    elsif data_stream_rx = x"72" then --ascii = r
                        addr_count_next <= ADDR_COUNT_UPLOAD_START;
                        state_next      <= UPLOAD_WAIT;
                    elsif data_stream_rx = x"77" then --ascii = w
                        addr_count_next <= ADDR_COUNT_DOWNLOAD_START;
                        state_next      <= DOWNLOAD_B0;
                    elsif data_stream_rx = x"63" then --ascii = c
                        data_buffer_next <= (others => '0');
                        addr_count_next  <= ADDR_COUNT_MIN;
                        state_next       <= CLEAR;
                    else
                        state_next <= WAIT_AND_CHECK_COMMAND;
                    end if;
                end if;

            when REPLY_TEST =>
                data_stream_tx     <= x"79"; -- ascii = y
                data_stream_tx_stb <= '1';
                if data_stream_tx_ack = '0' then
                    state_next <= REPLY_TEST;
                else
                    state_next <= WAIT_AND_CHECK_COMMAND;
                end if;

            when DOWNLOAD_B0 =>
                if data_stream_rx_stb = '0' then --uart_rd_data(1) goes to  '1' when there is something to read
                    --I must wait
                    state_next <= DOWNLOAD_B0;
                else
                    -- I can read
                    data_buffer_next(7 downto 0) <= data_stream_rx;
                    state_next                   <= DOWNLOAD_B1;
                end if;

            when DOWNLOAD_B1 =>
                if data_stream_rx_stb = '0' then --uart_rd_data(1) goes to  '1' when there is something to read
                    --I must wait
                    state_next <= DOWNLOAD_B1;
                else
                    -- I can read
                    data_buffer_next(15 downto 8) <= data_stream_rx;
                    state_next                    <= DOWNLOAD_B2;
                end if;

            when DOWNLOAD_B2 =>
                if data_stream_rx_stb = '0' then --uart_rd_data(1) goes to  '1' when there is something to read
                    --I must wait
                    state_next <= DOWNLOAD_B2;
                else
                    -- I can read
                    data_buffer_next(23 downto 16) <= data_stream_rx;
                    state_next                     <= DOWNLOAD_B3;
                end if;

            when DOWNLOAD_B3 =>
                if data_stream_rx_stb = '0' then --uart_rd_data(1) goes to  '1' when there is something to read
                    --I must wait
                    state_next <= DOWNLOAD_B3;
                else
                    -- I can read
                    data_buffer_next(31 downto 24) <= data_stream_rx;
                    state_next                     <= STORE_DOWNLOAD;
                end if;

            when STORE_DOWNLOAD =>
                -- store data in memory
                mem_en <= '1';
                mem_we <= '1';
                if (addr_count = ADDR_COUNT_DOWNLOAD_END) then
                    state_next <= WAIT_AND_CHECK_COMMAND;
                else
                    addr_count_next <= addr_count + 1;
                    state_next      <= DOWNLOAD_B0;
                end if;

            when UPLOAD_WAIT =>
                mem_en     <= '1';
                state_next <= UPLOAD_B0;

            when UPLOAD_B0 =>
                mem_en             <= '1';
                data_stream_tx     <= mem_dr(7 downto 0);
                data_stream_tx_stb <= '1';
                if data_stream_tx_ack = '0' then
                    state_next <= UPLOAD_B0;
                else
                    state_next <= UPLOAD_B1;
                end if;

            when UPLOAD_B1 =>
                mem_en             <= '1';
                data_stream_tx     <= mem_dr(15 downto 8);
                data_stream_tx_stb <= '1';
                if data_stream_tx_ack = '0' then
                    state_next <= UPLOAD_B1;
                else
                    state_next <= UPLOAD_B2;
                end if;

            when UPLOAD_B2 =>
                mem_en             <= '1';
                data_stream_tx     <= mem_dr(23 downto 16);
                data_stream_tx_stb <= '1';
                if data_stream_tx_ack = '0' then
                    state_next <= UPLOAD_B2;
                else
                    state_next <= UPLOAD_B3;
                end if;

            when UPLOAD_B3 =>
                mem_en             <= '1';
                data_stream_tx     <= mem_dr(31 downto 24);
                data_stream_tx_stb <= '1';
                if data_stream_tx_ack = '0' then
                    state_next <= UPLOAD_B3;
                else
                    state_next <= UPLOAD_CHECK;
                end if;

            when UPLOAD_CHECK =>
                if (addr_count = ADDR_COUNT_UPLOAD_END) then
                    state_next <= WAIT_AND_CHECK_COMMAND;
                else
                    mem_en          <= '1';
                    addr_count_next <= addr_count + 1;
                    state_next      <= UPLOAD_B0;
                end if;

            when others =>
                state_next <= state;
        end case;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= START;
                data_buffer <= (others => '0');
                addr_count  <= (others => '0');
            else
                state       <= state_next;
                data_buffer <= data_buffer_next;
                addr_count  <= addr_count_next;
            end if;
        end if;
    end process;

end rtl;
