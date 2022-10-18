-------------------------------------------------------
--! @file rom_simples_pleg.vhd
--! @brief ROM simples carregada com um programa para cálculo de MDC
--! @author Rafael de A. Innecco
--! @date 2022-05-23
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity rom is
    port (
        addr: in bit_vector (7 downto 0);
        data: out bit_vector (31 downto 0)
    );
end rom;

architecture arch of rom is
    type mem_tipo is array (0 to 2**8 - 1) of bit_vector (31 downto 0);

    signal mem: mem_tipo;

    signal LDUR : bit_vector (10 downto 0)  := "11111000010";
    signal STUR : bit_vector (10 downto 0)  := "11111000000";
    signal SUB  : bit_vector (10 downto 0)  := "11001011000";
    signal ANN  : bit_vector (10 downto 0)  := "10001010000";
    signal B    : bit_vector (5 downto 0)   := "000101";
    signal CBZ  : bit_vector (7 downto 0)   := "10110100";

begin

    mem(0) <= LDUR & bit_vector(to_signed(0, 9)) & "00" & "11111" & "01111";
    mem(1) <= LDUR & bit_vector(to_signed(8, 9)) & "00" & "11111" & "01001";
    mem(2) <= LDUR & bit_vector(to_signed(16, 9)) & "00" & "11111" & "01010";

    mem(3) <= SUB & "01010" & "000000" & "01001" & "01011";
    mem(4) <= ANN & "01111" & "000000" & "01011" & "01011";
    mem(5) <= CBZ & bit_vector(to_signed(2, 19)) & "01011";
    mem(6) <= B & bit_vector(to_signed(4, 26));

    mem(7) <= SUB & "01010" & "000000" & "01001" & "01001";
    mem(8) <= CBZ & bit_vector(to_signed(5, 19)) & "01001";
    mem(9) <= B & bit_vector(to_signed(-6, 26));

    mem(10) <= SUB & "01001" & "000000" & "01010" & "01010";
    mem(11) <= CBZ & bit_vector(to_signed(3, 19)) & "01010";
    mem(12) <= B & bit_vector(to_signed(-9, 26));

    mem(13) <= STUR & "000000000" & "00" & "11111" & "01010";
    mem(14) <= B & bit_vector(to_signed(2, 26));

    mem(15) <= STUR & "000000000" & "00" & "11111" & "01001";
    mem(16) <= B & bit_vector(to_signed(0,26)); --Fim do programa, para nessa linha permanentemente

    FILL: for i in 17 to 2**8 - 1 generate
        mem(i) <= B & bit_vector(to_signed(0,26));
    end generate FILL;

    data <= mem(to_integer(unsigned(addr)));

end architecture arch;

-- Programa em Assembly:

-- LDUR X15, [XZR, #0] // Número mais negativo possível
-- LDUR X9, [XZR, #8] // Primeiro operando (A)
-- LDUR X10, [XZR. #16] // Segundo operando (B)

-- SUB X11, X9, X10
-- AND X11, X11, X15 // Caso esse resultado seja diferente de 0, A - B < 0, logo A < B
-- CBZ X11, #2
-- B #4

-- SUB X9, X9, X10
-- CBZ X9, #5 // MDC encontrado pelo método de euclides, se encontra no registrador B
-- B #-6

-- SUB X10, X10, X9
-- CBZ X10, #3
-- B #-9

-- STUR X10, [XZR, #0]
-- B #2 -- Usado para evitar que o resultao seja sobrescrito

-- STUR X9, [XZR, #0]