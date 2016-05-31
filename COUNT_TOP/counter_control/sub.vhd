library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;
entity sub0 is 
port(
en_count:in std_logic;
opc1,opc2:in std_logic_vector(11 downto 0);
result:out std_logic_vector(15 downto 0)
);	
end sub0;

architecture behavior of sub0 is
begin
process(en_count)
begin
if en_count='1' then 
result<="00000000"&(opc1-opc2);
else result<=(others=>'0');
end if;
end process;
end behavior;