library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_queue is
    generic(
        DATA_WIDTH : integer := 32;
        QUEUE_DEPTH : integer := 352
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
end entity fifo_queue;  -- Changed from queue to fifo_queue

architecture behavioural of fifo_queue is
    type queue_type is array(0 to QUEUE_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal queue : queue_type := (others => (others => '0'));
    signal head_ptr : integer range 0 to QUEUE_DEPTH-1 := 0;
    signal tail_ptr : integer range 0 to QUEUE_DEPTH-1 := 0;
    signal length : integer range 0 to QUEUE_DEPTH := 0;
    signal internal_empty : std_logic;
    signal internal_full : std_logic;

begin
    internal_empty <= '1' when length = 0 else '0';
    internal_full  <= '1' when length = QUEUE_DEPTH else '0';
    empty <= internal_empty;
    full <= internal_full;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                length <= 0;
                head_ptr <= 0;
                tail_ptr <= 0;
                queue <= (others => (others => '0'));
                dout <= (others => '0');
            else
                if push = '1' and internal_full = '0' and pop = '1' and internal_empty = '0' then
                    -- Simultaneous push and pop
                    length <= length;  -- Length stays the same
                    queue(tail_ptr) <= din;
                    tail_ptr <= (tail_ptr + 1) mod QUEUE_DEPTH;
                    head_ptr <= (head_ptr + 1) mod QUEUE_DEPTH;
                elsif push = '1' and internal_full = '0' then
                    -- Push only
                    length <= length + 1;
                    queue(tail_ptr) <= din;
                    tail_ptr <= (tail_ptr + 1) mod QUEUE_DEPTH;
                    -- If this is first element, make it visible immediately
                    if length = 0 then
                        dout <= din;
                    end if;
                elsif pop = '1' and internal_empty = '0' then
                    -- Pop only
                    length <= length - 1;
                    head_ptr <= (head_ptr + 1) mod QUEUE_DEPTH;
                end if;

                if internal_empty = '0' then
                    dout <= queue(head_ptr);
                else
                    dout <= (others => '0');
                end if;
            end if;
        end if;
    end process;        
end behavioural;