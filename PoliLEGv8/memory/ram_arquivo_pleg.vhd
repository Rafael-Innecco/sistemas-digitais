-------------------------------------------------------
--! @file ram_arquivo_pleg.vhd
--! @brief RAM com escrita sincrona inicializada a partir de arquvo .dat
--! @author Rafael de A. Innecco
--! @date 2022-05-25
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity ram is
    generic (
        addr_s : natural := 64; -- Size in bits
        word_s : natural := 32; -- Width in bits
        init_f : string := "ram.dat"
    );
    port (
        ck : in bit;
        rd, wr : in bit; --enables (read and write)
        addr : in bit_vector (addr_s - 1 downto 0);
        data_i : in bit_vector (word_s - 1 downto 0);
        data_o : out bit_vector (word_s - 1 downto 0)
    );
end ram;

architecture arch_ram of ram is
    type mem_tipo is array (0 to (2**addr_s - 1)) of bit_vector (word_s - 1 downto 0);

    impure function inicializa_mem (file_name: in string) return mem_tipo is
        file arquivo : text open read_mode is file_name;
        variable linha : line;
        variable temp_bitvec : bit_vector (word_s -1 downto 0);
        variable mem_temp : mem_tipo;
    begin
        for i in mem_tipo'range loop
            readline(arquivo, linha);
            read(linha, temp_bitvec);
            mem_temp(i) := temp_bitvec;
        end loop;
        return mem_temp;
    end;

    signal mem : mem_tipo := inicializa_mem(init_f);
begin
    data_o <= mem(to_integer(unsigned(addr))) when rd = '1';

    WRT: process (ck) is
    begin
        if (ck) = '1' and wr = '1' then
            mem(to_integer(unsigned(addr))) <= data_i;
        end if;
    end process WRT;
end architecture arch_ram;