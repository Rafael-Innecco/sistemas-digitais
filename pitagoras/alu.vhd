-------------------------------------------------------
--! @file alu_pleg.vhd
--! @brief Unidade Lógica Aritmética para o PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-05-25
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity alu is
    generic (
        size : natural := 64
    );
    port (
        A, B : in  bit_vector (size - 1 downto 0); --inputs
        F : out bit_vector (size - 1 downto 0); -- output
        S : in bit_vector (3 downto 0); -- op selection
        Z : out bit; -- zero flag
        Ov : out bit; -- overflow flag
        Co : out bit -- carry out
    );
end entity alu;

architecture behavioral of alu is

    signal IAND, IORR, ISUM, ILSS, SAI : bit_vector (size - 1 downto 0); --Sinais intermediários
    signal A_int, B_int : bit_vector (size - 1 downto 0); -- Podem representar a versão comum ou invertida das entradas
    signal Carry : bit_vector (size downto 0); -- Sinais utilizados para realizar o carry na soma e na subtração

begin

    A_int <= not(A) when S (3) = '1' else
            A;
    -- 

    B_int <= not(B) when S(2) = '1' else
            B;
    --

    -- A numeração dos sinais 'I' segue a ordem da tabela apresentada no enunciado
    IAND <= A_int and B_int; -- And bit a bit entre A_int e B_int
    IORR <= A_int or B_int; -- Or bit a bit entre A_int e B_int

    -- Implementação da soma por Carry-lookahead
    Carry(0) <= S(2); -- S(2) = 0 => soma, S(2) = 1 => subtração
    GEN_2: for j in 1 to (size) generate
        Carry(j) <= (A_int(j - 1) and B_int(j - 1)) or ((A_int(j - 1) or B_int(j - 1)) and Carry(j - 1)); --Carry da soma do j-ésimo bit
    end generate GEN_2;

    GEN_3: for j in 0 to (size - 1) generate
        ISUM(j) <= A_int(j) xor B_int(j) xor Carry(j);
    end generate GEN_3;

    ILSS <= bit_vector(to_unsigned(1, size)) when not(ISUM(size - 1)) = (Carry(size) xor Carry(size - 1)) else
            bit_vector(to_unsigned(0, size));

    -- Seleção da saída de maneira análoga a um multiplexador (SAI será utilizado em uma comparação, por isso, F receberá SAI posteriormente)
    SAI <=  IAND when S (1 downto 0) = "00" else
            IORR when S (1 downto 0) = "01" else
            ISUM when S (1 downto 0) = "10" else
            ILSS when S (1 downto 0) = "11" else
            A; -- Caso padrão, nunca será selecionado em situações normais
    --

    -- Implementação de flags

    -- Flag de overflow
    Ov <= (Carry(size) xor Carry(size - 1));
    --

    -- Flag  de Carry-out
    Co <= Carry(size);
    --

    Z <= '1' when SAI = bit_vector(to_unsigned(0, size)) else
         '0';
    --

    F <= SAI;

end architecture behavioral;