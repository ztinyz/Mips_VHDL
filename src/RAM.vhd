library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity ram is
port ( clk : in std_logic;
wen : in std_logic;
addr : in std_logic_vector(15 downto 0);
di : in std_logic_vector(15 downto 0);
do : out std_logic_vector(15 downto 0));
end ram;

architecture syn of ram is

type ram_type is array (0 to 255) of std_logic_vector (15 downto 0);
signal RAM: ram_type := (
0 => x"0001",
1 => x"0002",
2 => x"0003",
3 => x"0004",
others => (others => '0')
);

begin

process (clk)
begin
    if clk'event and clk = '1' then
        if wen = '1' then
            RAM(conv_integer(addr)) <= di;
        end if;
    end if;
    do <= RAM( conv_integer(addr)); 
end process;

end syn;