library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;
entity count_top is 
port(
clk,rst:in std_logic;
col:in std_logic_vector(3 downto 0);
scan:out std_logic_vector(3 downto 0);
result_end:out std_logic_vector(15 downto 0);
ef_key:out std_logic;
complete:out std_logic;
err:out std_logic
);	
end  count_top;

architecture behavior of count_top is 
component detect_FSM is
port(
clk,rst,ef_key:in std_logic;
key_value:in std_logic_vector(3 downto 0);
result_end:out std_logic_vector(15 downto 0);
complete:out std_logic;
err:out std_logic
);
end component;
component key_scan_0 is
port(
clk,rst:in std_logic;
col:in std_logic_vector(3 downto 0);
scan:out std_logic_vector(3 downto 0);
ef_key:out std_logic;
key_value:out std_logic_vector(3 downto 0));
end component;
signal key_value:std_logic_vector(3 downto 0);
signal ef_key0:std_logic;
begin 
u1:detect_FSM port map(clk=>clk,rst=>rst,ef_key=>ef_key0,key_value=>key_value,complete=>complete,result_end=>result_end,err=>err);
u2:key_scan_0 port map(clk=>clk,rst=>rst,col=>col,scan=>scan,ef_key=>ef_key0,key_value=>key_value);
ef_key<=ef_key0;	
end behavior;