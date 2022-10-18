-------------------------------------------------------
--! @file shift_left.vhd
--! @brief Realiza um shift de dois bits para a esquerda
--! @author Rafael de A. Innecco
--! @date 2022-05-25
-------------------------------------------------------

entity shiftleft2 is
    generic (
        ws : natural := 64); -- word size
    port (
        i : in bit_vector (ws - 1 downto 0); --input
        o : out bit_vector (ws - 1 downto 0) --output
    );
end shiftleft2;

architecture shifter of shiftleft2 is
begin
   o <= i(ws - 3 downto 0) & "00";
end architecture shifter;