-------------------------------------------------------
--! @file ram.vhd
--! @brief RAM com escrita sincrona
--! @author Rafael de A. Innecco
--! @date 2021-12-01
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity ram is
    generic (
        addressSize : natural := 4;
        wordSize : natural := 8
    );
    port (
        ck, wr : in bit;
        addr : in bit_vector (addressSize - 1 downto 0);
        data_i : in bit_vector (wordSize - 1 downto 0);
        data_o : out bit_vector (wordSize - 1 downto 0)
    );
end ram;

architecture arch of ram is
    constant depth : natural := 2**addressSize;
    type mem_tipo is array (0 to depth - 1) of bit_vector (wordSize - 1 downto 0);
    signal mem : mem_tipo;
begin

    ESCR: process (ck) is -- Processo de escrita
    begin
        if ck = '1' and wr = '1' then
            mem(to_integer(unsigned(addr))) <= data_i;
        end if;
    end process ESCR;

    data_o <= mem(to_integer(unsigned(addr)));
end architecture arch;