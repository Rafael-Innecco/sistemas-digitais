-------------------------------------------------------
--! @file banco_reg.vhd
--! @brief Banco de registradores para o PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-05-26
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

entity regfile is
    generic (
        reg_n   : natural := 10;
        word_s  : natural := 64
    );
    port (
        clock           : in bit;
        reset           : in bit;
        regWrite        : in bit;
        rr1, rr2, wr    : in bit_vector (natural(ceil(log2(real(reg_n)))) - 1 downto 0);
        d               : in bit_vector (word_s - 1 downto 0);
        q1, q2          : out bit_vector (word_s - 1 downto 0)
    );
end regfile;

architecture behavioral of regfile is
    -- O banco de registradores será modelado como uma matriz, sendo cada linha correspondente a um registrador.
    -- Essa modelagem se assemelha à de uma memória ram, no entanto existem algumas diferenças imprtantes

    type regfile_tipo is array (0 to reg_n - 1) of bit_vector (word_s - 1 downto 0);

    impure function reseta_banco (check: bit) return regfile_tipo is
        variable regf_temp : regfile_tipo;
    begin
        for i in regfile_tipo'range loop
            regf_temp(i) := bit_vector(to_unsigned(0, word_s));
        end loop;
        return regf_temp;
    end;

    signal reg_bank : regfile_tipo;
    --signal check    : array (reg_n - 1 downto 0) of bit_vector (natural(ceil(log2(real(reg_n)))) - 1 downto 0);
begin
    GEN: for i in 0 to reg_n - 2 generate
        UPDATE: process (clock, reset) is
        begin
            --check(i) <= bit_vector(to_unsigned(i, natural(ceil(log2(real(reg_n))))));
            if (reset = '1') then
                reg_bank(i) <= bit_vector(to_unsigned(0, word_s));
            elsif ((clock = '1') and (regWrite = '1') and (wr = bit_vector(to_unsigned(i, natural(ceil(log2(real(reg_n)))))))) then
                reg_bank (i) <= d;
            end if;
        end process UPDATE;
    end generate GEN;

    reg_bank (reg_n - 1) <= bit_vector(to_unsigned(0, word_s));

    q1 <= reg_bank(to_integer(unsigned(rr1)));
    q2 <= reg_bank(to_integer(unsigned(rr2)));
end architecture behavioral;