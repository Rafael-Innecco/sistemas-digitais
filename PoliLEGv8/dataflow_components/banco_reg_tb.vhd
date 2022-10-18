-------------------------------------------------------
--! @file banco_reg_tb.vhd
--! @brief Testbench para o banco de registradores
--! @author Rafael de A. Innecco
--! @date 2021-06-19
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

--  A testbench has no ports.
entity banco_reg_tb is
end entity banco_reg_tb;
    
architecture testbench of banco_reg_tb is

    --Declaration of components to be tested
    component regfile
        generic (
            reg_n   : natural := 4;
            word_s  : natural := 0
        );
        port (
            clock   : in bit;
            reset   : in bit;
            regWrite    : in bit;
            rr1, rr2, wr    : in bit_vector (natural(ceil(log2(real(reg_n)))) - 1 downto 0);
            d               : in bit_vector (word_s - 1 downto 0);
            q1, q2          : out bit_vector (word_s - 1 downto 0)
        );
    end component regfile;

    --Declaration of signals
    signal word_s : natural := 4;
    signal reg_n  : natural := 3;
    signal clock, reset, regWrite: bit;
    signal rr1, rr2, wr : bit_vector (natural(ceil(log2(real(reg_n)))) - 1 downto 0);
    signal d, q1, q2: bit_vector (word_s - 1 downto 0);
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.regfile(behavioral) 
        generic map (reg_n, word_s)
        port map (clock, reset, regWrite, rr1, rr2, wr, d, q1, q2);
    -- Clock generator
    clk: process is
    begin
        clock <= '0';
        wait for 0.5 ns;
        clock <= '1';
        wait for 0.5 ns;
    end process clk;
    
    rr1 <= "10";
    wr <= "10";
    rr2 <= "10";

    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            d : bit_vector (word_s - 1 downto 0);
            regWrite : bit;
            reset : bit;
            --  The expected outputs of the circuit.
            q1 : bit_vector(word_s - 1 downto 0);

        end record;

        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("1011",'0','1',"0000"),
                ("1100",'1','0',"0000"),
                ("1100",'1','1',"0000"),
                ("0101",'0','1',"0000"),
                ("1001",'1','0',"0000"),
                ("1111",'0','0',"0000"),
                ("1101",'1','1',"0000"));
    begin
        --  Check each pattern.
        for k in patterns'range loop

            --  Set the inputs.
            d <= patterns(k).d;
            regWrite <= patterns(k).regWrite;
            reset <= patterns(k).reset;

            --  Wait for the results.
            wait for 1 ns;
        
            --  Check the outputs.
            assert q1 = patterns(k).q1
            report "bad q" severity error;
        end loop;
    
        assert false report "end of test" severity note;
    
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;