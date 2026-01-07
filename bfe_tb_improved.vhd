--
-- AAD 2025/2026, bfe testbench melhorado com valores reais
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bfe_tb_improved is
end bfe_tb_improved;

architecture stimulus of bfe_tb_improved is
  -- constants
  constant DATA_BITS_LOG2 : positive := 4;
  -- the interface signals
  signal s_dst            : std_logic_vector(2**DATA_BITS_LOG2-1 downto 0);
  signal s_src            : std_logic_vector(2**DATA_BITS_LOG2-1 downto 0);
  signal s_size           : std_logic_vector(   DATA_BITS_LOG2-1 downto 0);
  signal s_start          : std_logic_vector(   DATA_BITS_LOG2-1 downto 0);
  signal s_variant        : std_logic;
begin
  uut : entity work.bfe(structural)
               generic map
               (
                 DATA_BITS_LOG2 => DATA_BITS_LOG2
               )
               port map
               (
                 dst     => s_dst,
                 src     => s_src,
                 size    => s_size,
                 start   => s_start,
                 variant => s_variant
               );
  stim : process is
  begin
    -- Teste 1: Extrair 4 bits começando na posição 3 de 0xABCD
    -- Bits [6:3] de 0xABCD = 1010101111001101 -> bits 6,5,4,3 = 1001 = 0x9
    s_src      <= "1010101111001101"; -- 0xABCD
    s_size     <= "0100"; -- 4 bits
    s_start    <= "0011"; -- posição 3
    s_variant  <= '0'; -- unsigned
    wait for 500 ps;
    
    s_variant  <= '1'; -- signed (bit de sinal = 1, então estende com 1s)
    wait for 500 ps;
    
    -- Teste 2: Extrair 8 bits começando na posição 4 de 0xDEAD
    -- Bits [11:4] de 0xDEAD = 1101111010101101 -> bits 11-4 = 11101110 = 0xEE
    s_src      <= "1101111010101101"; -- 0xDEAD
    s_size     <= "1000"; -- 8 bits
    s_start    <= "0100"; -- posição 4
    s_variant  <= '0'; -- unsigned
    wait for 500 ps;
    
    s_variant  <= '1'; -- signed
    wait for 500 ps;
    
    -- Teste 3: Extrair 3 bits começando na posição 0 de 0x1234
    -- Bits [2:0] de 0x1234 = 0001001000110100 -> bits 2,1,0 = 100 = 0x4
    s_src      <= "0001001000110100"; -- 0x1234
    s_size     <= "0011"; -- 3 bits
    s_start    <= "0000"; -- posição 0
    s_variant  <= '0'; -- unsigned
    wait for 500 ps;
    
    s_variant  <= '1'; -- signed (bit de sinal = 1, então resultado negativo)
    wait for 500 ps;
    
    -- Teste 4: Caso limite - size + start > 15 (deve preencher com zeros)
    -- Extrair 8 bits começando na posição 10 de 0xFFFF
    -- Bits [17:10] mas só existem até [15:10] = 6 bits = 111111, resto com 0
    s_src      <= "1111111111111111"; -- 0xFFFF
    s_size     <= "1000"; -- 8 bits
    s_start    <= "1010"; -- posição 10
    s_variant  <= '0'; -- unsigned
    wait for 500 ps;
    
    s_variant  <= '1'; -- signed
    wait for 500 ps;
    
    -- Teste 5: Extrair todos os 16 bits (size=0 deve ser interpretado como 16)
    s_src      <= "1001000111100101"; -- 0x91E5
    s_size     <= "0000"; -- 0 bits (ou 16 bits dependendo da implementação)
    s_start    <= "0000"; -- posição 0
    s_variant  <= '0'; -- unsigned
    wait for 500 ps;
    
    -- Teste 6: Campo de 1 bit (testar bit individual)
    s_src      <= "1010101010101010"; -- 0xAAAA
    s_size     <= "0001"; -- 1 bit
    s_start    <= "0101"; -- posição 5 (bit=0)
    s_variant  <= '0'; -- unsigned
    wait for 500 ps;
    
    s_start    <= "0100"; -- posição 4 (bit=1)
    wait for 500 ps;
    
    -- Teste 7: Valor negativo com sign extension
    s_src      <= "1111111111110110"; -- 0xFFF6 = -10 em complemento de 2
    s_size     <= "0100"; -- 4 bits
    s_start    <= "0000"; -- posição 0
    s_variant  <= '0'; -- unsigned -> resultado = 0x0006
    wait for 500 ps;
    
    s_variant  <= '1'; -- signed -> resultado = 0xFFF6 (extensão de sinal)
    wait for 500 ps;
    
    -- done
    wait;
  end process;
end stimulus;
