-- -----------------------------------------------------------------------------
--
--  Title      :  Simple clock generator.
--             :
--  Developers :  Niels Haandb�k -- c958307@student.dtu.dk
--             :
--  Purpose    :  This design contains a clock generator.
--             :
--  Revision   :  1.0    27-8-99     Initial version
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- A simple clock generator. The period is specified in a generic and defaults
-- to 50 ns.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity clock is
    generic(
        period : time := 50 ns
    );
    port(
        stop : in  std_logic;
        clk  : out std_logic := '0'
    );
end clock;

architecture behaviour of clock is
begin
    process
    begin
        if (not stop = '1') then
            clk <= '1', '0' after period / 2;
            wait for period;
        else
            wait;
        end if;
    end process;
end behaviour;
