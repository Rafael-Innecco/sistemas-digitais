-------------------------------------------------------
--! @file ULA.vhdl
--! @brief D_register
--! @author Rafael de A. Innecco
--! @date 2021-11-10
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity d_register is
    generic (
        width: natural := 4;
        reset_value: natural := 0
    );
    port (
        clock, reset, load: in bit;
        d: in bit_vector (width - 1 downto 0);
        q: out bit_vector (width - 1 downto 0)
    );
end entity d_register;

architecture t1 of d_register is
begin
    LD: process (clock, reset) is
    begin
        if reset = '1' then
            q <= bit_vector(to_unsigned(reset_value, width));
        elsif (clock = '1') and (load = '1') then
            q <= d;
        end if;
    end process LD;
end architecture t1;