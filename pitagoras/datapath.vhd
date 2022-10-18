-------------------------------------------------------
--! @file data_flow.vhd
--! @brief Fluxo de dados para cálculo de sqrt(a^2 + b^2) por aproximação
--! @author Rafael de A. Innecco
--! @date 2022-06-30
-------------------------------------------------------


entity datapath is
    generic (
        word_s  : natural := 8;
    );
    port (
        --Geral
        clock               : in bit;
        input_a, input_b    : in bit_vector (word_s - 1 downto 0); -- Entradas
        result              : out bit_vector (word_s - 1 downto 0); -- Resultado
        -- Interface com a unidade de controle
        reset               : in bit;
        a_src, a_en         : in bit; --Seletor e enable para o registrador a
        b_src, b_en         : in bit; -- Seletor e enable para o registrador b
        alub_src            : in bit_vector (1 downto 0); -- Seletores para a entrada da ULA
        alua_src            : in bit_vector (2 downto 0);
        alu_sel             : in bit_vector (3 downto 0); -- Seleciona a operação da ULA
        shift_src           : in bit; --Seletor para a entrada do operador 'shift'
        xy_en               : in bit; -- Seletor para a entrada do registrador x e enable para x e y
        sx_src, bx_en, sx_en: in  bit;
        o_en                : in bit; -- Seletor e enalble para a saída
        zero                : out bit
    );
end datapath;

architecture structural of datapath is
    component mux_2 is
        generic (
            word_s  : natural := 8
        );
        port (
            i0, i1  : in bit_vector(word_s - 1 downto 0);
            o       : out bit_vector(word_s - 1 downto 0);
            sel     : in bit
        );
    end component mux_2;

    component mux_4 is
        generic (
            word_s  : natural := 8
        );
        port (
            i0, i1, i2, i3  : in bit_vector(word_s - 1 downto 0);
            o               : out bit_vector(word_s - 1 downto 0);
            sel             : in bit_vector (2 downto 0);
        );
    end component mux_4;

    component alu is
        generic (
            size    : natural := 64;
        );
        port (
            A, B    : in bit_vector (size - 1 downto 0);
            F       : out bit_vector (size - 1 downto 0);
            S       : in bit_vector (3 downto 0);
            Z       : out bit;
            Ov      : out bit;
            Co      : out bit
        );
    end component alu;

    component d_register is
        generic (
            width   : natural := 4;
            reset_value : natural := 0;
        );
        port (
            clock, reset, load  : in bit;
            d   : in bit_vector (width - 1 downto 0);
            q   : out bit_vector (width - 1 downto 0)
        );
    end component d_register;

    signal alu_a, alu_b, alu_out        : bit_vector(word_s - 1 downto 0);
    signal a_in, b_in, x_in, sx_in      : bit_vector(word_s - 1 downto 0);
    signal a_out, b_out, x_out          : bit_vector(word_s - 1 downto 0);
    signal y_out, , bx_out, sx_out      : bit_vector(word_s - 1 downto 0);
    signal shft_in, shft_out, o_in      : bit_vector(word_s - 1 downto 0);
    signal int_alua, int_alub, int_shft : bit_vector(word_2 - 1 downto 0);
    signal aluzr                        : bit; 
begin
    A: d_register
        generic map (word_s, 0)
        port map (
            clock, reset, a_en, a_in, a_out
        );
    --
    B: d_register
        generic map (word_s, 0)
        port map (
            clock, reset, b_en, b_in, b_out
        );
    --
    X: d_register
        generic map (word_s, 0)
        port map (clock, reset, xy_en, x_in, x_out);
    --
    Y: d_regster
        generic map (word_s, 0)
        port map (clock, reset, xy_en, shft_out, y_out);
    --
    xbuffer: d_register
        generic map (word_s, 0)
        port map (clock, reset, bx_en, alu_out, bx_out);
    --
    xshift: d_register
        generic map (word_s, 0)
        port map (clock, reset, sx_en, sx_in, sx_out);
    --
    Outpt: d_register
        generic map (word_s, 0)
        port map (clock, reset, o_en, o_in, result);
    --

    AMUX: mux_2
        generic map (word_s)
        port map (input_a, alu_out, a_in, a_src);
    --
    BMUX: mux_2
        generic map (word_s)
        port map (input_b, alu_out, b_in, b_src);
    --

    ALUAINT: mux_4
        generic map (word_s)
        port map (
            a, bit_vector(to_unsigned(0, word_s)), 
            shft_out, y_out, int_alua, alua_src(1 downto 0)
        );
    ALUAMUX: mux_2
        generic map (word_s)
        port map (
            int_alua, x_out, alu_a, alua_src(2)
        );
    --

    ALUBINT: mux_2
        generic map (word_s)
        port map (
            a, b, int_alub, alub_src(0)
        );
    ALUBMUX: mux_2
        generic map (word_s)
        port map (
            int_alub, bx_out, alu_b, alub_src(1)
        );
    --

    XMUX: mux_2
        generic map (word_s)
        port map (
            a_out, b_out, x_in, not(alu_zr)
        );
    --

    OUTMUX: mux_2
        generic map  (word_s)
        port map (
            x_out, bx_out, o_in, not(alu_zr)
        );
    --

    SHFTMUX1: mux_2
        generic map (word_s)
        port map (
            a_out, b_out, int_shft, alu_zr
        );
    SHFTMUX2: mux_2
        generic map (word_s)
        port map (
            int_shft, sx_out, shft_in, shft_src
        );
    --

    SXMUX: mux_2
        generic map (word_s)
        port map (
            x_in, shft_out, sx_in, sx_src
        );
    --

    ALU: alu
        generic map (word_s)
        port map (
            alu_a, alu_b, alu_out,
            alu_sel, alu_zr, open, open
        );
    --

    shft_out <= shft_in srl 1;
    zero <= alu_zr;

end architecture structural;