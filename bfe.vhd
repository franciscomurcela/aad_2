--
-- AAD 2025/2026, data flow for the bit-field extract instruction
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bfe is
  generic
  (
    DATA_BITS_LOG2 : integer range 2 to 6 := 4                    -- use 4 by default
  );
  port
  ( 
    dst     : out std_logic_vector(2**DATA_BITS_LOG2-1 downto 0); -- 15 downto 0
    src     : in  std_logic_vector(2**DATA_BITS_LOG2-1 downto 0); -- 15 downto 0
    size    : in  std_logic_vector(   DATA_BITS_LOG2-1 downto 0); --  3 downto 0
    start   : in  std_logic_vector(   DATA_BITS_LOG2-1 downto 0); --  3 downto 0
    variant : in  std_logic                                       -- '0' for .u and '1' for .s
  );
end bfe;

architecture structural of bfe is
  -- Componentes
  component barrel_shift_right is
    generic
    (
      DATA_BITS_LOG2 : integer range 1 to 6 := 4
    );
    port
    (
      data_in  : in  std_logic_vector(2**DATA_BITS_LOG2-1 downto 0);
      data_out : out std_logic_vector(2**DATA_BITS_LOG2-1 downto 0);
      shift    : in  std_logic_vector(   DATA_BITS_LOG2-1 downto 0);
      missing  : in  std_logic
    );
  end component;
  
  component comparator_n is
    generic
    (
      N : positive
    );
    port
    (
      a  : in  std_logic_vector(N-1 downto 0);
      b  : in  std_logic_vector(N-1 downto 0);
      lt : out std_logic;
      eq : out std_logic;
      gt : out std_logic
    );
  end component;
  
  -- Sinais internos
  signal shifted_src : std_logic_vector(2**DATA_BITS_LOG2-1 downto 0); -- Resultado do barrel shift
  signal mask        : std_logic_vector(2**DATA_BITS_LOG2-1 downto 0); -- Máscara para isolar bits
  signal masked_data : std_logic_vector(2**DATA_BITS_LOG2-1 downto 0); -- Dados após aplicação da máscara
  signal sign_bit    : std_logic;                                       -- Bit de sinal para extensão
  signal extended    : std_logic_vector(2**DATA_BITS_LOG2-1 downto 0); -- Resultado final com extensão
  
  -- Sinais auxiliares para comparação (bit-a-bit)
  type cmp_array_t is array(0 to 2**DATA_BITS_LOG2-1) of std_logic;
  signal bit_lt : cmp_array_t; -- bit i < size?
  signal bit_eq : cmp_array_t; -- bit i = size?
  signal bit_gt : cmp_array_t; -- bit i > size?
  
  -- Constantes para comparação
  constant ZERO_VECTOR : std_logic_vector(DATA_BITS_LOG2-1 downto 0) := (others => '0');
  
begin
  
  -- ========================================================================
  -- PASSO 1: BARREL SHIFT RIGHT
  -- Desloca src à direita por 'start' posições para alinhar o bit-field
  -- O bit 'start' fica na posição 0
  -- Usa '0' para missing (logical shift) pois queremos zeros à esquerda
  -- ========================================================================
  barrel_shifter : barrel_shift_right
    generic map
    (
      DATA_BITS_LOG2 => DATA_BITS_LOG2
    )
    port map
    (
      data_in  => src,
      data_out => shifted_src,
      shift    => start,
      missing  => '0' -- Logical shift (preenche com zeros à esquerda)
    );
  
  -- ========================================================================
  -- PASSO 2: CRIAÇÃO DA MÁSCARA
  -- Para cada bit i, compara se i < size
  -- Se i < size, o bit deve ser mantido (mask(i) = '1')
  -- Se i >= size, o bit deve ser zerado (mask(i) = '0')
  -- ========================================================================
  gen_mask : for i in 0 to 2**DATA_BITS_LOG2-1 generate
    -- Converte i para std_logic_vector para comparação
    constant i_vector : std_logic_vector(DATA_BITS_LOG2-1 downto 0) := 
                        std_logic_vector(to_unsigned(i, DATA_BITS_LOG2));
  begin
    comparator : comparator_n
      generic map
      (
        N => DATA_BITS_LOG2
      )
      port map
      (
        a  => i_vector,
        b  => size,
        lt => bit_lt(i),
        eq => bit_eq(i),
        gt => bit_gt(i)
      );
    
    -- Máscara é '1' se i < size, '0' caso contrário
    mask(i) <= bit_lt(i);
  end generate gen_mask;
  
  -- ========================================================================
  -- PASSO 3: APLICAÇÃO DA MÁSCARA
  -- Isola os bits de interesse do campo bit-field deslocado
  -- ========================================================================
  masked_data <= shifted_src and mask;
  
  -- ========================================================================
  -- PASSO 4: DETERMINAÇÃO DO BIT DE SINAL
  -- O bit de sinal é o MSB do campo extraído (posição size-1)
  -- Precisamos identificar qual bit de masked_data corresponde a size-1
  -- ========================================================================
  process(masked_data, size)
    variable size_minus_1 : unsigned(DATA_BITS_LOG2-1 downto 0);
    variable bit_pos      : integer range 0 to 2**DATA_BITS_LOG2-1;
  begin
    -- Se size = 0, não há bit de sinal (caso especial)
    if unsigned(size) = 0 then
      sign_bit <= '0';
    else
      -- Calcula size - 1
      size_minus_1 := unsigned(size) - 1;
      bit_pos := to_integer(size_minus_1);
      
      -- Garante que não há overflow
      if bit_pos < 2**DATA_BITS_LOG2 then
        sign_bit <= masked_data(bit_pos);
      else
        sign_bit <= '0';
      end if;
    end if;
  end process;
  
  -- ========================================================================
  -- PASSO 5: EXTENSÃO (ZERO-EXTENSION OU SIGN-EXTENSION)
  -- Se variant = '0' (.u): Zero-extension
  -- Se variant = '1' (.s): Sign-extension
  -- ========================================================================
  gen_extension : for i in 0 to 2**DATA_BITS_LOG2-1 generate
    -- Se o bit está dentro da máscara (i < size), mantém o valor
    -- Se está fora da máscara (i >= size), usa zero-extension ou sign-extension
    extended(i) <= masked_data(i) when mask(i) = '1' else
                   (variant and sign_bit);
  end generate gen_extension;
  
  -- ========================================================================
  -- SAÍDA FINAL
  -- ========================================================================
  dst <= extended;
  
end structural;
