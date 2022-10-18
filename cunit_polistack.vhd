-------------------------------------------------------
--! @file cunit_polistack.vhd
--! @brief Unidade de controle do Polistack
--! @author Rafael de A. Innecco
--! @date 2021-12-01
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity control_unit is
    port (
        clock, reset : in bit;
        pc_en, ir_en, sp_en,
        pc_src, mem_a_addr_src, mem_b_mem_src, alu_shfimm_src, alu_mem_src,
        mem_we, mem_enable : out bit;
        mem_b_addr_src, mem_b_wrd_src, alu_a_src, alu_b_src : out bit_vector (1 downto 0);
        alu_op : out bit_vector (2 downto 0);
        mem_busy : in bit;
        instruction : in bit_vector (7 downto 0);
        halted : out bit
    );
end entity;

architecture C_unit of control_unit is
    type state_type is (F, D, W, BREAK, PUSHSP, POPPC, ADD, EXAND, EXOR, LOAD, EXNOT,
                         FLIP, NOP, STORE, STORE2, POPSP, ADDSP, CALL, CALL2, STORESP, LOADSP, IM1, IMM); --Estados da máquina de estados (cada instrução possui um estado próprio)
    signal present_state, next_state : state_type;
    signal IM_ult, exec : bit; --Indica se a última instrução executada foi IM1 ou IM* / Indica se o se está alguma instrução está sendo executada (evita que o estado mude e interrompa a execução)
    signal drct_call, drct_store : bit;
begin
    seq: process (clock) is
    begin
        if (rising_edge(clock)) and (exec = '0') then
            present_state <= next_state;
        end if;
    end process seq;

    com: process is
    begin
        case present_state is
            when F =>
                -- Estado de 'fetch'
                exec <= '1';   
                pc_en <= '0';
                sp_en <= '0';
                ir_en <= '0';

                --O próximo bloco faz a leitura de mem[PC] a partir da porta A
                mem_a_addr_src <= '1';
                mem_enable <= '1'; 
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                --Configura a ULA para PC + 1
                alu_shfimm_src <= '0';
                alu_a_src <= "00";
                alu_b_src <= "00";
                alu_op <= "001";

                pc_src <= '0';
                pc_en <= '1';
                ir_en <= '1';
                wait until rising_edge(clock);
                pc_en <= '0';
                ir_en <= '0';

                exec <= '0';
                next_state <= D;
                wait until rising_edge(clock);
            when D => -- Decodificação de instruções
                exec <= '1';
                if (instruction(7) = '1') then
                    if (IM_ult = '1') then
                        next_state <= IMM;
                    else
                        IM_ult <= '1';
                        next_state <= IM1;
                    end if;
                elsif (instruction (6) = '1') then
                    if (instruction (5) = '1') then
                        IM_ult <= '0';
                        next_state <= LOADSP;
                    else
                        IM_ult <= '0';
                        next_state <= STORESP;
                    end if;
                elsif (instruction (5) = '1') then
                    IM_ult <= '0';
                    next_state <= CALL;
                elsif (instruction (4) = '1') then
                    IM_ult <= '0';
                    next_state <= ADDSP;
                elsif (instruction = "00000000") then 
                    IM_ult <= '0';
                    next_state <= BREAK;
                elsif (instruction = "00000010") then
                    IM_ult <= '0';
                    next_state <= PUSHSP;
                elsif (instruction = "00000100") then
                    IM_ult <= '0';
                    next_state <= POPPC;
                elsif (instruction = "00000101") then
                    IM_ult <= '0';
                    next_state <= ADD;
                elsif (instruction = "00000110") then
                    IM_ult <= '0';
                    next_state <= EXAND;
                elsif (instruction = "00000111") then
                    IM_ult <= '0';
                    next_state <= EXOR;
                elsif (instruction = "00001000") then
                    IM_ult <= '0';
                    next_state <= LOAD;
                elsif (instruction = "00001001") then
                    IM_ult <= '0';
                    next_state <= EXNOT;
                elsif (instruction = "00001010") then
                    IM_ult <= '0';
                    next_state <= FLIP;
                elsif (instruction = "00001011") then
                    IM_ult <= '0';
                    next_state <= NOP;
                elsif (instruction = "00001100") then
                    IM_ult <= '0';
                    next_state <= STORE;
                elsif (instruction = "00001101") then
                    IM_ult <= '0';
                    next_state <= POPSP;
                end if;
                exec <= '0';
                wait until rising_edge(clock);
            when BREAK =>
                halted <= '1';
                next_state <= BREAK;
                wait until rising_edge(clock);
            when PUSHSP =>
                exec <= '1';
                
                --Configura a ULA para sp - 4
                alu_a_src <= "01";
                alu_b_src <= "00";
                alu_shfimm_src  <= '1';
                alu_op <= "100";

                mem_b_addr_src <= "10";
                mem_b_wrd_src <= "10";
                
                -- Escreve na memória
                mem_we <= '1';
                mem_enable <= '1';
                wait until mem_busy = '1';
                mem_we <= '0';
                wait until mem_busy = '0';
                mem_enable <= '0';

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                exec <= '0';
                next_state <= F;
                wait until rising_edge(clock);
            when POPPC =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';
                --memA_rdd = mem[sp]

                --Configura a ULA e o seletor do PC
                pc_src <= '1';
                alu_a_src <= "01";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "001";

                --Atualiza SP e PC
                pc_en <= '1';
                sp_en <= '1';
                wait until rising_edge(clock);
                pc_en <= '0';
                sp_en <= '0';

                exec <= '0';
                next_state <= F;
                wait until rising_edge(clock);
            when ADD =>
                exec <= '1';

                --Configura a ULA para sp+4
                alu_a_src <= "01";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "001";

                mem_b_addr_src <= "10";
                mem_a_addr_src <= '0';

                --Carrega mem[sp] e mem[sp+4]
                mem_enable <= '1';
                wait until mem_busy <= '1';
                wait until mem_busy <= '0';
                mem_enable <= '0';

                --Atualiza sp para liberar a ULA
                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                --Configura a ULA para memA_rdd + memB_rdd
                alu_a_src <= "10";
                alu_b_src <= "01";
                alu_mem_src <= '1';
                alu_op <= "001";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when EXAND =>
                exec <= '1';

                --Configura a ULA para sp+4
                alu_a_src <= "01";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "001";

                mem_b_addr_src <= "10";
                mem_a_addr_src <= '0';
                --Carrega mem[sp] e mem[sp+4]
                mem_enable <= '1';
                wait until mem_busy <= '1';
                wait until mem_busy <= '0';
                mem_enable <= '0';

                --Atualiza sp para liberar a ULA
                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                --Configura a ULA para memA_rdd and memB_rdd
                alu_a_src <= "10";
                alu_b_src <= "01";
                alu_mem_src <= '1';
                alu_op <= "010";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge (clock);
            when EXOR =>
                exec <= '1';

                --Configura a ULA para sp+4
                alu_a_src <= "01";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "001";

                mem_b_addr_src <= "10";
                mem_a_addr_src <= '0';

                --Carrega mem[sp] e mem[sp+4]
                mem_enable <= '1';
                wait until mem_busy <= '1';
                wait until mem_busy <= '0';
                mem_enable <= '0';

                --Atualiza sp para liberar a ULA
                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                --Configura a ULA para memA_rdd or memB_rdd
                alu_a_src <= "10";
                alu_b_src <= "01";
                alu_mem_src <= '1';
                alu_op <= "011";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when LOAD =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                mem_b_wrd_src <= "01";
                mem_b_mem_src <= '0';
                mem_b_addr_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when EXNOT =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                -- Configura a ULA para not(memA_rdd)
                alu_a_src <= "10";
                alu_op <= "101";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when FLIP =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                -- Configura a ULA para flip(memA_rdd)
                alu_a_src <= "10";
                alu_op <= "110";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when NOP =>
                next_state <= F;
                wait until rising_edge(clock);
            when STORE =>
                exec <= '1';

                --Configura a ALU para sp + 4
                alu_a_src <= "00";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "001";

                mem_a_addr_src <= '0';
                mem_b_addr_src <= "11";
                -- Carrega os dados da memória
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                mem_b_addr_src <= "01";
                mem_b_wrd_src <= "01";
                mem_b_mem_src <= '1';

                exec <= '0';
                drct_store <= '1';
                next_state <= W;
                wait until rising_edge (clock);
            when STORE2 =>
                sp_en <= '1';
                --Como a ULA ficou configurada para SP + 4 durante todo o processo e SP foi atualizado duas vezes, efetivamente foi feito SP + 4 + 4 = SP + 8;

                exec <= '0';
                next_state <= F;
                wait until rising_edge(clock);
            when POPSP =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                --Configura a ULA para copiar memA_rdd
                alu_a_src <= "10";
                alu_op <= "000";

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                exec <= '0';
                next_state <= F;
                wait until rising_edge(clock);
            when ADDSP =>
                exec <= '1';

                --Configura a ULA
                alu_a_src <= "01";
                alu_b_src <= "11";
                alu_op <= "001";

                mem_a_addr_src <= '0';
                mem_b_addr_src <= "10";
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                --Configura a ULA para a próxima operação
                alu_a_src <= "10";
                alu_b_src <= "01";
                alu_mem_src <= '1';
                alu_op <= "001";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when CALL =>
                exec <= '1';

                alu_a_src <= "01";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "100";

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                alu_a_src <= "00";
                alu_op <= "000";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                drct_call <= '1';
                next_state <= W;
                wait until rising_edge(clock);
            when CALL2 =>
                exec <= '1';

                alu_b_src <= "10";
                alu_op <= "111";

                pc_src <= '0';
                pc_en <= '1';

                exec <= '0';
                next_state <= F;
                wait until rising_edge(clock);
            when STORESP =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';
                --memA_rdd = mem[sp]

                alu_a_src <= "01";
                alu_b_src <= "11";
                alu_op <= "001";

                mem_b_addr_src <= "10";
                mem_b_wrd_src <= "01";
                mem_b_mem_src <= '0';
                
                --Escreve na memória
                mem_we <= '1';
                mem_enable <= '1';
                wait until mem_busy = '1';
                mem_we <= '0';
                wait until mem_busy = '0';
                mem_enable <= '0';

                --Configura a ALU para sp + 4
                alu_a_src <= "00";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "001";

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                exec <= '0';
                next_state <= F;
                wait until rising_edge(clock);
            when LOADSP =>
                exec <= '1';

                --Configura a ULA
                alu_a_src <= "01";
                alu_b_src <= "11";
                alu_op <= "001";

                mem_b_addr_src <= "10";
                mem_enable <= '1';
                wait until mem_busy <= '1';
                wait until mem_busy <= '0';
                mem_enable <= '0';

                --Configura a ALU para sp - 4
                alu_a_src <= "00";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "100";

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "01";
                mem_b_mem_src <= '1';

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when IM1 =>
                exec <= '1';

                --Configura a ALU para sp - 4
                alu_a_src <= "00";
                alu_b_src <= "00";
                alu_shfimm_src <= '1';
                alu_op <= "100";

                sp_en <= '1';
                wait until rising_edge(clock);
                sp_en <= '0';

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "11";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when IMM =>
                exec <= '1';

                mem_a_addr_src <= '0';
                mem_enable <= '1';
                wait until mem_busy = '1';
                wait until mem_busy = '0';
                mem_enable <= '0';

                alu_b_src <= "01";
                alu_mem_src <= '0';
                alu_op <= "111";

                mem_b_addr_src <= "00";
                mem_b_wrd_src <= "00";

                exec <= '0';
                next_state <= W;
                wait until rising_edge(clock);
            when W =>
                --Estado para escrita na memória
                exec <= '1';
                pc_en <= '0';
                sp_en <= '0';
                ir_en <= '0';

                mem_we <= '1';
                mem_enable <= '1';
                wait until mem_busy = '1';
                mem_we <= '0';
                wait until mem_busy = '0';

                exec <= '0';
                if (drct_call = '1') then 
                    next_state <= CALL2;
                elsif (drct_store = '1') then
                    next_state <= STORE2;
                else
                    next_state <= F;
                end if;
                wait until rising_edge(clock);
        end case;
    end process com;
end architecture C_unit;