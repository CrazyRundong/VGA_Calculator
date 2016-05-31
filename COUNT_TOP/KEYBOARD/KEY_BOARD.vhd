library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 

entity key_scan_0 is
	port(
	clk,rst:in std_logic;
	col:in std_logic_vector(3 downto 0);
	scan:out std_logic_vector(3 downto 0);
	ef_key:out std_logic;
	key_value:out std_logic_vector(3 downto 0)
	);
end key_scan_0;

architecture test_top of key_scan_0 is	
component fenpin is
port(
clk:in std_logic;
rst:in std_logic;
clk1_6khz:out std_logic
);	
end component;
component  key_scan is
	port(
	clk:in std_logic;
	rst:in std_logic;
	col:in std_logic_vector(3 downto 0);
	scan:out std_logic_vector(3 downto 0);
	key_value:out std_logic_vector(3 downto 0)
	);
end component; 
signal clk1_6khz:std_logic;
signal key_value_tem:std_logic_vector(3 downto 0);
begin 
	key_value<=key_value_tem;
	u_clkgen:fenpin port map(clk=>clk,rst=>rst,clk1_6khz=>clk1_6khz);
	u_keyscan:key_scan port map(clk=>clk1_6khz,rst=>rst,col=>col,scan=>scan,key_value=>key_value_tem);
	process(key_value_tem)
	begin
	case key_value_tem is
	when "0000"=>ef_key<='1';
	when "0001"=>ef_key<='1';
	when "0010"=>ef_key<='1';
	when "0011"=>ef_key<='1';
	when "0100"=>ef_key<='1';
	when "0101"=>ef_key<='1';
	when "0110"=>ef_key<='1';
	when "0111"=>ef_key<='1';
	when "1000"=>ef_key<='1';
	when "1001"=>ef_key<='1';
	when "1010"=>ef_key<='1';
	when "1011"=>ef_key<='1';
	when "1100"=>ef_key<='1';
	when "1101"=>ef_key<='1';
	when others=>ef_key<='0';
	end case;
	end process; 
end test_top;








