-- -----------------------------------------------------------------------------
--
--  Title      :  Top level for task 2 of the Edge-Detection design project.
--             :
--  Developers :  Luca Pezzarossa - lpez@dtu.dk
--             :
--  Purpose    :  A top-level entity connecting all the components.
--             :
--             :
--  Revision   :  1.0    15-09-17    Initial version
--
-- -----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity top is
    port(
        clk_100mhz : in  std_logic;
        rst        : in  std_logic;
        led        : out std_logic;
        start      : in  std_logic;
        -- Serial interface for PC communication
        serial_tx  : in  STD_LOGIC;     -- from the PC
        serial_rx  : out STD_LOGIC      -- to the PC
    );
end top;

architecture structure of top is

    -- The accelerator clock frequency will be (100MHz/CLK_DIVISION_FACTOR)
    constant CLK_DIVISION_FACTOR : integer := 2; --(1 to 7)

    signal clk   : bit_t;
    signal rst_s : std_logic;

    signal addr     : halfword_t;
    signal dataR    : word_t;
    signal dataW    : word_t;
    signal en       : bit_t;
    signal we       : bit_t;
    signal finish   : bit_t;
    signal start_db : bit_t;

    signal mem_enb   : std_logic;
    signal mem_web   : std_logic;
    signal mem_addrb : std_logic_vector(15 downto 0);
    signal mem_dib   : std_logic_vector(31 downto 0);
    signal mem_dob   : std_logic_vector(31 downto 0);

    signal data_stream_in      : std_logic_vector(7 downto 0);
    signal data_stream_in_stb  : std_logic;
    signal data_stream_in_ack  : std_logic;
    signal data_stream_out     : std_logic_vector(7 downto 0);
    signal data_stream_out_stb : std_logic;

begin
    led <= finish;

    clock_divider_inst_0 : entity work.clock_divider
        generic map(
            DIVIDE => CLK_DIVISION_FACTOR
        )
        port map(
            clk_in  => clk_100mhz,
            clk_out => clk
        );

    debounce_inst_0 : entity work.debounce
        port map(
            clk        => clk,
            reset      => rst,
            sw         => start,
            db_level   => start_db,
            db_tick    => open,
            reset_sync => rst_s
        );

    accelerator_inst_0 : entity work.acc
        port map(
            clk    => clk,
            reset  => rst_s,
            addr   => addr,
            dataR  => dataR,
            dataW  => dataW,
            en     => en,
            we     => we,
            start  => start_db,
            finish => finish
        );

    controller_inst_0 : entity work.controller
        generic map(
            MEMORY_ADDR_SIZE => 16
        )
        port map(
            clk                => clk,
            reset              => rst_s,
            data_stream_tx     => data_stream_in,
            data_stream_tx_stb => data_stream_in_stb,
            data_stream_tx_ack => data_stream_in_ack,
            data_stream_rx     => data_stream_out,
            data_stream_rx_stb => data_stream_out_stb,
            mem_en             => mem_enb,
            mem_we             => mem_web,
            mem_addr           => mem_addrb,
            mem_dw             => mem_dib,
            mem_dr             => mem_dob
        );

    uart_inst_0 : entity work.uart
        generic map(
            baud            => 115200,
            clock_frequency => positive(100_000_000 / CLK_DIVISION_FACTOR)
        )
        port map(
            clock               => clk,
            reset               => rst_s,
            data_stream_in      => data_stream_in,
            data_stream_in_stb  => data_stream_in_stb,
            data_stream_in_ack  => data_stream_in_ack,
            data_stream_out     => data_stream_out,
            data_stream_out_stb => data_stream_out_stb,
            tx                  => serial_rx,
            rx                  => serial_tx
        );

    memory3_inst_0 : entity work.memory3
        generic map(
            ADDR_SIZE => 16
        )
        port map(
            clk   => clk,
            -- Port a (for the accelerator)
            ena   => en,
            wea   => we,
            addra => addr,
            dia   => dataW,
            doa   => dataR,
            -- Port b (for the uart/controller)
            enb   => mem_enb,
            web   => mem_web,
            addrb => mem_addrb,
            dib   => mem_dib,
            dob   => mem_dob
        );

end structure;
