library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;
use ieee.math_real.all;

--  A testbench has no ports.
entity secded_gen_tb is
end entity secded_gen_tb;

architecture testbench of secded_gen_tb is
    function secded_message_size (size: positive) return natural is
    begin
        return natural(floorsec(log2(real(size)))) + natural(size) + 2;
    end function;

    --  Declaration of the component to be tested.
    component secded_dec is
        generic(
        data_size: positive := 16
        );
        port (
            mem_data: in bit_vector(secded_message_size(data_size)-1 downto 0);
            u_data: out bit_vector(data_size-1 downto 0);
            uncorrectable_error: out bit
        );
    end component secded_dec;
    -- Declaration of signals
    signal inData   : bit_vector(21 downto 0);
    signal outData  : bit_vector(15 downto 0);
    signal uerror   : bit;
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.secded_dec(t3)
        port map (inData, outData, uerror);
        
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            inData  : bit_vector (21 downto 0);
            --  The expected outputs of the circuit.
            outData : bit_vector (15 downto 0);
            uerror: bit;
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("0011000011110000110000", "0110001111000110", '0'),
                ("0011000011110000010000", "0110001111000110", '0'),
                ("0011000010110100110000", "0110001011010110", '1'),
                ("1011000011110000110000", "0110001111000110", '0'),
                ("0011000011110000110001", "0110001111000110", '0'),
                ("0011000011110000110011", "0110001111000111", '1')
            );
        
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.
            inData <= patterns(k).inData;
            --  Wait for the results.
                wait for 10 ns;
            --  Check the outputs.
            assert outData = patterns(k).outData
                report "Bad outData" severity error;
            assert uerror = patterns(k).uerror
                report "Bad uerror" severity error;
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;