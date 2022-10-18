-------------------------------------------------------
--! @file d_register_tb.vhd
--! @brief Testbench para o D_register
--! @author Rafael de A. Innecco
--! @date 2021-11-11
-------------------------------------------------------

--  A testbench has no ports.
entity d_register_tb is
end entity d_register_tb;
    
architecture testbench of d_register_tb is

    --Declaration of components to be tested
    component d_register
        generic (
            width: natural := 4;
            reset_value: natural := 0
        );
        port (
            clock, reset, load: in bit;
            d: in bit_vector (width - 1 downto 0);
            q: out bit_vector (width - 1 downto 0)
        );
    end component d_register;

    --Declaration of signals
    signal width : natural := 4;
    signal clock, reset, load: bit;
    signal d, q: bit_vector (width - 1 downto 0);
    signal reset_value: natural := 0;

begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.d_register(t1) 
        generic map (width, reset_value)
        port map (clock, reset, load, d, q);
    -- Clock generator
    clk: process is
    begin
        clock <= '0';
        wait for 0.5 ns;
        clock <= '1';
        wait for 0.5 ns;
    end process clk;
    
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            d : bit_vector (width - 1 downto 0);
            load : bit;
            reset : bit;
            --  The expected outputs of the circuit.
            q : bit_vector(width - 1 downto 0);
        end record;

        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
             ("1011",'0','1',"0000"),
             ("1100",'1','0',"1100"),
             ("1100",'1','1',"0000"),
             ("0101",'0','1',"0000"),
             ("1001",'1','0',"1001"),
             ("1111",'0','0',"1001"),
             ("1101",'1','1',"0000"));

    begin
        --  Check each pattern.
        for k in patterns'range loop

            --  Set the inputs.
            d <= patterns(k).d;
            load <= patterns(k).load;
            reset <= patterns(k).reset;

            --  Wait for the results.
            wait for 1 ns;
      
            --  Check the outputs.
            assert q = patterns(k).q
            report "bad q" severity error;
        end loop;
    
        assert false report "end of test" severity note;
    
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;