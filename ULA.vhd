-------------------------------------------------------
--! @file ULA.vhdl
--! @brief Unidade Lógica e Aritmética
--! @author Rafael de A. Innecco
--! @date 2021-11-10
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity alu is
    generic (
        size : natural := 8
    );

    port (
        A, B : in bit_vector (size - 1 downto 0); --inputs
        F : out bit_vector (size - 1 downto 0);
        S : in bit_vector (2 downto 0);
        Z : out bit; --zero flag
        Ov : out bit; --overflow flag
        Co : out bit --carry out flag
    );
end entity alu;

architecture t1 of alu is

    signal I0, I1, I2, I3, I4, I5, I6, I7, SAI : bit_vector (size - 1 downto 0); --Sinais intermediários
    signal CA, CS : bit_vector (size downto 0); -- Sinais utilizados para realizar o carry na soma e na subtração
    signal NEG_B : bit_vector (size - 1 downto 0);  -- Sinal para representar o oposto de B

begin

    -- A numeração dos sinais 'I' segue a ordem da tabela apresentada no enunciado
    I0 <= A; -- Cópia direta de A
    I2 <= A and B; -- And bit a bit entre A e B
    I3 <= A or B; -- Or bit a bit entre A e B
    I5 <= not A; -- Not A bit a bit

    -- Operação de inversão da ordem dos bits de A:
    GEN_1: for j in 0 to (size - 1) generate
        I6(j) <= A(size - 1 - j);
    end generate GEN_1;

    I7 <= B; -- Cópia direta de B

    -- Implementação da soma por Carry-lookahead
    CA(0) <= '0'; --Carry-in = 0
    GEN_2: for j in 1 to (size) generate
        CA(j) <= (A(j - 1) and B(j - 1)) or ((A(j - 1) or B(j - 1)) and CA(j - 1)); --Carry da soma do j-ésimo bit
    end generate GEN_2;

    GEN_3: for j in 0 to (size - 1) generate
        I1(j) <= A(j) xor B(j) xor CA(j);
    end generate GEN_3;

    --Implementação da subtração

    CS(0) <= '1'; --Carry-in = 1 (subtração em complemento de 2 = A + (-B + 1))
    GEN_4  : for j in 1 to (size) generate
        CS(j) <= (A(j - 1) and not(B(j - 1))) or ((A(j - 1) or not(B(j - 1))) and CS(j - 1)); --Carry da soma do j-ésimo bit
    end generate GEN_4;

    GEN_5: for j in 0 to (size - 1) generate
        I4(j) <= A(j) xor not(B(j)) xor CS(j);
    end generate GEN_5;

    -- Seleção da saída de maneira análoga a um multiplexador (SAI será utilizado em uma comparação, por isso, F receberá SAI posteriormente)
    SAI <= I0 when S = "000" else
         I1 when S = "001" else
         I2 when S = "010" else
         I3 when S = "011" else
         I4 when S = "100" else
         I5 when S = "101" else
         I6 when S = "110" else
         I7 when S = "111" else
         A; -- Caso padrão, nunca será selecionado em situações normais
    --

    -- Implementação de flags

    -- Flag de overflow
    Ov <= (CA(size) xor CA(size - 1)) when S = "001" else
          (CS(size) xor CS(size - 1)) when S = "100" else
          '0';
    --

    -- Flag  de Carry-out
    Co <= CA(size) when S = "001" else
          CS(size) when S = "100" else
          '0';
    --

    Z <= '1' when SAI = bit_vector(to_unsigned(0, size)) else
         '0';
    --

    F <= SAI;

end architecture t1;