-- -----------------------------------------------------------------------------
--
--  Title      :  FSMD implementation of GCD (ack signal handling corrected)
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
  port (
    clk   : in std_logic;              -- The clock signal.
    reset : in std_logic;              -- Reset the module.
    req   : in std_logic;              -- Input operand / start computation.
    AB    : in unsigned(15 downto 0);  -- The two operands.
    ack   : out std_logic;             -- Computation is complete.
    C     : out unsigned(15 downto 0)  -- The result.
  );
end gcd;

architecture fsmd of gcd is

  -- Define the state machine states
  type state_type is (idle, load_a, load_b, compare, subtract_a, subtract_b, done);

  signal reg_a, next_reg_a, next_reg_b, reg_b : unsigned(15 downto 0);
  signal state, next_state : state_type;

begin

  -- Combinatorial logic

  cl : process (req, AB, state, reg_a, reg_b, next_reg_a, next_reg_b, next_state, reset)
  begin
    -- Assignments to avoid latch inference
    next_state <= state;
    next_reg_b <= reg_b;
    next_reg_a <= reg_a;
    ack <= '0';  
    C <= reg_b;

    case (state) is
    
        when idle =>
          if req = '1' then
            next_state <= load_a;
          end if;
        
        when load_a =>
          next_reg_a <= AB;               
          ack <= '1';                     
          if req = '0' then               
            ack <= '0';                   
            next_state <= load_b;
          end if;
         
        when load_b =>
          if req = '1' then 
            next_reg_b <= AB;             
            next_state <= compare;
          end if;
        
        when compare =>
          if reg_a = 0 then
            next_reg_a <= reg_b;          
            next_state <= done;
          elsif reg_b = 0 then
            next_state <= done;           
          elsif reg_a = reg_b then
            next_state <= done;           
          elsif reg_a > reg_b then
            next_state <= subtract_a;      
          else
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
          if req = '0' then                
            ack <= '0';                    
            next_state <= idle;
          end if;
          
        when others =>
          next_state <= idle;

    end case;
  end process cl;

  -- Sequential process to update registers

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
