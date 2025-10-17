library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity Top_reg is
  port (
    clk : in std_logic;
    btn : in  std_logic_vector(4  downto 0);
    sw  : in  std_logic_vector(15 downto 0);
    led : out std_logic_vector(15 downto 0);
    an  : out std_logic_vector(7  downto 0);
    cat : out std_logic_vector(6  downto 0)
  );
end entity Top_reg;

architecture behavioral of Top_reg is  

component reg_file is
port (
    clk : in std_logic;
    ra1 : in std_logic_vector (3 downto 0);
    ra2 : in std_logic_vector (3 downto 0);
    wa : in std_logic_vector (3 downto 0);
    wd : in std_logic_vector (31 downto 0);
    wen : in std_logic;
    rd1 : out std_logic_vector (31 downto 0);
    rd2 : out std_logic_vector (31 downto 0)
);
end component;

component mono_pulse_gen is
  port (
    clk    : in std_logic;
    btn    : in  std_logic_vector(4  downto 0);
    enable : out  std_logic_vector(4  downto 0)
  );
end component;

component SSD is
  port (
    clk : in std_logic;
    digits  : in  std_logic_vector(31 downto 0);
    an  : out std_logic_vector(7  downto 0);
    cat : out std_logic_vector(6  downto 0)
    
  );
end component;

signal s_digits: std_logic_vector(31 downto 0);
signal mpg_out: std_logic_vector(4 downto 0);
signal s_cnt: std_logic_vector(3 downto 0);
signal s_rd1: std_logic_vector(31 downto 0);
signal s_rd2: std_logic_vector(31 downto 0);

begin

SSD_instance : SSD port map(
clk => clk,
digits => s_digits,
an => an,
cat => cat
);

mono_pulse_gen_instance : mono_pulse_gen port map(
clk => clk,
btn => btn,
enable => mpg_out
);

reg_instance : reg_file port map(
    clk => clk,
    ra1 => s_cnt,
    ra2 => s_cnt,
    wa => s_cnt,
    wd => s_digits,
    wen => mpg_out(3),
    rd1 => s_rd1,
    rd2 => s_rd2
);

process(clk)
begin
    if mpg_out(2) = '1' then
        s_cnt <= x"0";
    else
        if rising_edge(clk)
        then
            if mpg_out(0) = '1'
            then
                s_cnt <= s_cnt + '1';
            end if;
        end if;
    end if;
end process;

led <= x"000" & s_cnt ;
s_digits <= s_rd1 + s_rd2;

end architecture behavioral; 