library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity Top_dec is
  port (
    clk : in  std_logic;
    btn : in  std_logic_vector(4  downto 0);
    sw  : in  std_logic_vector(15 downto 0);
    led : out std_logic_vector(15 downto 0);
    an  : out std_logic_vector(7  downto 0);
    cat : out std_logic_vector(6  downto 0)
  );
end entity Top_dec;

architecture behavioral of Top_dec is  

    component SSD is
      port (
        clk : in std_logic;
        digits  : in  std_logic_vector(31 downto 0);
        an  : out std_logic_vector(7  downto 0);
        cat : out std_logic_vector(6  downto 0)
        
      );
    end component;

  component instr_decode
  port (
    clk       : in  std_logic;
    instr     : in  std_logic_vector(15 downto 0);
    wd        : in  std_logic_vector(15 downto 0);
    ext_op    : in  std_logic;
    reg_dst   : in  std_logic;
    reg_write : in  std_logic;
    ext_imm   : out std_logic_vector(15 downto 0);
    func      : out std_logic_vector(2  downto 0);
    rd1       : out std_logic_vector(15 downto 0);
    rd2       : out std_logic_vector(15 downto 0);
    sa        : out std_logic
  );
  end component;

  -- additional signals and component declarations
  
    component control_unit
  port (
    op_code    : in std_logic_vector(2 downto 0);
    reg_dst    : out std_logic;
    ext_op     : out std_logic;
    alu_src    : out std_logic;
    branch     : out std_logic;
    jump       : out std_logic;
    alu_op     : out std_logic_vector(2 downto 0);
    mem_write  : out std_logic;
    mem_to_reg : out std_logic;
    reg_write  : out std_logic
  );
  end component;

 component inst_fetch
  port (
    clk                   : in  std_logic;
    branch_target_address : in  std_logic_vector(15 downto 0);
    jump_address          : in  std_logic_vector(15 downto 0);
    jump                  : in  std_logic;
    pc_src                : in  std_logic;
    pc_en                 : in  std_logic;
    pc_reset              : in  std_logic;
    instruction           : out std_logic_vector(15 downto 0);
    pc_plus_one           : out std_logic_vector(15 downto 0)
  );
  end component;
  
  component mono_pulse_gen is
  port (
    clk : in  std_logic;
    btn : in  std_logic_vector(4  downto 0);
    enable : out std_logic_vector(4 downto 0)
  );
  end component;

  component exec_unit
  port (
    ext_imm     : in  std_logic_vector(15 downto 0);
    func        : in  std_logic_vector(2  downto 0);
    rd1         : in  std_logic_vector(15 downto 0);
    rd2         : in  std_logic_vector(15 downto 0);
    pc_plus_one : in  std_logic_vector(15 downto 0);
    sa          : in  std_logic;
    alu_op      : in  std_logic_vector(2  downto 0);
    alu_src     : in  std_logic;
    alu_res     : out std_logic_vector(15 downto 0);
    bta         : out std_logic_vector(15 downto 0);
    zero        : out std_logic
  );
  end component;

component mem_unit is
  port (
    -- inputs
    clk         : in std_logic;
    alu_res_in  : in std_logic_vector(15 downto 0);
    rd2         : in std_logic_vector(15 downto 0);        
    -- control signals
    mem_write   : in  std_logic;
    -- outputs
    alu_res_out : out std_logic_vector(15 downto 0);
    mem_data    : out std_logic_vector(15 downto 0)
  );
end component;

    signal s_if_out_instruction: std_logic_vector(15 downto 0);
    signal s_ctrl_reg_dst: std_logic;
    signal s_ctrl_ext_op: std_logic;
    signal s_ctrl_alu_src: std_logic;
    signal s_ctrl_branch: std_logic;
    signal s_ctrl_jump: std_logic;
    signal s_ctrl_alu_op: std_logic_vector(2 downto 0);
    signal s_ctrl_mem_write: std_logic;
    signal s_ctrl_mem_to_reg: std_logic;
    signal s_ctrl_reg_write: std_logic;
    
    signal s_id_in_wd: std_logic_vector(15 downto 0);
    signal s_id_in_reg_write: std_logic;
    signal s_id_out_ext_imm: std_logic_vector(15 downto 0);
    signal s_id_out_func: std_logic_vector(2  downto 0);
    signal s_id_out_rd1: std_logic_vector(15 downto 0);
    signal s_id_out_rd2: std_logic_vector(15 downto 0);
    signal s_id_out_sa: std_logic;
    
    signal s_if_out_pc_plus_one: std_logic_vector(15 downto 0);
    signal s_digits_upper: std_logic_vector(15 downto 0);
    signal s_digits_lower: std_logic_vector(15 downto 0);
    
    signal s_mpg_out : std_logic_vector(4 downto 0);
    signal s_digits: std_logic_vector(31 downto 0);
    signal s_mu_out_mem_data: std_logic_vector(15 downto 0);
    signal s_wb_out_wd: std_logic_vector(15 downto 0);
    
    -- Execution Unit
      signal s_eu_out_alu_res : std_logic_vector(15 downto 0) := x"0000";
      signal s_eu_out_bta     : std_logic_vector(15 downto 0) := x"0000";
      signal s_eu_out_zero    : std_logic                     := '0';
      
    -- Mem unit
    signal s_mem_out_alu_res : std_logic_vector(15 downto 0) := x"0000";
    signal s_mem_out_mem_data : std_logic_vector(15 downto 0) := x"0000";
    
    -- int reg
    signal s_intreg1_pc_plus_one: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg1_instruction: std_logic_vector(15 downto 0):= x"0000";

    signal s_intreg2_m: std_logic_vector(1 downto 0):= "00";
    signal s_intreg2_wb: std_logic_vector(1 downto 0):= "00";
    signal s_intreg2_ex: std_logic_vector(3 downto 0):= "0000";
    signal s_intreg2_pc_plus_one: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg2_out_rd1: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg2_out_rd2: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg2_out_ext_imm: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg2_out_func: std_logic_vector(2 downto 0):= "000";
    signal s_intreg2_out_s_wa: std_logic_vector(2 downto 0):= "000";
    signal s_intreg2_out_sa: std_logic:= '0';
    
    signal s_intreg3_m: std_logic_vector(1 downto 0):= "00";
    signal s_intreg3_wb: std_logic_vector(1 downto 0):= "00";
    signal s_intreg3_bta: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg3_alu_res: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg3_zero: std_logic:= '0';
    signal s_intreg3_rd2: std_logic_vector(15 downto 0):= x"0000";
    
    signal s_intreg4_wb: std_logic_vector(1 downto 0):= "00";
    signal s_intreg4_alu_res: std_logic_vector(15 downto 0):= x"0000";
    signal s_intreg4_mem_data: std_logic_vector(15 downto 0):= x"0000";
    
    signal s_mux_enable: std_logic;
begin

  -- previous component instantiations / implementation

   mono_instance : mono_pulse_gen
   port map (
    clk => clk,
    btn => btn,
    enable => s_mpg_out
   );

    SSD_instance: SSD
    port map(
    clk => clk,
    digits  => s_digits,
    an  => an,
    cat => cat
    );

  inst_cu : control_unit
  port map (
    op_code    => s_intreg1_instruction(15 downto 13),
    reg_dst    => s_ctrl_reg_dst,
    ext_op     => s_ctrl_ext_op,
    alu_src    => s_ctrl_alu_src,
    branch     => s_ctrl_branch,
    jump       => s_ctrl_jump,
    alu_op     => s_ctrl_alu_op,
    mem_write  => s_ctrl_mem_write,
    mem_to_reg => s_ctrl_mem_to_reg,
    reg_write  => s_ctrl_reg_write
  );

  inst_indcd : instr_decode
  port map (
    clk       => clk,
    instr     => s_intreg1_instruction,
    wd        => s_id_in_wd,
    ext_op    => s_ctrl_ext_op,
    reg_dst   => s_ctrl_reg_dst,
    reg_write => s_intreg4_wb(0),
    ext_imm   => s_id_out_ext_imm,
    func      => s_id_out_func,
    rd1       => s_id_out_rd1,
    rd2       => s_id_out_rd2,
    sa        => s_id_out_sa
  );
  
    inst_infe : inst_fetch
  port map (
    clk                    => clk,
    branch_target_address  => s_eu_out_alu_res,
    jump_address           => s_id_out_ext_imm,
    jump                   => sw(0),
    pc_src                 => sw(1),
    pc_en                  => s_mpg_out(0),
    pc_reset               => s_mpg_out(1),
    instruction            => s_if_out_instruction,
    pc_plus_one            => s_if_out_pc_plus_one
  );
  
    exec_unit_inst : exec_unit
  port map (
    ext_imm     => s_intreg2_out_ext_imm,
    func        => s_intreg2_out_func,
    rd1         => s_intreg2_out_rd1,
    rd2         => s_intreg2_out_rd2,
    pc_plus_one => s_intreg2_pc_plus_one,
    sa          => s_intreg2_out_sa,
    alu_op      => s_intreg2_ex(3 downto 1),
    alu_src     => s_intreg2_ex(0),
    alu_res     => s_eu_out_alu_res,
    bta         => s_eu_out_bta,
    zero        => s_eu_out_zero
  );
  
  mem_unit_inst : mem_unit
  port map (
    clk      => clk,
    alu_res_in =>s_intreg3_alu_res,
    rd2        =>s_intreg3_rd2,
    mem_write  =>s_intreg3_m(1),
    alu_res_out=>s_mem_out_alu_res,
    mem_data   =>s_mem_out_mem_data
  );
  
  process(clk) -- first intermediary reg 
  begin
      if rising_edge(clk) then
        if(s_mpg_out(0) = '1') then
          s_intreg1_pc_plus_one <= s_if_out_pc_plus_one;
          s_intreg1_instruction <= s_if_out_instruction;
        end if;
      end if;
  end process;
  
  process(clk) -- second intermediary reg
  begin
      if rising_edge(clk) then
          if(s_mpg_out(0) = '1') then
              s_intreg2_m <= s_ctrl_mem_write & s_ctrl_branch;
              s_intreg2_wb <= s_ctrl_mem_to_reg & s_ctrl_reg_write;
              s_intreg2_ex <= s_ctrl_alu_op & s_ctrl_alu_src;
              s_intreg2_pc_plus_one <= s_intreg1_pc_plus_one;
              s_intreg2_out_rd1 <= s_id_out_rd1;
              s_intreg2_out_rd2 <= s_id_out_rd2;
              s_intreg2_out_ext_imm <= s_id_out_ext_imm;
              s_intreg2_out_func <= s_id_out_func;
              s_intreg2_out_sa <= s_id_out_sa;
          end if;
      end if;
  end process;
  
  process(clk) -- third intermediary reg
  begin
    if(rising_edge(clk)) then
        if(s_mpg_out(0) = '1') then
            s_intreg3_wb <= s_intreg2_wb;
            s_intreg3_m <= s_intreg3_m;
            s_intreg3_bta <= s_eu_out_bta;
            s_intreg3_alu_res <= s_eu_out_alu_res;
            s_intreg3_zero <= s_eu_out_zero;
            s_intreg3_rd2 <= s_intreg2_out_rd2;
        end if;
    end if;
  end process;
  
  process(clk) -- forth intermediary reg
  begin
    if(rising_edge(clk))then
        if(s_mpg_out(0) = '1') then
            s_intreg4_wb <= s_intreg3_wb;
            s_intreg4_alu_res <= s_mem_out_alu_res;
            s_intreg4_mem_data <= s_mem_out_mem_data;
        end if;
    end if;
  end process;

  -- Writeback 
   s_id_in_wd <= s_intreg4_mem_data when s_intreg4_wb(1) = '1' else s_intreg4_alu_res;
  
  -- MUX for 7-segment display left side (31 downto 16)
  process (sw(11 downto 9), s_if_out_pc_plus_one, s_if_out_instruction, s_id_out_rd1, s_id_out_rd2, s_id_in_wd)
  begin
    case sw(11 downto 9) is
      when "000"  => s_digits_upper <= s_if_out_instruction;
      when "001"  => s_digits_upper <= s_if_out_pc_plus_one;
      when "010"  => s_digits_upper <= s_id_out_rd1;
      when "011"  => s_digits_upper <= s_id_out_rd2;
      when "100"  => s_digits_upper <= s_id_out_ext_imm;
      when "101"  => s_digits_upper <= s_eu_out_alu_res;
      when "110"  => s_digits_upper <= s_mu_out_mem_data;
      when "111"  => s_digits_upper <= s_wb_out_wd;
    end case;
  end process;

  -- MUX for 7-segment display right side (15 downto 0)
  process (sw(6 downto 4), s_if_out_pc_plus_one, s_if_out_instruction, s_id_out_rd1, s_id_out_rd2, s_id_in_wd)
  begin
    case sw(6 downto 4) is
      when "000"  => s_digits_lower <= s_if_out_instruction;
      when "001"  => s_digits_lower <= s_if_out_pc_plus_one;
      when "010"  => s_digits_lower <= s_id_out_rd1;
      when "011"  => s_digits_lower <= s_id_out_rd2;
      when "100"  => s_digits_lower <= s_id_out_ext_imm;
      when "101"  => s_digits_lower <= s_eu_out_alu_res;
      when "110"  => s_digits_lower <= s_mu_out_mem_data;
      when "111"  => s_digits_lower <= s_wb_out_wd;
    end case;
  end process;
  
  s_digits <= s_digits_upper & s_digits_lower;

  -- LED with signals from Main Control Unit
  led <= s_ctrl_alu_op     & -- ALU operation        15:13
         b"0000_0"         & -- Unused               12:8
         s_ctrl_reg_dst    & -- Register destination 7
         s_ctrl_ext_op     & -- Extend operation     6
         s_ctrl_alu_src    & -- ALU source           5
         s_ctrl_branch     & -- Branch               4
         s_ctrl_jump       & -- Jump                 3
         s_ctrl_mem_write  & -- Memory write         2
         s_ctrl_mem_to_reg & -- Memory to register   1
         s_ctrl_reg_write;   -- Register write       0
         
end architecture behavioral; 