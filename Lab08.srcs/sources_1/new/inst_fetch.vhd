library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity inst_fetch is
  port (
    -- inputs
    clk                   : in  std_logic;
    branch_target_address : in  std_logic_vector(15 downto 0);
    jump_address          : in  std_logic_vector(15 downto 0);
    pc_en                 : in  std_logic;
    pc_reset              : in  std_logic;
    -- control signal based inputs
    jump                  : in  std_logic;
    pc_src                : in  std_logic;
    -- outputs
    instruction           : out std_logic_vector(15 downto 0);
    pc_plus_one           : out std_logic_vector(15 downto 0)
  );
end inst_fetch;

architecture behavioral of inst_fetch is

  type t_rom is array (0 to 255) of std_logic_vector(15 downto 0);
  signal s_rom : t_rom := (
  --  opc rs  rt  rd sa func
  -- r type instructions
    b"000_001_010_011_0_000", -- #0 x"0530" add $3 <= $1 + $2
    b"000_110_100_010_0_001", -- #1 x"1a21" sub $2 <= $6 - $4
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_001_010_011_1_010", -- #2 x"0532" sll $3 <= $1 << 1
    b"000_110_100_010_1_011", -- #3 x"1a23" srl $2 <= $4 >> 1 
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_001_010_011_0_100", -- #4 x"0534" and $3 <= $1 & $2
    b"000_110_100_010_0_101", -- #5 x"1a25" or $2 <= $6 | $4
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_001_010_011_0_110", -- #6 x"0536" xor $3 <= $1 ^ $2
    b"000_110_100_010_1_111", -- #7 x"1a27" sra $2 <= $4 >>> 2
    -- i type instructions
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"001_001_010_011_0_100", -- #0 x"2534" addi $2 <= $1 + imm
    b"010_110_100_010_0_101", -- #1 x"5a25" lw $4 <= mem[$6 + imm]
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"011_001_010_011_0_110", -- #2 x"6536" sw $2 <= mem[$1 + imm] 
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"000_000_000_000_0_000",
    b"100_001_010_011_0_111", -- #3 x"8537" beq if $2 == $1 go to imm else pc + 1
    b"101_001_010_011_0_000", -- #4 x"a530" slti if $1 < imm $2 <= 1 pc + 1 else $t <= 0 pc + 1
    b"110_001_010_011_0_001", -- #5 x"c531" xori $2 <= $1 ^ imm pc + 1
    -- jump instructions
    b"111_000_000_000_0_001", -- #6 x"E001" pc <= imm
    others => (others => '1')
  );
  
  -- *  
  -- NO OTHER EXTERNAL COMPONENT DECLARATION NECESSARY
  -- ADDITIONAL SIGNALS HERE
  
  signal s_mux_jump_out : std_logic_vector ( 15 downto 0);
  signal s_mux_branch_out : std_logic_vector ( 15 downto 0);
  signal s_adder_out : std_logic_vector ( 15 downto 0);
  signal s_pc_out : std_logic_vector ( 15 downto 0);
  signal s_data : std_logic_vector ( 15 downto 0);
begin

  -- **  
  -- NO OTHER EXTERNAL COMPONENT INSTANTIATION NECESSARY
  -- ADDITIONAL COMPONENT IMPLEMENTATION HERE
    
    process(clk)
    begin
    if (rising_edge(clk)) then
        if pc_reset = '1' then
            s_pc_out <= x"0000";
        else
            if pc_en = '1' then
                s_pc_out <= s_mux_jump_out;
            end if;
        end if;
    end if;
    end process;
    
    process (clk)
    begin
    if rising_edge(clk) then
        s_data <= s_rom(conv_integer(s_pc_out(7 downto 0)));
    end if;
    end process;
    
    s_adder_out <= s_pc_out + '1';
    s_mux_branch_out <= branch_target_address when pc_src = '1' else s_adder_out;
    s_mux_jump_out <= jump_address when jump = '1' else s_mux_branch_out;
    
    instruction <= s_data;
    pc_plus_one <= s_adder_out;
end behavioral;