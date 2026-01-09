--
-- AAD 2025/2026, n-bit comparator
--
-- for extra credit, implement this also using chains of unsigned comparators:
--
-- unsigned comparator stage (one per bit)
--   in   a_bit   b_bit   old_lt   old_eq   old_gt
--   out                  new_lt   new_eq   new_gt
-- logic, start from the least significant bit with old_lt=old_gt=0 and old_eq=1
--   if a_bit=b_bit (no change, keep the earlier result)
--     new_lt=old_lt   new_eq=old_eq   new_gt=old_gt
--   else if a_bit=1 (a is greater because a_bit=1 and b_bit=0)
--     new_lt=0        new_eq=0        new_gt=1
--   else  (a is smaller because a_bit=0 and b_bit=1)
--     new_lt=1        new_eq=0        new_gt=0
-- use a transport delay of 5 ps per stage
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity comparator_n is
  generic
  (
    N : positive
  );
  port
  (
    a  : in  std_logic_vector(N-1 downto 0);
    b  : in  std_logic_vector(N-1 downto 0);
    lt : out std_logic; -- '1' if a<b, '0' otherwise
    eq : out std_logic; -- '1' if a=b, '0' otherwise
    gt : out std_logic  -- '1' if a>b, '0' otherwise
  );
end comparator_n;

architecture structural of comparator_n is
  -- Component declaration for single-bit comparator stage
  component comparator_stage is
    port
    (
      a_bit   : in  std_logic;
      b_bit   : in  std_logic;
      old_lt  : in  std_logic;
      old_eq  : in  std_logic;
      old_gt  : in  std_logic;
      new_lt  : out std_logic;
      new_eq  : out std_logic;
      new_gt  : out std_logic
    );
  end component;
  
  -- Internal signals for chaining comparator stages
  -- Array of N+1 elements: index 0 is initial, indices 1..N are outputs of each stage
  type cmp_chain_t is array(0 to N) of std_logic;
  signal chain_lt : cmp_chain_t;
  signal chain_eq : cmp_chain_t;
  signal chain_gt : cmp_chain_t;
  
begin
  
  -- Initialize the comparison chain (start from LSB with lt=0, eq=1, gt=0)
  chain_lt(0) <= '0';
  chain_eq(0) <= '1';
  chain_gt(0) <= '0';
  
  -- Generate N comparator stages, one per bit
  -- Start from LSB (bit 0) and propagate to MSB (bit N-1)
  gen_stages : for i in 0 to N-1 generate
    stage : comparator_stage
      port map
      (
        a_bit   => a(i),
        b_bit   => b(i),
        old_lt  => chain_lt(i),
        old_eq  => chain_eq(i),
        old_gt  => chain_gt(i),
        new_lt  => chain_lt(i+1),
        new_eq  => chain_eq(i+1),
        new_gt  => chain_gt(i+1)
      );
  end generate gen_stages;
  
  -- Output the final results from the last stage
  lt <= chain_lt(N);
  eq <= chain_eq(N);
  gt <= chain_gt(N);
  
end structural;
