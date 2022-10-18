-------------------------------------------------------
--! @file rom_simples_pleg.vhd
--! @brief ROM simples feita durante a construção do PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-05-23
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity rom_simples is
    port (
        addr: in bit_vector (3 downto 0);
        data: out bit_vector (7 downto 0)
    );
end rom_simples;

architecture arch of rom_simples is
    type mem_tipo is array (0 to 15) of bit_vector (7 downto 0);

    signal mem: mem_tipo := (
        "00000000", 
        "00000011", 
        "11000000", 
        "00001100",
        "00110000", 
        "01010101", 
        "10101010", 
        "11111111",
        "11100000", 
        "11100111", 
        "00000111", 
        "00011000",
        "11000011", 
        "00111100", 
        "11110000", 
        "00001111"
    );

begin

    data <= mem(to_integer(unsigned(addr)));

end architecture arch;