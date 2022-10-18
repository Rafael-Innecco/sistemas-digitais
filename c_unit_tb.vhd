-------------------------------------------------------
--! @file c_unit_tb.vhd
--! @brief Testbench para a unidade de controle do polistack
--! @author Rafael de A. Innecco
--! @date 2021-12-16
-------------------------------------------------------

--  A testbench has no ports.
entity c_unit_tb is
end entity c_unit_tb;
        

architecture testbench of generic_tb is
        
    --  Declaration of the component to be tested.
    component control_unit is
        port (
            clock, reset : in bit;
            pc_en, ir_en, sp_en,
            pc_src, mem_a_addr_src, mem_b_mem_src, alu_shfimm_src, alu_mem_src,
            mem_we, mem_enable : out bit;
            mem_b_addr_src, mem_b_wrd_src, alu_a_src, alu_b_src : out bit_vector (1 downto 0);
            alu_op : out bit_vector (2 downto 0);
            mem_busy : in bit;
            instruction : in bit_vector (7 downto 0);
            halted : out bit
        );
    end component;
    -- Declaration of signals
    signal clk, rst, pcen, iren, spen, pcsrc, aaddrsrc, bmemsrc, shfimmsrc, memsrc, we, menable, bsy, halt : bit;
    signal baddrsrc, bwrdsrc, aluasrc, alubsrc : bit_vector (1 downto 0);
    signal op : bit_vector (2 downto 0);
    signal instr : bit_vector (7 downto 0);

begin
    -- Component instantiation
    -- DUT = Device Under Test 
    DUT: entity work.control_unit(C_unit)
        port map (clk, rst, pcen, iren, spen, pcsrc, aaddrsrc, bmemsrc, shfimmsrc, memsrc, we, menable
                  baddrsrc, bwrdsrc, aluasrc, alubsrc, op, bsy, instr, halt);
    --

    clk: process is
    begin
      clk <= '0';
      wait for 0.5 ns;
      clk <= '1';
      wait for 0.5 ns;
    end process clk;  
    
    bsy: process is
    begin
        bsy <= '0';
        wait for 0.5 ns;
        bsy <= '1';
        wait for 0.5 ns;
    end process bsy;
    --  This process does the real job.
    stimulus_process: process is
        type pattern_type is record
            --  The inputs of the circuit.
            clock, reset : bit;
            pc_en, ir_en, sp_en,
            pc_src, mem_a_addr_src, mem_b_mem_src, alu_shfimm_src, alu_mem_src,
            mem_we, mem_enable : bit;
            mem_b_addr_src, mem_b_wrd_src, alu_a_src, alu_b_src : out bit_vector (1 downto 0);
            alu_op : bit_vector (2 downto 0);
            mem_busy : bit;
            instruction : bit_vector (7 downto 0);
            halted : bit
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