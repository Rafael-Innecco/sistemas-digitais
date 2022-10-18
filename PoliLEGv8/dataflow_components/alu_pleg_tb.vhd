-------------------------------------------------------
--! @file alu_pleg.vhd
--! @brief Testbenchpara a Undade Lógica artmética do PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-06-19
-------------------------------------------------------

--  A testbench has no ports.
entity alu_pleg_tb is
end entity alu_pleg_tb;
        

architecture testbench of alu_pleg_tb is
        
    --  Declaration of the component to be tested.
    component alu is
        generic (
            size : natural
        );
        port (
                A, B    : in bit_vector (size - 1 downto 0);
                F       : out bit_vector (size - 1 downto 0);
                S       : in bit_vector (3 downto 0);
                Z       : out bit;
                Ov      : out bit;
                Co      : out bit
        );
    end component alu;
    -- Declaration of signals
    signal size     : natural := 5;
    signal A, B, F  : bit_vector (size - 1 downto 0);
    signal S        : bit_vector (3 downto 0);
    signal Z, Ov, Co: bit; 
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.alu(behavioral)
        generic map (size)
        port map (A, B, F, S, Z, Ov, Co);
    --

    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            a   : bit_vector (size - 1 downto 0);
            b   : bit_vector (size - 1 downto 0);
            s   : bit_vector (3 downto 0);
            --  The expected outputs of the circuit.
            f   : bit_vector (size -1 downto 0);
            z   : bit;
            ov  : bit;
            co  : bit;
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("01001", "00111", "0000", "00001", '0', '1', '0'),
                ("10110", "11000", "0001", "11110", '0', '1', '1'),
                ("01101", "10101", "0010", "00010", '0', '0', '1'),
                ("11000", "10011", "0110", "00101", '0', '0', '1'),
                ("10001", "10100", "0111", "00001", '0', '0', '0'),
                ("10100", "10001", "0111", "00000", '1', '0', '1'),
                ("01100", "10100", "1100", "00011", '0', '0', '0')
            );
        
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.
            A <= patterns(k).a;
            B <= patterns(k).b;
            S <= patterns(k).s;
            --  Wait for the results.
            wait for 5 ns;

            --  Check the outputs.
            assert F = patterns(k).f
                report "Bad F" severity error;
            assert Z = patterns(k).z
                report "Bad Z" severity error;
            assert Ov = patterns(k).ov
                report "Bad Ov" severity error;
            assert Co = patterns(k).co
                report "Bad Co" severity error;
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;