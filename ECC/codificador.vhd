-------------------------------------------------------
--! @file codificador.vhd
--! @brief Codificador para memória ecc
--! @author Rafael de A. Innecco
--! @date 2022-07-08
-------------------------------------------------------

entity secded_enc16 is
    port (
    u_data: in bit_vector(15 downto 0);
    mem_data: out bit_vector(21 downto 0)
    );
end entity;

architecture t1 of secded_enc16 is
    signal P0, P1, P2, P3, P4, P5 : bit;
begin
    P0 <= u_data(15) xor u_data(13) xor u_data(11) xor u_data(10) xor u_data(8) xor u_data(6) xor u_data(4) xor u_data(3) xor u_data(1) xor u_data(0);
    P1 <= u_data(13) xor u_data(12) xor u_data(10) xor u_data(9) xor u_data(6) xor u_data(5) xor u_data(3) xor u_data(2) xor u_data(0);
    P2 <= u_data(15) xor u_data(14) xor u_data(10) xor u_data(9) xor u_data(8) xor u_data(7) xor u_data(3) xor u_data(2) xor u_data(1);
    P3 <= u_data(10) xor u_data(9) xor u_data(8) xor u_data(7) xor u_data(6) xor u_data(5) xor u_data(4);
    P4 <= u_data(15) xor u_data(14) xor u_data(13) xor u_data(12) xor u_data(11);

    P5 <= u_data(14) xor u_data(12) xor P4 xor u_data(9) xor u_data(7) xor u_data(5) xor P3 xor u_data(2) xor P2 xor P1;

    mem_data(21) <= P5;
    mem_data(15) <= P4;
    mem_data(7) <= P3;
    mem_data(3) <= P2;
    mem_data(1) <= P1;
    mem_data(0) <= P0;

    mem_data(20 downto 16) <= u_data(15 downto 11);
    mem_data(14 downto 8) <= u_data(10 downto 4);
    mem_data(6 downto 4) <= u_data(3 downto 1);
    mem_data(2) <= u_data(0);
end architecture t1; 