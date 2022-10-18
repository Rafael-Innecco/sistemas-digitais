-------------------------------------------------------
--! @file signExtend.vhd
--! @brief Entidade que extende o sinal de um imediato contido na instrução recebida
--! @author Rafael de A. Innecco
--! @date 2022-05-25
-------------------------------------------------------

entity signExtend is
    port (
        i : in bit_vector (31 downto 0); --input
        o : out bit_vector (63 downto 0) --output
    );
end signExtend;

architecture sgnExt of signExtend is
    signal ID, IB, ICB: bit_vector (63 downto 0); -- Sinais intermediários para cada tipo de instrução
begin

    ID(8 downto 0) <= i(20 downto 12);

    IB(25 downto 0) <= i(25 downto 0);

    ICB(18 downto 0) <= i(23 downto 5);

    EXTD: for j in 9 to 63 generate
        ID (j) <= i(20);
    end generate EXTD;

    EXTB: for j in 26 to 63 generate
        IB (j) <= i(25);
    end generate EXTB;

    EXTCB: for j in 19 to 63 generate
        ICB (j) <= i(23);
    end generate EXTCB;

    o <= IB when i(31) = '0' else -- Instruções tipo B são as únicas implementadas com esse bit = '0'
         ICB when i(26) = '1' else -- Instruções do tipo B e Cb possuem esse bit, mas as do tipo B já terão seido "eliminadas"
         ID; -- O shift para instruções do tipo D é o caso padrão
end architecture sgnExt;