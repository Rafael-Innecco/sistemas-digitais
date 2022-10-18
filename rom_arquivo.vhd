-------------------------------------------------------
--! @file rom_arquivo.vhd
--! @brief ROM arquivo
--! @author Rafael de A. Innecco
--! @date 2021-12-01
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity rom_arquivo is
    port (
        addr: in bit_vector (3 downto 0);
        data: out bit_vector (7 downto 0)
    );
end rom_arquivo;

architecture arch of rom_arquivo is
    type mem_tipo is array (0 to 15) of bit_vector (7 downto 0);

    impure function inicializa(file_name : in string) return mem_tipo is

        file arq : text open read_mode is file_name;
        variable lin : line;
        variable temp_bitvec : bit_vector (7 downto 0);
        variable mem_temp : mem_tipo;
    
    begin
        for i in mem_tipo'range loop
            readline(arq, lin);
            read (lin, temp_bitvec);
            mem_temp(i) := temp_bitvec;
        end loop;
        return mem_temp;
    end;

    signal mem: mem_tipo := inicializa ("conteudo_rom_ativ_02_carga.dat");

begin

    data <= mem(to_integer(unsigned(addr)));

end architecture arch;