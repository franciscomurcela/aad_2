--
-- AAD 2025/2026, single-bit comparator stage
--
-- Implements one stage of a bit-by-bit comparator chain
-- Compares one bit position and propagates comparison results
--

library IEEE;
use IEEE.std_logic_1164.all;

entity comparator_stage is
  port
  (
    a_bit   : in  std_logic;  -- bit from operand a
    b_bit   : in  std_logic;  -- bit from operand b
    old_lt  : in  std_logic;  -- previous less-than result
    old_eq  : in  std_logic;  -- previous equal result
    old_gt  : in  std_logic;  -- previous greater-than result
    new_lt  : out std_logic;  -- updated less-than result
    new_eq  : out std_logic;  -- updated equal result
    new_gt  : out std_logic   -- updated greater-than result
  );
end comparator_stage;

architecture behavioral of comparator_stage is
  signal s_lt : std_logic;
  signal s_eq : std_logic;
  signal s_gt : std_logic;
begin
  process(a_bit, b_bit, old_lt, old_eq, old_gt)
  begin
    if a_bit = b_bit then
      -- Bits are equal, keep previous results
      s_lt <= old_lt;
      s_eq <= old_eq;
      s_gt <= old_gt;
    elsif a_bit = '1' then
      -- a_bit=1 and b_bit=0, so a > b at this position
      s_lt <= '0';
      s_eq <= '0';
      s_gt <= '1';
    else
      -- a_bit=0 and b_bit=1, so a < b at this position
      s_lt <= '1';
      s_eq <= '0';
      s_gt <= '0';
    end if;
  end process;
  
  -- 5 ps delay per stage as specified
  new_lt <= transport s_lt after 5 ps;
  new_eq <= transport s_eq after 5 ps;
  new_gt <= transport s_gt after 5 ps;
  
end behavioral;
