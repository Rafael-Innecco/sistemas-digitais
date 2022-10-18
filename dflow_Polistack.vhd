-------------------------------------------------------
--! @file dflow_Polistack.vhd
--! @brief Fluxo de dados do Polistack
--! @author Rafael de A. Innecco
--! @date 2021-12-01
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity data_flow is
    generic (
        addr_s : natural := 16; -- addres size in bits
        word_s : natural := 32 -- word size in bits
    );
    port (
       clock, reset: in bit;
       -- Memory Interface
       memA_addr, memB_addr : out bit_vector (addr_s - 1 downto 0);
       memB_wrd : out bit_vector (word_s -1 downto 0);
       memA_rdd, memB_rdd : in bit_vector (word_s -1 downto 0);
       -- Control Unit Interface
       pc_en, ir_en, sp_en : in bit;
       pc_src, mem_a_addr_src,
       mem_b_mem_src : in bit;
       mem_b_addr_src, mem_b_wrd_src,
       alu_a_src, alu_b_src : in bit_vector (1 downto 0);
       alu_shfimm_src, alu_mem_src : in bit;
       alu_op : in bit_vector (2 downto 0);
       instruction : out bit_vector (7 downto 0)
    );
end entity;


architecture dflow of data_flow is
    component d_register
        generic (
            width: natural;
            reset_value: natural
        );
        port (
            clock, reset, load: in bit;
            d: in bit_vector (width - 1 downto 0);
            q: out bit_vector (width - 1 downto 0)
        );
    end component d_register;

    component alu
        generic (
            size : natural
        );
    
        port (
            A, B : in bit_vector (size - 1 downto 0); --inputs
            F : out bit_vector (size - 1 downto 0);
            S : in bit_vector (2 downto 0);
            Z : out bit; --zero flag
            Ov : out bit; --overflow flag
            Co : out bit --carry out flag
        );
    end component alu; 

    signal PC, PC_out : bit_vector (word_s - 1 downto 0);
    signal SP_out : bit_vector (word_s - 1 downto 0);
    signal imm_shft, alu_mem, memb_mem : bit_vector (word_s - 1 downto 0);
    signal IR : bit_vector (7 downto 0);
    signal alu_a, alu_b, alu_ext : bit_vector (word_s - 1 downto 0);
    signal aluz, aluov, aluco : bit; --Flags da ula

begin 
    PC_reg: d_register
        generic map (word_s, 0)
        port map (clock, reset, pc_en, PC, PC_out);
    --

    SP_reg: d_register
        generic map (word_s, 131064)
        port map (clock, reset, sp_en, alu_ext, SP_out);
    --

    IR_reg: d_register
        generic map (8, 0)
        port map (clock, reset, ir_en, memA_rdd (7 downto 0), IR);
    --

    ULA: alu
        generic map (word_s)
        port map (alu_a, alu_b, alu_ext, alu_op, aluz, aluov,  aluco);
    --

    PC <= alu_ext when pc_src = '0' else
          memA_rdd;
    --

    memA_addr <= SP_out when mem_a_addr_src = '0' else
                 PC_out;
    --

    memB_addr <= SP_out when mem_b_addr_src = "00" else
                 memA_rdd when mem_b_addr_src = "01" else
                 alu_ext;
    --

    memB_wrd <= alu_ext when mem_b_wrd_src = "00" else
                memb_mem when mem_b_wrd_src = "01" else
                SP_out when mem_b_wrd_src = "10" else
                bit_vector(to_unsigned(0, word_s - 7)) & IR(6 downto 0);
    --

    memb_mem <= memA_rdd when mem_b_mem_src = '0' else
                memB_rdd;
    --

    alu_a <= PC_out when alu_a_src = "00" else
             SP_out when alu_a_src = "01" else
             memA_rdd;
    --

    alu_b <= imm_shft when alu_b_src = "00" else
             alu_mem when alu_b_src = "01" else
             (bit_vector(to_unsigned(0, word_s - 5)) & IR(4 downto 0)) sll 5 when alu_b_src = "10" else
             (bit_vector(to_unsigned(0, word_s - 5)) & not(IR(4)) & IR(3 downto 0)) sll 2;
    --

    imm_shft <= bit_vector(to_unsigned(1, word_s)) when alu_shfimm_src = '0' else
                bit_vector(to_unsigned(4, word_s));
    --

    alu_mem <= (memA_rdd sll 7) or (bit_vector(to_unsigned(0, word_s - 7)) & IR(6 downto 0)) when alu_mem_src = '0' else
                memB_rdd;
    --

    instruction <= IR;

end architecture dflow;