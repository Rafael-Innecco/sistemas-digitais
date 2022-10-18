-------------------------------------------------------
--! @file control_unit.vhd
--! @brief Unidade de controle para cálculo de sqrt(a^2 + b^2) por aproximação
--! @author Rafael de A. Innecco
--! @date 2022-06-30
-------------------------------------------------------

entity contorlunit is
    port (
        -- Geral
        clock, start    : in bit;
        done            : out bit;
        --Interface com o fluxo de dados
        reset           : out bit;
        a_src, a_en     : out bit;
        b_src, b_en     : out bit;
        alub_src        : out bit_vector (1 downto 0);
        alua_src        : out bit_vector (2 downto 0);
        alu_sel         : out bit_vector (3 downto 0);
        shift_src, xy_en: out bit;
        sx_src, sx_en   : out bit;
        o_en, bx_en     : out bit;
        zero            : in bit
    );
end entity contorlunit;

architecture fsm of controlunit is
    type state is (
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12
    );

    signal present, future  : state;
begin
    UPDT: process (clock) is
    begin
        if clock = '1' then
            present <= future
        end if;
    end process UPDT;

    FSM: process is
    begin
        case present is
            when S0 =>
                a_en <= '0';
                b_en <= '0';
                xy_en <= '0';
                sx_en <= '0';
                bx_en <= '0';
                sx_en <= '0';
                o_en <= '0';
                wait on clock; -- Amostra na borda de descida do clock
                if start = '1' then
                    future <= S1;
                    reset <= '1';
                else
                    future <= S0;
                end if;
                wait on present;
            when S1 =>
                reset <= '0';
                done <= '0';
                a_en <= '1';
                a_src <= '0';
                b_en <= '1';
                b_src <= '0';
                future <= S2;
            when S2 =>
                a_en <= '0';
                b_en <= '0';
                alua_src <= "001";
                alub_src <= "00";
                alu_sel <= "0111";
                wait on clock;
                if zero = '1' then
                    future <= S3;
                else
                    future <= S4;
                end if;
                wait on present;
            when S3 =>
                alu_sel <= "0110"
                a_en <= '1';
                a_src <= '1';
                future <= S4;
            when S4 =>
                a_en <= '0';
                alub_src <= "01";
                alu_sel <= "0111";
                wait until clock = '0';
                if zero = '1' then
                    future <= S5;
                else
                    future <= S6;
                end if;
                wait on present;
            when S5 =>
                alu_sel <= "0110";
                b_en <= '1';
                b_src <= '1';
                future <= S6;
            when S6 =>
                b_en <= '0';
                alua_src <= "000";
                alub_src <= "01";
                alu_sel <= "0111";
                xy_en <= '1';
                sx_en <= '1';
                sx_src <= '0';
                shift_src <= '0';
                future <= S7;
            when S7 =>
                xy_en <= '0';
                alua_src <= "010";
                alub_src <= "10";
                alu_sel <= "0010"
                sx_en <= '1';
                sx_src <= '1';
                bx_en <= '1';
                shft_src <= '1';
                future <= S8;
            when S8 =>
                future <= S9;
            when S9 =>
                future <= S10;
            when S10 =>
                alua_src <= "011";
                sx_en <= '0';
                bx_en < ='1';
                future <= S11;
            when S11 =>
                alu_a <= "100";
                alu_b <= "10";
                alu_sel <= "0111";
                o_en <= '1';
                future <= S12;
            when S12 =>
                done <= '1';
                o_en <= '0';
                future <= S0;
        end case;
    end process FSM; 
end architecture fsm;