-------------------------------------------------------
--! @file generic_testbench.vhd
--! @brief Template para testbench
--! @author Rafael de A. Innecco
--! @date 2021-11-10
-------------------------------------------------------

--  A testbench has no ports.
entity generic_tb is
end entity generic_tb;
        

architecture testbench of generic_tb is
        
    --  Declaration of the component to be tested.
          
    -- Declaration of signals
        
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.name(architecture)
        generic map ()
        port map ();
        
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.

            --  The expected outputs of the circuit.

        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (

            );
        
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.

            --  Wait for the results.
                wait for 5 ns;

            --  Check the outputs.
              
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;