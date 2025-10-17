library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity reg_file is
port (
    clk : in std_logic;
    ra1 : in std_logic_vector (2 downto 0);
    ra2 : in std_logic_vector (2 downto 0);
    wa : in std_logic_vector (2 downto 0);
    wd : in std_logic_vector (15 downto 0);
    wen : in std_logic;
    rd1 : out std_logic_vector (15 downto 0);
    rd2 : out std_logic_vector (15 downto 0)
);
end reg_file;

architecture Behavioral of reg_file is


signal wa_signal: std_logic_vector(2 downto 0);
signal wa_waiter: std_logic_vector(1 downto 0);
type reg_array is array (0 to 15) of std_logic_vector(15 downto 0);

signal reg_file : reg_array := (x"0001",
                                x"0002",
                                x"0003",
                                x"0004",
                                x"0005",
                                x"0006",
                                x"0007",
                                x"0008",
                                x"0009",
                                others => (others => '0')
                                );

    begin
    process(clk)
    begin
        if rising_edge(clk)then
            wa_waiter <= wa_waiter + '1';
        end if;
        if wa_waiter = "11" then
            wa_signal <= wa;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if wen = '1' then
                reg_file(conv_integer(wa_signal)) <= wd;
            end if;
        end if;
    end process;
    rd1 <= reg_file(conv_integer(ra1));
    rd2 <= reg_file(conv_integer(ra2));
end Behavioral;