entity mux_2 is
    generic (
        word_s  : natural := 8
    );
    port (
        i0, i1  : in bit_vector (word_s - 1 downto 0);
        o       : out bit_vector (word_s - 1 downto 0);
        sel     : in bit
    );
end mux_2;

architecture arch1 of mux_2 is
begin
    o <= i1 when sel = '1' else i0;
end architecture arch1;

entity mux_4 is
    generic (
        word_s  : natural := 8
    );
    port (
        i0, i1, i2, i3  : in bit_vector (word_s - 1 downto 0);
        o               : out bit_vector (word_s - 1 downto 0);
        sel             : in bit_vector (2 downto 0)
    );
end mux_4;

architecture arch1 of mux_4 is
begin
    o <=    i3 when sel = "11" else
            i2 when sel = "10" else
            i1 when sel = "01" else
            i0;
end architecture arch1;