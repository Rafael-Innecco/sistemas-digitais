library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

entity datapath is
    port (
        --Common
        clock   : in bit;
        reset   : in bit;
        --From Control Unit
        reg2loc : in bit;
        pcsrc   : in bit;
        memToReg: in bit;
        aluCtrl : in bit_vector (3 downto 0);
        aluSrc  : in bit;
        regWrite: in bit;
        -- To Control Unit
        opcode  : out bit_vector (10 downto 0);
        zero    : out bit;
        -- Instruction Memory interface
        imAddr  : out bit_vector (63 downto 0);
        imOut   : in bit_vector (31 downto 0);
        -- Data Memory Interface
        dmAddr  : out bit_vector (63 downto 0);
        dmIn    : out bit_vector (63 downto 0);
        dmOut   : in bit_vector (63 downto 0)
    );
end entity datapath;

architecture data_flow of datapath is
    component alu is
        generic (
            size : natural
        );
        port (
            A, B: in bit_vector (size - 1 downto 0);
            F   : out bit_vector (size - 1 downto 0);
            S   : in bit_vector (3 downto 0);
            Z   : out bit;
            Ov  : out bit;
            Co  : out  bit
        );
    end component alu;

    component d_register is
        generic (
            width   : natural;
            reset_value : natural
        );
        port (
            clock, reset, load  : in bit;
            d   : in bit_vector (width - 1 downto 0);
            q   : out bit_vector (width - 1 downto 0)
        );
    end component d_register;

    component regfile is
        generic (
            reg_n   : natural;
            word_s  : natural
        );
        port (
            clock   : in bit;
            reset   : in bit;
            regWrite: in bit;
            rr1, rr2, wr    : in bit_vector (natural(ceil(log2(real(reg_n)))) - 1 downto 0);
            d       : in bit_vector (word_s - 1 downto 0);
            q1, q2  : out bit_vector (word_s - 1 downto 0)
        );
    end component regfile;

    component shiftleft2 is
        generic (
            ws  : natural
        );
        port (
            i   : in bit_vector (ws - 1 downto 0);
            o   : out bit_vector (ws - 1 downto 0)
        );
    end component shiftleft2;

    component signExtend is
        port (
            i   : in bit_vector (31 downto 0);
            o   : out bit_vector (63 downto 0)
        );
    end component signExtend;

    signal PC_in, PC_out    : bit_vector (63 downto 0);
    
    signal rr1, rr2, wr             : bit_vector (4 downto 0);
    signal reg_data, read1, read2   : bit_vector (63 downto 0);

    signal extended_signal  : bit_vector (63 downto 0);

    signal shifted_signal   : bit_vector (63 downto 0);

    signal alu_b , alu_out          : bit_vector (63 downto 0);
    
    signal incremented_pc   : bit_vector (63 downto 0);
    signal pcToBranch       : bit_vector (63 downto 0);
begin
    PC_reg : d_register
        generic map (64, 0)
        port map (clock, reset, '1', PC_in, PC_out);
    -- O load do PC é permanentemente 1 pois a arquitetura requer que ele seja atualizado todo ciclo de clock

    imAddr <= PC_out;

    rr1 <= imOut (9 downto 5);

    rr2 <= imOut (20 downto 16) when reg2loc = '0' else
            imOut (4 downto 0);
    --

    wr <= imOut (4 downto 0);

    reg_bank : regfile
        generic map (32, 64)
        port map (
            clock, reset, regWrite, 
            rr1, rr2, wr, 
            reg_data, read1, read2);
    --

    Sgn_ext : signExtend
        port map (imOut, extended_signal);
    --

    Sft : shiftleft2
        generic map (64)
        port map (extended_signal, shifted_signal);
    --

    alu_b <= extended_signal when aluSrc = '1' else
            read2;

    ULA : alu
        generic map (64)
        port map (
            read1, alu_b, alu_out, 
            aluCtrl, zero, open, open);
    -- 

    reg_data <= dmOut when memToReg = '1' else
                alu_out;
    --

    PC_adder : alu
        generic map (64)
        port map (
            PC_out, bit_vector(to_unsigned(4, 64)), incremented_pc,
            "0010", open, open, open
        );
    --

    Branch_adder : alu
        generic map (64)
        port map (
            PC_out, shifted_signal, pcToBranch,
            "0010", open, open, open
        );
    --

    PC_in <= pcToBranch when pcsrc = '1' else
            incremented_pc;
    --

    dmIn <= read2;

    dmAddr <= alu_out;
    
    opcode <= imOut (31 downto 21);
end architecture data_flow;

library ieee;
use ieee.numeric_bit.all;

entity d_register is
    generic (
        width: natural := 4;
        reset_value: natural := 0
    );
    port (
        clock, reset, load: in bit;
        d: in bit_vector (width - 1 downto 0);
        q: out bit_vector (width - 1 downto 0)
    );
end entity d_register;

architecture t1 of d_register is
begin
    LD: process (clock, reset) is
    begin
        if rising_edge(reset) then
            q <= bit_vector(to_unsigned(reset_value, width));
        elsif (clock = '1') and (load = '1') then
            q <= d;
        end if;
    end process LD;
end architecture t1;

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

    signal reg_bank : regfile_tipo;
    --signal check    : array (reg_n - 1 downto 0) of bit_vector (natural(ceil(log2(real(reg_n)))) - 1 downto 0);
begin
    GEN: for i in 0 to reg_n - 2 generate
        UPDATE: process (clock, reset) is
        begin
            --check(i) <= bit_vector(to_unsigned(i, natural(ceil(log2(real(reg_n))))));
            if rising_edge(reset) then
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

entity signExtend is
    port (
        i : in bit_vector (31 downto 0); --input
        o : out bit_vector (63 downto 0) --output
    );
end signExtend;

architecture sgnExt of signExtend is
    signal ID, IB, ICB: bit_vector (63 downto 0); -- Sinais intermediários para cada tipo de instrução
    signal medio : bit_vector (8 downto 0);
begin

    medio <= i(20 downto 12);

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