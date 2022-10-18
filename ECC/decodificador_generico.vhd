-------------------------------------------------------
--! @file decodificador_generico.vhd
--! @brief Decodificador de tamanho genérico para memória ecc
--! @author Rafael de A. Innecco
--! @date 2022-07-19
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

package minhas_funcoes is
    function secded_message_size (size: positive) return natural;
end minhas_funcoes;

package body minhas_funcoes is
    function secded_message_size (size: positive) return natural is
    begin
        return natural(floor(log2(real(size)))) + natural(size) + 2;
    end function;
end minhas_funcoes;


library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;
library work;
use work.minhas_funcoes.secded_message_size;

entity secded_dec is
    generic(
        data_size: positive := 16
    );
    port (
        mem_data: in bit_vector(secded_message_size(data_size)-1 downto 0);
        u_data: out bit_vector(data_size-1 downto 0);
        uncorrectable_error: out bit
    );
end entity;

architecture t3 of secded_dec is
    constant secded_size  : natural := secded_message_size(data_size);

    impure function parity_xor (data: bit_vector(secded_size - 1 downto 0); par: integer) return bit is
        variable intermediate : bit := '0';
        variable position_size : natural := natural(ceil(log2(real(secded_size))));
        variable iVector    : bit_vector(position_size - 1 downto 0);
    begin
        for i in 0 to secded_size - 1 loop
            iVector := bit_vector(to_unsigned(i + 1, position_size)) srl par;
            if iVector(0) = '1' and i /= secded_size - 1 then
                intermediate := intermediate xor data(i);
            end if;
        end loop;
        return intermediate;
    end;

    impure function extract_data (inData: bit_vector(secded_message_size(data_size) - 1 downto 0)) return bit_vector is
        variable outData    : bit_vector(data_size - 1 downto 0);
        variable check      : real;
        variable n          : natural := 0;
    begin
        for i in 0 to secded_size - 2 loop
            check := ceil(2**ceil(log2(real(i + 1))));
            if check /= real(i + 1) then
                outData(n) := inData(i);
                n := n + 1;
            end if;
        end loop;

        return outData;
    end function;

    constant par_size : natural := natural(ceil(log2(real(secded_size))));

    impure function ult_xor (data: bit_vector(secded_size - 2 downto 0)) return bit is
        variable int    : bit;
    begin
        for i in 0 to secded_size - 2 loop
            int := int xor data(i);
        end loop;
        return int;
    end function;

    impure function extract_parity (data: bit_vector(secded_size - 1 downto 0)) return bit_vector is
        variable int    : bit_vector(par_size - 1 downto 0);
    begin
        for i in 0 to par_size - 1 loop
            int(i) := data(2**i - 1);
        end loop;
        return int;
    end function;

    signal intermediate : bit_vector(secded_size - 1 downto 0);
    signal expected, rParity    : bit_vector(par_size downto 0);
    signal synd         : bit_vector(par_size - 1 downto 0);
    signal received_data: bit_vector(data_size - 1 downto 0);
    signal parity_error : bit;
begin
    received_data <= extract_data(mem_data);

    PGEN: for i in 0 to par_size - 1 generate
        expected(i) <= parity_xor(mem_data, i);
    end generate PGEN;

    expected(par_size) <= ult_xor(mem_data(secded_size - 2 downto 0));

    rParity(par_size - 1 downto 0) <= extract_parity(mem_data);

    rParity(par_size) <= mem_data(secded_size - 1);

    --synd <= rParity(par_size - 1 downto 0) xor expected(par_size - 1 downto 0);
    synd <= expected(par_size - 1 downto 0);

    CRR: for i in 0 to secded_size - 1 generate
        intermediate(i) <= not(mem_data(i)) when i = to_integer(unsigned(synd)) - 1 else mem_data(i);
    end generate CRR;

    u_data <= extract_data(intermediate);

    parity_error <= rParity(par_size) xor expected(par_size);
    uncorrectable_error <= '1' when (to_integer(unsigned(synd)) /= 0) and parity_error = '0' else '0';
end architecture t3;