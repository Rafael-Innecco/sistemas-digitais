-------------------------------------------------------
--! @file rom_simples_tb.vhd
--! @brief Testbench para a ROM simples
--! @author Rafael de A. Innecco
--! @date 2021-11-10
-------------------------------------------------------

--  A testbench has no ports.
entity rom_arquivo_tb is
end entity rom_arquivo_tb;
            
    
architecture testbench of rom_arquivo_tb is
            
    --  Declaration of the component to be tested.
    component rom_arquivo
        port (
            addr: in bit_vector (3 downto 0);
            data: out bit_vector (7 downto 0)
        );
    end component rom_arquivo;

    --  Declaration of signals
    signal a: bit_vector (3 downto 0);
    signal d: bit_vector (7 downto 0);

begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.rom_arquivo(arch)
        port map (a, d);
            
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            addr: bit_vector (3 downto 0);
            --  The expected outputs of the circuit.
            data: bit_vector (7 downto 0);
        end record;
            
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("0000", "00000000"),
                ("0001", "00000011"),
                ("0010", "11000000"),
                ("0011", "00001100"),
                ("0100", "00110000"),
                ("0101", "01010101"),
                ("0110", "10101010"),
                ("0111", "11111111"),
                ("1000", "11100000"),
                ("1001", "11100111"),
                ("1010", "00000111"),
                ("1011", "00011000"),
                ("1100", "11000011"),
                ("1101", "00111100"),
                ("1110", "11110000"),
                ("1111", "00001111")
            );
            
    begin
        --  Check each pattern.
        for k in patterns'range loop
            
            --  Set the inputs.
            a <= patterns(k).addr;
            --  Wait for the results.
            wait for 5 ns;
    
            --  Check the outputs.
            assert d = patterns(k).data
            report "bad data" severity error;
        end loop;
                
        assert false report "end of test" severity note;
                
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;