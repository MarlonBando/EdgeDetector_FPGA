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
            en     : out bit_t;
            we     : out bit_t;
            start  : in  bit_t;
            finish : out bit_t;
            push1  : out std_logic;
            pop1   : out std_logic;
            push2  : out std_logic;
            pop2   : out std_logic;
            queue1_R : in std_logic_vector(31 downto 0);
            queue1_W : out std_logic_vector(31 downto 0);
            queue2_R : in std_logic_vector(31 downto 0);
            queue2_W : out std_logic_vector(31 downto 0)
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

    signal queue1_din  : std_logic_vector(31 downto 0);
    signal queue1_dout : std_logic_vector(31 downto 0);
    signal queue1_empty : std_logic;
    signal queue1_full : std_logic;
    signal queue1_push : std_logic;
    signal queue1_pop  : std_logic;

    signal queue2_din  : std_logic_vector(31 downto 0);
    signal queue2_dout : std_logic_vector(31 downto 0);
    signal queue2_empty : std_logic;
    signal queue2_full : std_logic;
    signal queue2_push : std_logic;
    signal queue2_pop  : std_logic;

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
            clk      => clk,
            reset    => reset,
            addr     => addr,
            dataR    => dataR,
            dataW    => dataW,
            en       => en,
            we       => we,
            start    => start,
            finish   => finish,
            push1    => queue1_push,
            pop1     => queue1_pop,
            push2    => queue2_push,
            pop2     => queue2_pop,
            queue1_R => queue1_dout,
            queue1_W => queue1_din,
            queue2_R => queue2_dout,
            queue2_W => queue2_din
        );

    Memory : memory2
        generic map(
            load_file_name => "pic1.pgm"
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

    fifo_queue_inst_1 : fifo_queue
        generic map(
            DATA_WIDTH => 32,
            QUEUE_DEPTH => 352
        )
        port map(
            clk   => clk,
            reset => reset,
            pop   => queue1_pop,
            push  => queue1_push,
            din   => queue1_din,
            dout  => queue1_dout,
            empty => queue1_empty,
            full  => queue1_full
        );

    fifo_queue_inst_2 : fifo_queue
        generic map(
            DATA_WIDTH => 32,
            QUEUE_DEPTH => 352
        )
        port map(
            clk   => clk,
            reset => reset,
            pop   => queue2_pop,
            push  => queue2_push,
            din   => queue2_din,
            dout  => queue2_dout,
            empty => queue2_empty,
            full  => queue2_full
        );

end structure;
