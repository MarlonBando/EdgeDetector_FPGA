-- -----------------------------------------------------------------------------
--
--  Title      :  FSMD implementation of GCD
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--           :
--  Purpose    :  This is a FSMD (finite state machine with datapath) 
--             :  implementation the GCD circuit
--             :
--  Revision   :  02203 fall 2019 v.5.0
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
  port (clk : in std_logic;             -- The clock signal.
    reset : in  std_logic;              -- Reset the module.
    req   : in  std_logic;              -- Input operand / start computation.
    AB    : in  unsigned(15 downto 0);  -- The two operands.
    ack   : out std_logic;              -- Computation is complete.
    C     : out unsigned(15 downto 0)); -- The result.
end gcd;

architecture fsmd of gcd is

  type state_type is (idle, load_a, release_btn, load_b, compare, zero_a, subtract_a, subtract_b, done); -- Input your own state names

  signal reg_a, next_reg_a, next_reg_b, reg_b : unsigned(15 downto 0);

  signal state, next_state : state_type;


begin

  -- Combinatoriel logic

  cl : process (req,ab,state,reg_a,reg_b,reset)
  begin
    -- The assignments before
    next_state <= state;
    next_reg_a <= reg_a;
    next_reg_b <= reg_b;
    ack <= '0';               
    C <= reg_a;
    
    case (state) is
        
        when idle =>
          if req = '1' then
            next_state <= load_a;
          end if;
        
        when load_a =>
           if req = '1' then
            next_reg_a <= ab;
            ack <= '1';
           else
            next_state <= release_btn;
           end if;
           
         when release_btn =>
           if req = '0' then
             ack <= '0';
             next_state <= load_b;
           end if;
        
        when load_b =>
          if req = '1' then
            next_reg_b <= ab;
            next_state <= compare;
          end if;
                    
        when compare =>
          -- Corner cases
          -- gcd(a, 0) = gcd(0, a) = |a|
          -- gcd(0, 0) = 0
          if reg_a = reg_b then
            next_state <= done;
          elsif reg_a = 0 then
            next_reg_a <= reg_b;
            next_state <= done;
          elsif reg_b = 0 then
            next_state <= done;
          elsif reg_a > reg_b then
            next_state <= subtract_a;
          elsif reg_a < reg_b then
            next_state <= subtract_b;
          end if;
        
        when subtract_a =>
          next_reg_a <= reg_a - reg_b;
          next_state <= compare;
        
        when subtract_b =>
          next_reg_b <= reg_b - reg_a;
          next_state <= compare;
          
        when done =>
          ack <= '1';
          C <= reg_a;
          next_state <= idle;
        
        when others =>
          next_state <= idle;

    end case;
  end process cl;

  -- Registers

  seq : process (clk, reset)
  begin

    if reset = '1' then
      state <= idle;
      reg_a <= (others => '0');
      reg_b <= (others => '0');
    elsif rising_edge(clk) then
      state <= next_state;
      reg_a <= next_reg_a;
      reg_b <= next_reg_b;
    end if;

  end process seq;


end fsmd;
