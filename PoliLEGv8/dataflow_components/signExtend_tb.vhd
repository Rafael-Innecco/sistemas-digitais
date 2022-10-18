-------------------------------------------------------
--! @file signExtend.vhd
--! @brief Testbench para o comonent que faz a extensão de sinal
--! @author Rafael de A. Innecco
--! @date 2022-05-25
-------------------------------------------------------

--  A testbench has no ports.
entity signExtend_tb is
end entity signExtend_tb;
        

architecture testbench of signExtend_tb is
        
    --  Declaration of the component to be tested.
    component signExtend
        port (
            i : in bit_vector (31 downto 0);
            o : out bit_vector (63 downto 0)
        );
    end component signExtend;
    -- Declaration of signals
    signal i :  bit_vector (31 downto 0);
    signal o :  bit_vector (63 downto 0);
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.signExtend(sgnExt)
        port map (i, o);
    --

    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            inpt :  bit_vector (31 downto 0);
            --  The expected outputs of the circuit.
            outpt : bit_vector (63 downto 0);
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("00010111000000000000000000000000",
                 "1111111111111111111111111111111111111111000000000000000000000000"),
                ("00010101111111111111111111111111",
                 "0000000000000000000000000000000000000001111111111111111111111111"),
                ("10110100111000000000000000010011",
                 "1111111111111111111111111111111111111111111111110000000000000000"),
                ("11111000010001100111001010101010",
                 "0000000000000000000000000000000000000000000000000000000001100111")
            );
        
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.
            i <= patterns(k).inpt;
            --  Wait for the results.
                wait for 5 ns;

            --  Check the outputs.
            assert o = patterns(k).outpt
                report "Bad output" severity error;
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;