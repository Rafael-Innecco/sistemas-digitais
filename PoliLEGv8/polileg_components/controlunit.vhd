-------------------------------------------------------
--! @file controlunit.vhd
--! @brief Unidade de controle para o processador PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-06-20
-------------------------------------------------------

entity controlunit is
    port (
        --To Datapath
        reg2loc     : out bit;
        uncondBranch: out bit;
        branch      : out bit;
        memRead     : out bit;
        memToReg    : out bit;
        aluOp       : out bit_vector (1 downto 0);
        memWrite    : out bit;
        aluSrc      : out bit;
        regWrite    : out bit;
        --From Datapath
        opcode      : in bit_vector (10 downto 0)
    );
end entity;

architecture behavioral of controlunit is
    type instruction is (LDUR, STUR, CBZ, B, ADD, SUB, ANN, ORR); -- ANN substitui AND pois o último é ua palavra reservada

    signal inst : instruction;
begin
    inst <= B when opcode(10) = '0' else
            CBZ when opcode(5) = '1' else
            LDUR when (opcode(7) = '1' and opcode(1) = '1') else
            STUR when opcode(7) = '1' else
            ADD when (opcode(3) = '1' and opcode(9) = '0') else
            SUB when opcode(3) = '1' else
            ANN when opcode(8) = '0' else
            ORR;
    --

    reg2loc <=  opcode(7); -- Desativado somente para instruções lógicas

    uncondBranch <= '1' when inst = B else '0';

    branch <=   '1' when inst = CBZ else '0';

    memRead <=  '1' when inst = LDUR else '0';

    memToReg <= opcode(7); -- Desativado somente para instruções lógicas

    aluOp(0) <= '1' when inst = CBZ else '0';

    aluOp(1) <= not(opcode(7)); -- Ativado para instruções lógicas

    memWrite <= '1' when inst = STUR else '0';

    aluSrc <= '1' when opcode(10 downto 6) = "11111" else '0';

    regWrite <= '1' when (opcode(7) = '0' or inst = LDUR) else '0'; -- Instruções lógicas + LDUR

end architecture behavioral;