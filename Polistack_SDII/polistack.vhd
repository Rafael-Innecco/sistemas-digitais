-------------------------------------------------------
--! @file polistack.vhd
--! @brief Processador Polsitack
--! @author Rafael de A. Innecco
--! @date 2022-04-11
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity polistack is
    
    generic(
        addr_s : natural := 16; -- adrr_s size in bits
        word_s : natural := 32  -- word size in bits
    );

    port (
        clock, reset : in bit;
        halted: out bit;
        -- memory interface
        mem_we, mem_enable      : out bit;
        memA_addr, memB_addr    : out bit_vector (addr_s - 1 downto 0);
        memB_wrd                : out bit_vector (word_s - 1 downto 0);
        memA_rdd, memB_rdd      : in  bit_vector (word_s - 1 downto 0);
        busy                    : in  bit
    );
end entity;

architecture allinone of polistack is
    -- Sinais de ligação entre o Fluxo de Dados e a unidade de controle
    signal pc_en, ir_en, sp_en : bit;
    signal pc_src, mem_a_addr_src, mem_b_mem_src : bit;
    signal mem_b_addr_src, mem_b_wrd_src, alu_a_src, alu_b_src : bit_vector (1 downto 0);
    signal alu_shfimm_src, alu_mem_src : bit;
    signal alu_op : bit_vector (2 downto 0);
    signal instruction : bit_vector (7 downto 0);

    -- Sinais da ULA
    signal I0, I1, I2, I3, I4, I5, I6, I7, SAI : bit_vector (word_s - 1 downto 0); --Sinais intermediários
    signal CA, CS : bit_vector (word_s downto 0); -- Sinais utilizados para realizar o carry na soma e na subtração
    signal NEG_B : bit_vector (word_s - 1 downto 0);  -- Sinal para representar o oposto de B

    -- Sinais do Fluxo de dados
    signal PC_in, PC : bit_vector (word_s - 1 downto 0);
    signal SP : bit_vector (word_s - 1 downto 0);
    signal imm_shft, alu_mem, memb_mem : bit_vector (word_s - 1 downto 0);
    signal IR : bit_vector (7 downto 0);
    signal alu_a, alu_b, alu_ext : bit_vector (word_s - 1 downto 0);
    signal aluz, aluov, aluco : bit; --Flags da ula
    signal H : bit := '0';
    signal ext : bit_vector (word_s - 8 downto 0);

    -- Sinais da unidade de controle
    type state_type is (fetch, decode, break, pushsp, poppc, inst_alu,
                        load, inst_alu2, nop, store, popsp, addsp, 
                        call, storesp, loadsp, im1, im_mais,
                        wrt, wrt_sp);
    signal present_state : state_type := fetch;
    signal next_state : state_type;
    signal ultima_im : bit := '0'; -- Indica se a última instrução foi im1 ou im_mais
    signal inter_op : bit_vector (2 downto 0);

begin
    --Fluxo de dados:
    -- -- Registrador IR
    LD_PC: process (clock, reset) is
    begin
        if reset = '1' then
            PC <= bit_vector(to_unsigned(0, word_s));
        elsif (clock = '1') and (pc_en = '1') then
                PC <= PC_in;
        end if;
    end process LD_PC;
    --

    -- -- Registrador SP
    LD_SP: process (clock, reset) is
    begin
        if reset = '1' then
            SP <= bit_vector(to_unsigned(131064, word_s));
        elsif (clock = '1') and (sp_en = '1') then
            SP <= alu_ext;
        end if;
    end process LD_SP;
    -- 

    -- -- Registrador IR
    LD_IR: process (clock) is
    begin
        if reset = '1' then
            IR <= bit_vector(to_unsigned(0, 8));
        elsif (clock = '1') and (ir_en = '1') then
            IR <= memA_rdd (7 downto 0);
        end if;
    end process LD_IR;
    --

    -- -- ULA

    I0 <= alu_a; -- Cópia direta de A
    I2 <= alu_a and alu_b; -- And bit a bit entre A e B
    I3 <= alu_a or alu_b; -- Or bit a bit entre A e B
    I5 <= not alu_a; -- Not A bit a bit

    -- Operação de inversão da ordem dos bits de A:
    GEN_1: for j in 0 to (word_s - 1) generate
        I6(j) <= alu_a(word_s - 1 - j);
    end generate GEN_1;

    I7 <= alu_b; -- Cópia direta de B

    -- Implementação da soma por Carry-lookahead
    CA(0) <= '0'; --Carry-in = 0
    GEN_2: for j in 1 to (word_s) generate
        CA(j) <= (alu_a(j - 1) and alu_b(j - 1)) or ((alu_a(j - 1) or alu_b(j - 1)) and CA(j - 1)); --Carry da soma do j-ésimo bit
    end generate GEN_2;

    GEN_3: for j in 0 to (word_s - 1) generate
        I1(j) <= alu_a(j) xor alu_b(j) xor CA(j);
    end generate GEN_3;

    --Implementação da subtração

    CS(0) <= '1'; --Carry-in = 1 (subtração em complemento de 2 = A + (-B + 1))
    GEN_4  : for j in 1 to (word_s) generate
        CS(j) <= (alu_a(j - 1) and not(alu_b(j - 1))) or ((alu_a(j - 1) or not(alu_b(j - 1))) and CS(j - 1)); --Carry da soma do j-ésimo bit
    end generate GEN_4;

    GEN_5: for j in 0 to (word_s - 1) generate
        I4(j) <= alu_a(j) xor not(alu_b(j)) xor CS(j);
    end generate GEN_5;

    -- Seleção da saída de maneira análoga a um multiplexador (SAI será utilizado em uma comparação, por isso, F receberá SAI posteriormente)
    SAI <= I0 when alu_op = "000" else
         I1 when alu_op = "001" else
         I2 when alu_op = "010" else
         I3 when alu_op = "011" else
         I4 when alu_op = "100" else
         I5 when alu_op = "101" else
         I6 when alu_op = "110" else
         I7 when alu_op = "111" else
         alu_a; -- Caso padrão, nunca será selecionado em situações normais
    --

    -- Implementação de flags

    -- Flag de overflow
    aluov <= (CA(word_s) xor CA(word_s - 1)) when alu_op = "001" else
          (CS(word_s) xor CS(word_s - 1)) when alu_op = "100" else
          '0';
    --

    -- Flag  de Carry-out
    aluco <= CA(word_s) when alu_op = "001" else
          CS(word_s) when alu_op = "100" else
          '0';
    --

    aluz <= '1' when SAI = bit_vector(to_unsigned(0, word_s)) else
         '0';
    --

    alu_ext <= SAI;
    -- -- 

    PC_in <= alu_ext when pc_src = '0' else
          memA_rdd;
    --

    memA_addr <= SP when mem_a_addr_src = '0' else
                 PC;
    --

    memB_addr <= SP when mem_b_addr_src = "00" else
                 memA_rdd when mem_b_addr_src = "01" else
                 alu_ext;
    --

    memB_wrd <= alu_ext when mem_b_wrd_src = "00" else
                memb_mem when mem_b_wrd_src = "01" else
                SP when mem_b_wrd_src = "10" else
                ext & IR(6 downto 0);
    --

    signExt: for i in 0 to word_s - 8 generate
        ext(i) <= IR(6);
    end generate signExt;

    memb_mem <= memA_rdd when mem_b_mem_src = '0' else
                memB_rdd;
    --

    alu_a <= PC when alu_a_src = "00" else
             SP when alu_a_src = "01" else
             memA_rdd;
    --

    alu_b <= imm_shft when alu_b_src = "00" else
             alu_mem when alu_b_src = "01" else
             (bit_vector(to_unsigned(0, word_s - 5)) & IR(4 downto 0)) sll 5 when alu_b_src = "10" else
             bit_vector(to_unsigned(0, word_s - 7)) & not(IR(4)) & IR(3 downto 0) & "00";
    --

    imm_shft <= bit_vector(to_unsigned(1, word_s)) when alu_shfimm_src = '0' else
                bit_vector(to_unsigned(4, word_s));
    --

    alu_mem <= (memA_rdd sll 7) or (bit_vector(to_unsigned(0, word_s - 7)) & IR(6 downto 0)) when alu_mem_src = '0' else
                memB_rdd;
    --

    instruction <= IR;
    --

    -- Unidade de controle:
    sequencial : process (clock) is
        begin
            if clock = '1' then
                present_state <= next_state;
            end if;
        end process sequencial;
        
        opera: process is
        begin
            case present_state is
                when fetch =>
                    pc_en <= '0';
                    sp_en <= '0';
                    ir_en <= '0';
        
                    --Faz a leitura de mem[PC]
                    mem_a_addr_src <= '1';
                    mem_enable <= '1';
                    wait until falling_edge(busy);
                    mem_enable <= '0';
    
                    alu_a_src <= "00"; -- A = PC
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '0'; -- imm_shift = 1
                    alu_op <= "001"; -- A + B
    
                    pc_src <= '0'; -- Entrada do PC = Saída da ULA
                    -- Atualiza os registradores PC e IR
                    pc_en <= '1';
                    ir_en <= '1';
                    next_state <= decode;
                    wait until present_state'event;
                when decode =>
                    pc_en <= '0';
                    ir_en <= '0';
                    -- Conforme recomendado, busca o topo da pilha e o próximo elemento
                    mem_a_addr_src <= '0'; -- mem_a_addr = sp
    
                    
                    mem_b_addr_src <= "10"; -- mem_b_addr = Saída da ULA
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "001"; -- A + B
    
                    mem_enable <= '1'; -- Leitura de mem[sp] (porta A) e mem[sp + 4] (porta B)
                    wait until falling_edge(busy);
                    mem_enable <= '0';
    
                    -- Faz a decodifição de instruction
                    if instruction(7) = '1' then
                        if ultima_im = '1' then
                            next_state <= im_mais;
                        else
                            ultima_im <= '1';
                            next_state <= im1;
                        end if;
                    elsif instruction(6) = '1' then
                        ultima_im <= '0';
                        if instruction(5) = '1' then
                            next_state <= loadsp;
                        else
                            next_state <= storesp;
                        end if;
                    elsif instruction(5) = '1' then
                        ultima_im <= '0';
                        next_state <= call;
                    elsif instruction(4) = '1' then
                        ultima_im <= '0';
                        next_state <= addsp;
                    elsif instruction(3) = '1' then
                        ultima_im <= '0';
                        if instruction(2 downto 0) = "101" then
                            next_state <= popsp;
                        elsif instruction(2 downto 0) = "100" then
                            next_state <= store;
                        elsif instruction(2 downto 0) = "011" then
                            next_state <= nop;
                        elsif instruction(2 downto 0) = "010" then
                            inter_op <= '1' & instruction(1 downto 0);
                            next_state <= inst_alu2;
                        elsif instruction(2 downto 0) = "001" then
                            inter_op <= '1' & instruction(1 downto 0);
                            next_state <= inst_alu2;
                        elsif instruction(2 downto 0) = "000" then
                            next_state <= load;
                        end if;
                    elsif instruction(2) = '1' then
                        ultima_im <= '0';
                        if instruction(1 downto 0) = "00" then
                            next_state <= poppc;
                        else
                            inter_op <= "0" & instruction(1 downto 0);
                            next_state <= inst_alu;
                        end if;
                    elsif instruction(1 downto 0) = "10" then
                        ultima_im <= '0';
                        next_state <= pushsp;
                    else -- Caso a instrução chegue não caia em nenhum outro caso, o processador deve parar
                        next_state <= break;
                    end if;
                    wait until present_state'event;
                when break =>
                    halted <= '1';
                    next_state <= break;
                    wait until present_state'event;
                when pushsp =>
    
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "100"; -- A - B
    
                    -- mem_b_wrd = sp
                    mem_b_wrd_src <= "10";
                    mem_b_addr_src <= "10"; --mem_b_addr = saída ULA = sp - 4
    
                    -- Realiza a escrita
                    mem_enable <= '1';
                    mem_we <= '1';
                    next_state <= wrt_sp;
                    wait until present_state'event;
                when poppc =>
                    -- mem[sp] já está carregado na porta A
                    --Atualiza PC para mem[sp]
                    pc_src <= '1';
                    pc_en <= '1';
    
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "001"; -- A + B
    
                    sp_en <= '1';
    
                    next_state <= fetch;
                    wait until present_state'event;
                when inst_alu => -- Cobre os casos de ADD, AND e OR
                    -- Como mem[sp] e mem[sp + 4] já estão carregados, pode-se fazer sp = sp + 4 sem perder acesso ao mem[sp] original
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "001"; -- A + B
    
                    sp_en <= '1';
                    wait until rising_edge(clock);
                    sp_en <= '0';
                    -- Nesse ponto, sp = sp + 4
    
                    alu_a_src <= "10"; -- A = memA_rdd
                    alu_b_src <= "01"; -- B = alu_mem
                    alu_mem_src <= '1'; -- alu_mem = memB_rdd
                    alu_op <= inter_op;
    
                    mem_b_wrd_src <= "00"; -- memB_wrd = A + B
                    mem_b_addr_src <= "00"; -- mem_b_addr = sp (sp + 4)
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt;
                    wait until present_state'event;
                when load =>
                    mem_a_addr_src <= '0'; --mem_a_addr = sp
                    mem_b_addr_src <= "01"; --mem_b_addr = memA_rdd = mem[sp]
                    
                    mem_enable <= '1';
                    wait until falling_edge(busy);
                    mem_enable <= '0';
    
                    mem_b_addr_src <= "00"; -- mem_b_addr = sp
                    mem_b_wrd_src <= "01"; -- memB_wrd = memb_mem
                    mem_b_mem_src <= '1'; -- memb_mem = memB_wrd = mem[sp]
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt;
                    wait until present_state'event;
                when inst_alu2 =>
                    alu_a_src <= "10"; -- A = memA_rdd = mem[sp]
                    alu_op <= inter_op; --not(A) ou flip(A)
    
                    mem_b_addr_src <= "00"; -- memB_addr = sp
                    mem_b_wrd_src <= "00"; --saída da ULA
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt;
                    wait until present_state'event;
                when nop =>
                    next_state <= fetch;
                    wait until present_state'event;
                when store =>
                    -- memA_rdd = mem[sp] e memB_rdd = mem[sp + 4]
                    mem_b_addr_src <= "01"; -- memA_rdd
                    mem_b_wrd_src <= "01";
                    mem_b_mem_src <= '1';
    
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "001"; -- A + B
    
                    sp_en <= '1';
                    wait until rising_edge(clock);
                    sp_en <= '0';
    
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "001"; -- A + B
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt_sp;
                    wait until present_state'event;
                when popsp =>
                    -- memA_rdd = mem[sp]
    
                    alu_a_src <= "10"; -- A = memA_rdd
                    alu_op <= "000"; -- A
    
                    sp_en <= '1';
    
                    next_state <= fetch;
                    wait until present_state'event;
                when addsp =>
                    alu_a_src <= "01"; -- A = sp
                    alu_b_src <= "11"; -- B = not(ir[4])&ir[3:0]«2
                    alu_op <= "001"; -- A + B
    
                    mem_a_addr_src <= '0';
                    mem_b_addr_src <= "10";
    
                    mem_enable <= '1';
                    wait until falling_edge(busy);
                    mem_enable <= '0';
    
                    alu_a_src <= "10"; -- A = mem[sp]
                    alu_b_src <= "01";
                    alu_mem_src <= '1';
                    alu_op <= "001"; -- A + B
    
                    mem_b_addr_src <= "00";
                    mem_b_wrd_src <= "00";
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt;
                    wait until present_state'event;
                when call =>
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "100"; -- A + B
    
                    sp_en <= '1';
                    wait until rising_edge(clock);
                    sp_en <= '0';
    
                    alu_a_src <= "00"; -- A = pc
                    alu_op <= "000"; -- A
    
                    mem_b_addr_src <= "00"; --memB_Addr = sp
                    mem_b_wrd_src <= "00"; -- ULA
    
                    mem_enable <= '1';
                    mem_we <= '1';
                    wait until busy = '1';
                    mem_we <= '0';
                    wait until busy = '0';
                    mem_enable <= '0';
                        
                    alu_b_src <= "10"; -- B = ir[4:0] << 5
                    alu_op <= "111";
                    pc_src <= '0';
    
                    pc_en <= '1';
                    next_state <= fetch;
                    wait until present_state'event;
                when storesp =>
                    alu_a_src <= "01"; -- A = sp
                    alu_b_src <= "11"; -- B = not(ir[4])&ir[3:0]«2
                    alu_op <= "001"; -- A + B
    
                    mem_b_addr_src <= "10"; -- ULA
                    mem_b_wrd_src <= "01";
                    mem_b_mem_src <= '0';
    
                    mem_enable <= '1';
                    mem_we <= '1';
                    wait until busy <= '1';
                    mem_we <= '0';
                    wait until busy <= '0';
                    mem_enable <= '0';
    
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "001"; -- A + B
    
                    sp_en <= '1';
                    next_state <= fetch;
                    wait until present_state'event;
                when loadsp =>
                    alu_a_src <= "01"; -- A = sp
                    alu_b_src <= "11"; -- B = not(ir[4])&ir[3:0]«2
                    alu_op <= "001"; -- A + B
    
                    mem_b_addr_src <= "10"; -- ULA
                    mem_enable <= '1';
                    wait until falling_edge(busy);
                    mem_enable <= '0';
    
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "100"; -- A - B
    
                    mem_b_addr_src <= "10";
                    mem_b_wrd_src <= "01";
                    mem_b_mem_src <= '1';
    
                    next_state <= wrt_sp;
                    wait until present_state'event;
                when im1 =>
                    alu_a_src <= "01"; -- A = SP
                    alu_b_src <= "00"; -- B = imm_shift
                    alu_shfimm_src <= '1'; -- imm_shift = 4
                    alu_op <= "100"; -- A - B
    
                    sp_en <= '1';
                    wait until rising_edge(clock);
                    sp_en <= '0';
    
                    mem_b_addr_src <= "00"; -- sp
                    mem_b_wrd_src <= "11"; -- signExt(ir[6:0)
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt;
                    wait until present_state'event;
                when im_mais =>
                    mem_b_addr_src <= "00";
                    mem_b_wrd_src <= "00";
    
                    alu_b_src <= "01";
                    alu_mem_src <= '0';
                    alu_op <= "111";
    
                    mem_enable <= '1';
                    mem_we <= '1';
    
                    next_state <= wrt;
                    wait until present_state'event;
                when wrt => -- Realiza a escrita sem atualizar registradores
                    mem_enable <= '1';
                    mem_we <= '1';
                    wait until busy = '1';
                    mem_we <= '0';
                    wait until busy = '0';
                    mem_enable <= '0';
                    next_state <= fetch;
                    wait until present_state'event;
                when wrt_sp => -- Realiza a escrita e depois atualiza o registrador sp
                    mem_enable <= '1';
                    mem_we <= '1';
                    wait until busy = '1';
                    mem_we <= '0';
                    wait until busy = '0';
                    mem_enable <= '0';
                    sp_en <= '1';
                    next_state <= fetch;
                    wait until present_state'event;
            end case;
        end process opera;
end architecture allinone; 