-------------------------------------------------------
--! @file controlunit_tb.vhd
--! @brief Testbench para a unidade de controle do PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-06-20
-------------------------------------------------------

--  A testbench has no ports.
entity controlunit_tb is
end entity controlunit_tb;
        

architecture testbench of controlunit_tb is
        
    --  Declaration of the component to be tested.
    component controlunit is
        port (
            --To Datapath
            reg2loc     : out bit;
            uncondBranch: out bit;
            branch      : out bit;
            memRead     : out bit;
            memToreg    : out bit;
            aluOp       : out bit_vector (1 downto 0);
            memWrite    : out bit;
            aluSrc      : out bit;
            regWrite    : out bit;
            --From Datapath
            opcode      : in bit_vector (10 downto 0)
        );
    end component controlunit;
    -- Declaration of signals
    signal  reg2loc, uncondBranch, branch, memRead : bit;
    signal memToReg, memWrite, aluSrc, regWrite : bit;
    signal aluOp : bit_vector (1 downto 0);
    signal opcode : bit_vector (10 downto 0);
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.controlunit(behavioral)
        port map (
            reg2loc, uncondBranch, branch, memRead,
            memToReg, aluOp, memWrite, aluSrc, regWrite,
            opcode
        );
    --

    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            opcode : bit_vector (10 downto 0);
            --  The expected outputs of the circuit.
            reg2loc, uncondBranch, branch, memRead : bit;
            memToReg, memWrite, aluSrc, regWrite : bit;
            aluOp : bit_vector (1 downto 0);
        end record;
        
        --  The patterns to apply.
        type pattern_array is array (natural range <>) of pattern_type;
        constant patterns : pattern_array :=
            (
                ("11111000010", '1', '0', '0', '1', '1', '0', '1', '1', "00"),
                ("11111000000", '1', '0', '0', '0', '1', '1', '1', '0', "00"),
                ("10001011000", '0', '0', '0', '0', '0', '0', '0', '1', "10"),
                ("11001011000", '0', '0', '0', '0', '0', '0', '0', '1', "10"),
                ("10101010000", '0', '0', '0', '0', '0', '0', '0', '1', "10"),
                ("10001010000", '0', '0', '0', '0', '0', '0', '0', '1', "10"),
                ("10110100011", '1', '0', '1', '0', '1', '0', '0', '0', "01"),
                ("00010110010", '1', '1', '0', '0', '1', '0', '0', '0', "00")
            );
        
    begin
        --  Check each pattern.
        for k in patterns'range loop
        
            --  Set the inputs.
            opcode <= patterns(k).opcode;
            --  Wait for the results.
            wait for 10 ns;

            --  Check the outputs.
            assert reg2loc = patterns(k).reg2loc
                report "Bad reg2loc" severity error;
            assert uncondBranch = patterns(k).uncondBranch
                report "Bad uncondBranch" severity error;
            assert branch = patterns(k).branch
                report "Bad branch" severity error;
            assert memRead = patterns(k).memRead
                report "Bad memRead" severity error;
            assert memToReg = patterns(k).memToReg
                report "Bad memToReg" severity error;
            assert memWrite = patterns(k).memWrite
                report "Bad memWrite" severity error;
            assert aluSrc = patterns(k).aluSrc
                report "Bad aluSrc" severity error;
            assert regWrite = patterns(k).regWrite
                report "Bad regWrite" severity error;
            assert aluOp = patterns(k).aluOp
                report "Bad aluOp" severity error;
        end loop;
            
        assert false report "end of test" severity note;
            
        --  Wait forever; this will finish the simulation.
        wait;
    end process;
end architecture testbench;