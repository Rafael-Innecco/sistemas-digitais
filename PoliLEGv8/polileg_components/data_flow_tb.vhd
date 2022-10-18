-------------------------------------------------------
--! @file data_flow_tb.vhd
--! @brief Testbench para o fluxo de dados do PoliLEGv8
--! @author Rafael de A. Innecco
--! @date 2022-06-20
-------------------------------------------------------

--  A testbench has no ports.
entity data_flow_tb is
end entity data_flow_tb;
        

architecture testbench of data_flow_tb is
        
    --  Declaration of the component to be tested.
    component datapath is
        port (
            --Common
            clock   : in bit;
            reset   : in bit;
            --From Control Unit
            reg2loc : in bit;
            pcsrc   : in bit;
            memToReg: in bit;
            aluCtrl : in bit_vector (3 downto 0);
            aluSrc  : in bit;
            regWrite: in bit;
            --To Control Unit
            opcode  : out bit_vector (10 downto 0);
            zero    : out bit;
            --Instruction Memory interface
            imAddr  : out bit_vector (63 downto 0);
            imOut   : in bit_vector (31 downto 0);
            --Data Memory Interface
            dmAddr  : out bit_vector (63 downto 0);
            dmIn    : out bit_vector (63 downto 0);
            dmOut   : in bit_vector (63 downto 0)
        );
     end component datapath;

    -- Declaration of signals
    signal clock, reset : bit;
    signal reg2loc, pcsrc, memToReg : bit;
    signal aluCtrl : bit_vector (3 downto 0);
    signal aluSrc, regWrite : bit;
    signal opcode : bit_vector (10 downto 0);
    signal  zero  : bit;
    signal imAddr : bit_vector (63 downto 0);
    signal imOut : bit_vector (31 downto 0);
    signal dmAddr, dmIn : bit_vector (63 downto 0);
    signal dmOut : bit_vector (63 downto 0);
begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.datapath(data_flow)
        port map (
            clock, reset,
            reg2loc, pcsrc, memToReg, aluCtrl, aluSrc, regWrite
            opcode, zero,
            imAddr, imOut,
            dmAddr, dmIn, dmOut
        );
    --

    --Auxiliary Components
    IM: entity work.rom(arch_rom)
        generic map (64, 32, "dfIm.dat")
        port map (imAddr, imOut);
    --
    
    --Clock generator
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