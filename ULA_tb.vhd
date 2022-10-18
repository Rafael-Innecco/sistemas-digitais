-------------------------------------------------------
--! @file ULA.vhdl
--! @brief Testbench para a ULA
--! @author Rafael de A. Innecco
--! @date 2021-11-10
-------------------------------------------------------

--  A testbench has no ports.
entity ULA_tb is
end entity ULA_tb;
    
architecture testbench of ULA_tb is
    
    --  Declaration of the component to be tested.
    component alu
        generic (
            size : natural := 8
        );

        port (
            A, B : in bit_vector (size - 1 downto 0); --inputs
            F : out bit_vector (size - 1 downto 0);
            S : in bit_vector (2 downto 0);
            Z : out bit; --zero flag
            Ov : out bit; --overflow flag
            Co : out bit --carry out fkag
        );
    end component alu;
      
    -- Declaration of signals
    signal size : natural := 8;
    signal a, b : bit_vector (size - 1 downto 0); 
    signal f : bit_vector (size - 1 downto 0);
    signal s : bit_vector (2 downto 0);
    signal z : bit;
    signal ov : bit; 
    signal co : bit;
    
    begin
      -- Component instantiation
      -- DUT = Device Under Test 
      DUT: entity work.alu(t1)
        generic map (size)
        port map (a, b, f, s, z, ov, co);
    
      --  This process does the real job.
      stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            a : bit_vector (size - 1 downto 0);
            b : bit_vector (size - 1 downto 0);
            s : bit_vector (2 downto 0);
            --  The expected outputs of the circuit.
            f : bit_vector(size - 1 downto 0);
            z : bit;
            ov : bit;
            co : bit;
        end record;
    
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
          (
            ("00000000", "01101110", "000", "00000000", '1', '0', '0'),
            ("01001101", "11010111", "010", "01000101", '0', '0', '0'),
            ("10100110", "00011101", "011", "10111111", '0', '0', '0'),
            ("10100101", "11111111", "101", "01011010", '0', '0', '0'),
            ("00100000", "01010101", "110", "00000100", '0', '0', '0'),
            ("00000000", "11100011", "111", "11100011", '0', '0', '0'),
            ("10101010", "01010101", "010", "00000000", '1', '0', '0'),
            ("00001111", "00000100", "001", "00010011", '0', '0', '0'),
            ("01111111", "00000001", "001", "10000000", '0', '1', '0'),
            ("00000111", "00000111", "100", "00000000", '1', '0', '1'));
    
      begin
        --  Check each pattern.
        for k in patterns'range loop
    
            --  Set the inputs.
            a <= patterns(k).a;
            b <= patterns(k).b;
            s <= patterns(k).s;
    
            --  Wait for the results.
            wait for 5 ns;
          
            --  Check the outputs.
            assert f = patterns(k).f
                report "bad F" severity error;
            --
            assert z = patterns(k).z
                report "bad Z" severity error;
            --
            assert ov = patterns(k).ov
                report "bad Ov" severity error;
            --
            assert co = patterns(k).co
                report "bad Co" severity error;
          
        end loop;
        
        assert false report "end of test" severity note;
        
      --  Wait forever; this will finish the simulation.
        wait;
      end process;
    end architecture testbench;