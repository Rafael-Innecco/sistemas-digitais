-------------------------------------------------------
--! @file polileg_tb.vhd
--! @brief Testbench para o PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-06-23
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

--  A testbench has no ports.
entity polileg_tb is
end entity polileg_tb;
        

architecture testbench of polileg_tb is
        
    --  Declaration of the component to be tested.
    component polilegsc is
        port (
            clock, reset: in bit;
            -- Data Memory
            dmem_addr   : out bit_vector (63 downto 0);
            dmem_dati   : out bit_vector (63 downto 0);
            dmem_dato   : in bit_vector (63 downto 0);
            dmem_we     : out bit;
            -- Instruction Memory
            imem_addr   : out bit_vector (63 downto 0);
            imem_data   : in bit_vector (31 downto 0)
        );
    end component polilegsc;

    -- Declaration of signals
    signal clock, reset, dmem_we : bit;
    signal dmem_addr, dmem_dati, dmem_dato, imem_addr   : bit_vector (63 downto 0);
    signal imem_data    : bit_vector (31 downto 0);
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.polilegsc(pleg)
        port map (
            clock, reset, dmem_addr,
            dmem_dati, dmem_dato, dmem_we,
            imem_addr, imem_data
        );
    --

    CLK: process is
    begin
        clock <= '1';
        wait for 0.5 ns;
        clock <= '0';
        wait for 0.5 ns;
    end process CLK;

    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            reset       : bit;
            imem_data   : bit_vector (31 downto 0);
            dmem_dato   : bit_vector (63 downto 0);
            --  The expected outputs of the circuit.
            imem_addr   : bit_vector (63 downto 0);
            dmem_addr   : bit_vector (63 downto 0);
            dmem_dati   : bit_vector (63 downto 0);
            dmem_we     : bit;
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                (
                    '1', "10001011000" & "11111" & "000000" & "11111" & "11111", 
                    bit_vector(to_signed(37, 64)), bit_vector(to_unsigned(0, 64)),
                    bit_vector(to_signed(0, 64)), bit_vector(to_signed(0, 64)), '0'
                ),
                -- LDUR X9, [XZR, #0]
                (
                    '0', "11111000010" & bit_vector(to_signed(0, 9)) & "00" & "11111" & "01001",
                    bit_vector(to_signed(37, 64)), bit_vector(to_unsigned(4, 64)),
                    bit_vector(to_signed(0, 64)), bit_vector(to_signed(0, 64)), '0'
                ),
                -- LDUR X10, [XZR, #8]
                (
                    '0', "11111000010" & bit_vector(to_signed(8, 9)) & "00" & "11111" & "01010",
                    bit_vector(to_signed(15, 64)), bit_vector(to_unsigned(8, 64)),
                    bit_vector(to_signed(8, 64)), bit_vector(to_signed(0, 64)), '0'
                ),
                -- ADD X11, X10, X9
                (
                    '0', "10001011000010010000000101001011",
                    bit_vector(to_signed(-334, 64)), bit_vector(to_unsigned(12, 64)),
                    bit_vector(to_signed(52, 64)), bit_vector(to_signed(37, 64)), '0'
                ),
                -- SUB X12, X9, X10
                (
                    '0', "11001011000010100000000100101100",
                    bit_vector(to_signed(22, 64)), bit_vector(to_unsigned(16, 64)),
                    bit_vector(to_signed(22, 64)), bit_vector(to_signed(15, 64)), '0'
                ),
                -- AND X13, X11, X12
                (
                    '0', "10001010000011000000000101101101",
                    bit_vector(to_signed(33, 64)), bit_vector(to_unsigned(20, 64)),
                    bit_vector(to_signed(22, 64)) and bit_vector(to_signed(52, 64)),
                    bit_vector(to_signed(22, 64)), '0'
                ),
                -- ORR X13, X13, X9
                (
                    '0', "10101010000010010000000110101101",
                    bit_vector(to_signed(21, 64)), bit_vector(to_unsigned(24, 64)),
                    (bit_vector(to_signed(22, 64)) and bit_vector(to_signed(52, 64))) or bit_vector(to_signed(37, 64)),
                    bit_vector(to_signed(37, 64)), '0'
                ),
                -- B 100
                (
                    '0', "000101" & bit_vector(to_signed(100, 26)),
                    bit_vector(to_signed(0, 64)), bit_vector(to_unsigned(28, 64)),
                    bit_vector(to_signed(0, 64)), bit_vector(to_signed(0, 64)), '0'
                ),
                -- CBZ XZR, #2
                (
                    '0', "10110100" & bit_vector(to_signed(2, 14)) & "1111111111",
                    bit_vector(to_signed(37, 64)), bit_vector(to_unsigned(428, 64)),
                    bit_vector(to_signed(0, 64)), bit_vector(to_signed(0, 64)), '0'
                ),
                -- STUR X13, [XZR, #16]
                (
                    '0', "11111000000" & bit_vector(to_signed(16, 9)) & "00" & "11111" & "01101",
                    bit_vector(to_signed(0, 64)), bit_vector(to_unsigned(436, 64)),
                    bit_vector(to_signed(16, 64)), (bit_vector(to_signed(22, 64)) and bit_vector(to_signed(52, 64))) or bit_vector(to_signed(37, 64)), '1'
                )
            );
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.
            reset <= patterns(k).reset;
            imem_data <= patterns(k).imem_data;
            dmem_dato <= patterns(k).dmem_dato;
            --  Wait for the results.
            wait for 1 ns;
            --  Check the outputs.
            assert imem_addr = patterns(k).imem_addr
                report "Bad imem_addr" severity error;
            assert dmem_addr = patterns(k).dmem_addr
                report "Bad dmem_addr" severity error;
            assert dmem_dati = patterns(k).dmem_dati
                report "Bad dmem_dati" severity error;
            assert dmem_we = patterns(k).dmem_we
                report "Bad dmem_we" severity error;
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;