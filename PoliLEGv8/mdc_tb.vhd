library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity special_ram is
    port (
        ck : in bit;
        wr : in bit;
        addr : in bit_vector (2 downto 0);
        data_i : in bit_vector (63 downto 0);
        data_o : out bit_vector (63 downto 0);
        result : out bit_vector (63 downto 0)
    );
end special_ram;

architecture arch_ram of special_ram is
    type mem_tipo is array (0 to 7) of bit_vector (63 downto 0);

    impure function inicializa_mem (file_name: in string) return mem_tipo is
        file arquivo : text open read_mode is file_name;
        variable linha : line;
        variable temp_bitvec : bit_vector (63 downto 0);
        variable mem_temp : mem_tipo;
    begin
        for i in mem_tipo'range loop
            readline(arquivo, linha);
            read(linha, temp_bitvec);
            mem_temp(i) := temp_bitvec;
        end loop;
        return mem_temp;
    end;

    signal mem : mem_tipo := inicializa_mem("ram_mdc.dat");
begin
    data_o <= mem(to_integer(unsigned(addr)));

    result <= mem(0);

    WRT: process (ck) is
    begin
        if (ck) = '1' and wr = '1' then
            mem(to_integer(unsigned(addr))) <= data_i;
        end if;
    end process WRT;
end architecture arch_ram;

library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.floor;

entity mdc_tb is
end entity;

architecture behavioral of mdc_tb is
	component polilegsc is port(
		clock, reset    : in bit;
		dmem_addr       : out bit_vector(63 downto 0);
		dmem_dati       : out bit_vector(63 downto 0);
		dmem_dato       : in  bit_vector(63 downto 0);
		dmem_we         : out bit;
		imem_addr       : out bit_vector(63 downto 0);
		imem_data       : in  bit_vector(31 downto 0));
	end component;

	component rom is
		port (
			addr : in bit_vector(7 downto 0);
			data : out bit_vector(31 downto 0)
        );
	end component;

	component special_ram is
        port (
            ck      : in bit;
            wr      : in bit;
            addr    : in bit_vector (2 downto 0);
            data_i  : in bit_vector (63 downto 0);
            data_o  : out bit_vector (63 downto 0);
            result  : out bit_vector (63 downto 0)
        );
    end component special_ram;

	signal rom_data: bit_vector(31 downto 0);
	signal rom_addr, ram_addr, ram_input, ram_output: bit_vector(63 downto 0);
	signal ram_write: bit;
	constant PERIOD : time := 1 ns;
	signal finished: boolean := false;
	signal clock, reset: bit:='0';
    signal result : bit_vector(63 downto 0);
    signal waiter   : bit := '0';

	begin
		clock <= not clock after PERIOD/2 when not finished else '0';

		theROM: rom
			port map (
				rom_addr(7 downto 0),
				rom_data
            );
        --

		theRAM: special_ram
			port map (
				clock,
				ram_write,
				ram_addr(5 downto 3),
				ram_input,
				ram_output,
                result
            );
        --

		theCPU: polilegsc port map (
			clock,
			reset,
			ram_addr,
			ram_input,
			ram_output,
			ram_write,
			rom_addr,
			rom_data);

		main:process
		begin
			report "Begin test";

			finished <= false;
			reset <= '1';
			wait until clock'event and clock='1';
			wait until clock'event and clock='0';
			reset <= '0';
			wait on result;
			assert to_integer(unsigned(ram_input)) = 19 report "Bad Result" severity error;
			wait for 20 ns;
			finished <= true;
            
			report "End Test";
			wait;
		end process;
end architecture behavioral;
