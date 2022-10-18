-------------------------------------------------------
--! @file rom_arquivo_pleg.vhd
--! @brief ROM inicializada por arquivo .dat
--! @author Rafael de A. Innecco
--! @date 2022-05-23
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity rom is
    generic (
        addr_s : natural := 64; --Size in bits
        word_s : natural := 32; --Width in bits
        init_f : string := "rom.dat" -- File name
    );
    port (
        addr : in bit_vector (addr_s - 1 downto 0);
        data  :out bit_vector (word_s - 1 downto 0)
    );
end rom;


architecture arch_rom of rom is
    type mem_tipo is array (0 to (2**addr_s - 1)) of bit_vector (word_s - 1 downto 0);

    impure function inicializa_mem(file_name : in string) return mem_tipo is
        file arquivo : text open read_mode is file_name;
        variable linha : line;
        variable temp_bitvec : bit_vector (word_s - 1 downto 0);
        variable mem_temp : mem_tipo;
    begin
        for i in mem_tipo'range loop
            readline(arquivo, linha); -- reads the line from the file to 'linha';
            read(linha, temp_bitvec); -- reads from 'linha' to temp_bitvec
            mem_temp(i) := temp_bitvec; -- finally, saves the bit vector in the temporary memory
        end loop;
        return mem_temp;
    end;

    signal mem : mem_tipo := inicializa_mem (init_f);
begin
    data <= mem(to_integer(unsigned(addr)));
end architecture arch_rom;