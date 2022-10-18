-------------------------------------------------------
--! @file rom_arquivo_generica.vhd
--! @brief ROM arquivo generica
--! @author Rafael de A. Innecco
--! @date 2021-12-01
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity rom_arquivo_generica is
    generic (
        addressSize : natural := 4;
        wordSize : natural := 8;
        datFileName : string := "rom.dat"
    );
    port (
        addr: in bit_vector (addressSize - 1 downto 0);
        data: out bit_vector (wordSize  - 1 downto 0)
    );
end rom_arquivo_generica;

architecture arch of rom_arquivo_generica is
    constant depth : natural := 2**addressSize;
    type mem_tipo is array (0 to depth - 1) of bit_vector (wordSize - 1 downto 0);
    impure function inicializa(file_name : in string) return mem_tipo is

        file arq : text open read_mode is file_name;
        variable lin : line;
        variable temp_bitvec : bit_vector (wordSize - 1 downto 0);
        variable mem_temp : mem_tipo;
    
    begin
        for i in mem_tipo'range loop
            readline(arq, lin);
            read (lin, temp_bitvec);
            mem_temp(i) := temp_bitvec;
        end loop;
        return mem_temp;
    end;

    signal mem: mem_tipo := inicializa (datFileName);

begin

    data <= mem(to_integer(unsigned(addr)));

end architecture arch;