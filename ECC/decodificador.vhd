-------------------------------------------------------
--! @file decodificador.vhd
--! @brief Decodificador para memória ecc
--! @author Rafael de A. Innecco
--! @date 2022-07-12
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

entity secded_dec16 is
    port (
    mem_data: in bit_vector(21 downto 0);
    u_data: out bit_vector(15 downto 0);
    syndrome: out natural;
    two_errors: out bit;
    one_error: out bit
    );
end entity;

architecture t2 of secded_dec16 is

    component parity_generator is
        port (
            inData  : in bit_vector (15 downto 0);
            parity  : out bit_vector (5 downto 0)
        );
    end component parity_generator;
    
    component parser is
        port (
            i   : in bit_vector(21 downto 0);
            o   : out bit_vector (15 downto 0)
        );
    end component parser;

    signal intermediate : bit_vector(21 downto 0);
    signal expected : bit_vector (5 downto 0);
    signal synd : bit_vector (4 downto 0);
    signal received_data    : bit_vector (15 downto 0);
    signal parity_error : bit;
    signal received_parity  : bit_vector (5 downto 0);
begin
    RData : parser port map(mem_data, received_data);

    expected(0) <= received_data(15) xor received_data(13) xor received_data(11) xor received_data(10) xor received_data(8) xor received_data(6) xor received_data(4) xor received_data(3) xor received_data(1) xor received_data(0);
    expected(1) <= received_data(13) xor received_data(12) xor received_data(10) xor received_data(9) xor received_data(6) xor received_data(5) xor received_data(3) xor received_data(2) xor received_data(0);
    expected(2) <= received_data(15) xor received_data(14) xor received_data(10) xor received_data(9) xor received_data(8) xor received_data(7) xor received_data(3) xor received_data(2) xor received_data(1);
    expected(3) <= received_data(10) xor received_data(9) xor received_data(8) xor received_data(7) xor received_data(6) xor received_data(5) xor received_data(4);
    expected(4) <= received_data(15) xor received_data(14) xor received_data(13) xor received_data(12) xor received_data(11);

    expected(5) <= mem_data(20) xor mem_data(19) xor mem_data(18) xor mem_data(17) xor mem_data(16) xor mem_data(15) xor mem_data(14) xor mem_data(13) xor mem_data(12) xor mem_data(11) xor mem_data(10) xor mem_data(9) xor mem_data(8) xor mem_data(7) xor mem_data(6) xor mem_data(5) xor mem_data(4) xor mem_data(3) xor mem_data(2) xor mem_data(1) xor mem_data(0);

    received_parity <= mem_data(21) & mem_data(15) & mem_data(7) & mem_data(3) & mem_data(1) & mem_data(0);

    synd <= received_parity(4 downto 0) xor expected(4 downto 0);

    syndrome <= to_integer(unsigned(synd));

    CRR: for i in 0 to 21 generate
        intermediate(i) <= not(mem_data(i)) when i = (to_integer(unsigned(synd)) - 1) else mem_data(i);
    end generate CRR;

    parity_error <= received_parity(5) xor expected(5);

    CData: parser port map (intermediate, u_data);

    one_error <= '1' when parity_error = '1' else '0';
    two_errors <= '1' when (to_integer(unsigned(synd)) /= 0) and parity_error = '0' else '0';
end architecture t2;

entity parity_generator is
    port (
        inData  : in bit_vector (15 downto 0);
        parity  : out bit_vector (4 downto 0)
    );
end entity;

architecture pgen of parity_generator is
begin
    parity(0) <= inData(15) xor inData(13) xor inData(11) xor inData(10) xor inData(8) xor inData(6) xor inData(4) xor inData(3) xor inData(1) xor inData(0);
    parity(1) <= inData(13) xor inData(12) xor inData(10) xor inData(9) xor inData(6) xor inData(5) xor inData(3) xor inData(2) xor inData(0);
    parity(2) <= inData(15) xor inData(14) xor inData(10) xor inData(9) xor inData(8) xor inData(7) xor inData(3) xor inData(2) xor inData(1);
    parity(3) <= inData(10) xor inData(9) xor inData(8) xor inData(7) xor inData(6) xor inData(5) xor inData(4);
    parity(4) <= inData(15) xor inData(14) xor inData(13) xor inData(12) xor inData(11);
end architecture pgen;

entity parser is
    port (
        i   : in bit_vector(21 downto 0);
        o   : out bit_vector(15 downto 0)
    );
end entity parser;

architecture dataflow of parser is
begin
    o(15 downto 11) <= i(20 downto 16);
    o(10 downto 4) <= i(14 downto 8);
    o(3 downto 1) <= i(6 downto 4);
    o(0) <= i(2);
end architecture dataflow; 