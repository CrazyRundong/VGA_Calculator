library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;  

entity fenpin is
port(
clk:in std_logic;
rst:in std_logic;
clk1_6khz:out std_logic
);	
end fenpin;

architecture clkdiv of fenpin is
signal cnt1_6khz:std_logic_vector(13 downto 0);
signal temp1:std_logic;
constant zero14:std_logic_vector(13 downto 0):="00000000000000";
constant divd:integer:=10583;

begin 
----divider and asynchronous reset----
p_clk1_6khz:process(clk,rst)
begin
	if(rst = '0')then
	cnt1_6khz<=zero14;
	temp1<='0';
	elsif(clk'event and clk='1')then
		if(cnt1_6khz=divd)then 
		cnt1_6khz<=zero14;
		temp1<=not temp1;
		else 
		cnt1_6khz<=cnt1_6khz+1;
		end if;
	end if;
end process;
clk1_6khz<=temp1;
end clkdiv;
