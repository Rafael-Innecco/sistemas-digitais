-------------------------------------------------------
--! @file shift_left_tb.vhd
--! @brief Testebench para componente que faz shift de dois bits para a esquerda
--! @author Rafael de A. Innecco
--! @date 202s-06-15
-------------------------------------------------------

--  A testbench has no ports.
entity shift_left_tb is
end entity shift_left_tb;
        

architecture testbench of shift_left_tb is
        
    --  Declaration of the component to be tested.
    component shiftleft2
        generic (
            ws : natural := 64
        );
        port (
            i : in bit_vector (ws - 1 downto 0);
            o : out bit_vector (ws - 1 downto 0)
        );
    end component shiftleft2;

    -- Declaration of signals
    signal i, o : bit_vector (5 - 1 downto 0);

begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.shiftleft2(shifter)
        generic map (5)
        port map (i, o);
        
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            inpt :  bit_vector (5 - 1 downto 0);
            --  The expected outputs of the circuit.
            outpt : bit_vector (5 - 1 downto 0);
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("00000", "00000"),
                ("00001", "00100"),
                ("01001", "00100"),
                ("11111", "11100"),
                ("10101", "10100"),
                ("11100", "10000")
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