-- -----------------------------------------------------------------------------
--
--  Title      :  Testbench for task 2 of the Edge-Detection design project.
--             :
--  Developers :  Jonas Benjamin Borch - s052435@student.dtu.dk
--             :
--  Purpose    :  This design contains an architecture for the testbench used in
--             :  task 2 of the Edge-Detection design project.
--             :
--             :
--  Revision   :  1.0    07-10-08    Initial version
--             :  1.1    08-10-09    Split data line to dataR and dataW
--             :                     Edgar <s081553@student.dtu.dk>
--             :
--  Special    :
--  thanks to  :  Niels Haandbaek -- c958307@student.dtu.dk
--             :  Michael Kristensen -- c973396@student.dtu.dk
--             :  Hans Holten-Lund -- hahl@imm.dtu.dk
-- -----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use WORK.types.all;

entity testbench is
end testbench;

architecture structure of testbench is
    component clock
        generic(
            period : time := 80 ns
        );
        port(
            stop : in  std_logic;
            clk  : out std_logic := '0'
        );
    end component;

    component memory2 is
        generic(
            load_file_name : string
        );
        port(
            clk        : in  std_logic;
            en         : in  std_logic;
            we         : in  std_logic;
            addr       : in  std_logic_vector(15 downto 0);
            dataW      : in  std_logic_vector(31 downto 0);
            dataR      : out std_logic_vector(31 downto 0);
            dump_image : in  std_logic
        );
    end component memory2;

    component acc
        port(
            clk    : in  bit_t;
            reset  : in  bit_t;
            addr   : out halfword_t;
            dataR  : in  word_t;
            dataW  : out word_t;
            bl_queueR : in word_t;
            bl_queueW : out word_t;
            pix_queueR : in byte_t;
            pix_queueW : out byte_t;
            bl_pop : out bit_t;
            bl_push : out bit_t;
            pix_pop : out bit_t;
            pix_push : out bit_t;
            en     : out bit_t;
            we     : out bit_t;
            start  : in  bit_t;
            finish : out bit_t
        );
    end component;

    component fifo_queue is
        generic(
            DATA_WIDTH : integer := 32;
            QUEUE_DEPTH : integer := 288
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            pop : in std_logic;
            push: in std_logic;
            din : in std_logic_vector(DATA_WIDTH-1 downto 0);
            dout: out std_logic_vector(DATA_WIDTH-1 downto 0);
            empty : out std_logic;
            full : out std_logic
        );
    end component;

    signal StopSimulation : bit_t := '0';
    signal clk            : bit_t;
    signal reset          : bit_t;

    signal addr   : halfword_t;
    signal dataR  : word_t;
    signal dataW  : word_t;
    signal en     : bit_t;
    signal we     : bit_t;
    signal start  : bit_t;
    signal finish : bit_t;

    signal queueR : word_t;
    signal queueW : word_t;
    signal pop    : bit_t;
    signal push   : bit_t;

    signal bl_queueR : word_t;
    signal bl_queueW : word_t;
    signal pix_queueR : byte_t;
    signal pix_queueW : byte_t;
    signal bl_pop, bl_push : bit_t;
    signal pix_pop, pix_push : bit_t;

begin
    -- reset is active-low
    reset <= '1', '0' after 180 ns;

    -- start logic
    start_logic : process is
    begin
        start <= '0';

        wait until reset = '0' and clk'event and clk = '1';
        start <= '1';

        -- wait before accelerator is complete before deasserting the start
        wait until clk'event and clk = '1' and finish = '1';
        start <= '0';

        wait until clk'event and clk = '1';
        report "Test finished successfully! Simulation Stopped!" severity NOTE;
        StopSimulation <= '1';
    end process;

    SysClk : clock
        port map(
            stop => StopSimulation,
            clk  => clk
        );

    Accelerator : acc
        port map(
            clk    => clk,
            reset  => reset,
            addr   => addr,
            dataR  => dataR,
            dataW  => dataW,
            bl_queueR => bl_queueR,
            bl_queueW => bl_queueW,
            pix_queueR => pix_queueR,
            pix_queueW => pix_queueW,
            bl_pop => bl_pop,
            bl_push => bl_push,
            pix_pop => pix_pop,
            pix_push => pix_push,
            en     => en,
            we     => we,
            start  => start,
            finish => finish
        );

    Queue_blocks : fifo_queue
        generic map(
            DATA_WIDTH => 32,
            QUEUE_DEPTH => 288
        )
        port map(
            clk => clk,
            reset => reset,
            pop => bl_pop,
            push => bl_push,
            din => bl_queueW,
            dout => bl_queueR,
            empty => open,
            full => open
        );

    Queue_pixels : fifo_queue
        generic map(
            DATA_WIDTH => 8,
            QUEUE_DEPTH => 288
        )
        port map(
            clk => clk,
            reset => reset,
            pop => pix_pop,
            push => pix_push,
            din => pix_queueW,
            dout => pix_queueR,
            empty => open,
            full => open
        );

    Memory : memory2
        generic map(
            load_file_name => "black.pgm"
        )
        -- Result is saved to: load_file_name & "_result.pgm"
        port map(
            clk        => clk,
            en         => en,
            we         => we,
            addr       => addr,
            dataW      => dataW,
            dataR      => dataR,
            dump_image => finish
        );

end structure;
