library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity instr_decode is
  port (
    -- inputs
    clk       : in  std_logic;
    instr     : in  std_logic_vector(15 downto 0);
    wd        : in  std_logic_vector(15 downto 0);
    -- control signal based inputs
    ext_op    : in  std_logic;
    reg_dst   : in  std_logic;
    reg_write : in  std_logic;
    -- outputs
    ext_imm   : out std_logic_vector(15 downto 0);
    func      : out std_logic_vector(2  downto 0);
    rd1       : out std_logic_vector(15 downto 0);
    rd2       : out std_logic_vector(15 downto 0);        
    sa        : out std_logic
  );
end instr_decode;

architecture behavioral of instr_decode is

  component reg_file
  port (
    clk : in  std_logic;
    ra1 : in  std_logic_vector(2  downto 0);
    ra2 : in  std_logic_vector(2  downto 0);
    wa  : in  std_logic_vector(2  downto 0);
    wd  : in  std_logic_vector(15 downto 0);
    wen : in  std_logic;
    rd1 : out std_logic_vector(15 downto 0);
    rd2 : out std_logic_vector(15 downto 0)
  );
  end component;

  -- *  
  -- NO OTHER EXTERNAL COMPONENT DECLARATION NECESSARY
  -- ADDITIONAL SIGNALS HERE
    signal s_wa : std_logic_vector( 2 downto 0);
begin

  s_wa <= instr(6 downto 4) when reg_dst = '0' else instr(9 downto 7);
  
  inst_rf : reg_file
  port map (
    clk => clk,
    ra1 => instr(12 downto 10),
    ra2 => instr(9 downto 7),
    wa  => s_wa,
    wd  => wd,
    wen => reg_write,
    rd1 => rd1,
    rd2 => rd2 
  );

  -- **  
  -- NO OTHER EXTERNAL COMPONENT INSTANTIATION NECESSARY
  -- ADDITIONAL COMPONENT IMPLEMENTATION HERE
    sa <= instr(3);
    func <= instr(2 downto 0);
    ext_imm <= x"00" & '0' & instr(6 downto 0) when ext_op = '0' else (x"FF" & '1' & instr(6 downto 0) when instr(6) = '1' else x"00" & '0' & instr(6 downto 0));
    
end behavioral;