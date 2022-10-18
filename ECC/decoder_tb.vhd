-------------------------------------------------------
--! @file generic_testbench.vhd
--! @brief Testbench para o decodificador da secded de 16 bits
--! @author Rafael de A. Innecco
--! @date 2022-07-17
-------------------------------------------------------

--  A testbench has no ports.
entity secded_tb is
end entity secded_tb;

architecture testbench of secded_tb is
    --  Declaration of the component to be tested.
    component secded_dec16 is
        port (
            mem_data    : in bit_vector(21 downto 0);
            u_data      : out bit_vector(15 downto 0);
            syndrome    : out natural;
            two_errors  : out bit;
            one_error   : out bit
        );
    end component secded_dec16;
    -- Declaration of signals
    signal inData   : bit_vector(21 downto 0);
    signal outData  : bit_vector(15 downto 0);
    signal syndrome : natural;
    signal terrors, oerror : bit;
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.secded_dec16(t2)
        port map (inData, outData, syndrome, terrors, oerror);
        
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            inData  : bit_vector (21 downto 0);
            --  The expected outputs of the circuit.
            outData : bit_vector (15 downto 0);
            syndrome: natural;
            terrors, oerror : bit;
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("0011000011110000110000", "0110001111000110", 0, '0', '0'),
                ("0011000011110000010000", "0110001111000110", 6, '0', '1'),
                ("0011000010110100110000", "0110001011010110", 4, '1', '0'),
                ("1011000011110000110000", "0110001111000110", 0, '0', '0'),
                ("0011000011110000110001", "0110001111000110", 1, '0', '1'),
                ("0011000011110000110011", "0110001111000111", 3, '1', '0')
            );
        
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.
            inData <= patterns(k).inData;
            --  Wait for the results.
                wait for 5 ns;
            --  Check the outputs.
            assert outData = patterns(k).outData
                report "Bad outData" severity error;
            assert syndrome = patterns(k).syndrome
                report "Bad syndrome" severity error;
            assert terrors = patterns(k).terrors
                report "Bad terrors" severity error;
            assert oerror = patterns(k).oerror
                report "Bad oerror" severity error;
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;