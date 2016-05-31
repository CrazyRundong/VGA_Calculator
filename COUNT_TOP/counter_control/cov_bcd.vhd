library ieee; 
--16位二进制转BCD码（0到9999）
Use ieee.std_logic_unsigned.all;
Use ieee.std_logic_1164.all; 

entity cov_bcd is
port(
clk,rst,en_cov  :in std_logic;
result:in std_logic_vector(15 downto 0);
result_end:out std_logic_vector(15 downto 0)
);	
end cov_bcd ;
architecture behav of cov_bcd is 
signal i: integer range 0 to 16;
signal load:std_logic_vector(15 downto 0);--yi wei and pan duan
begin 
process(clk,rst)
begin 
if rst='0' then 
	i<=16;
	load<=(others=>'0');
elsif en_cov='1'then 
elsif clk'event and clk='1' then
	if i=0 then
    result_end<=load;
	else 
		if(load(2 downto 0)&result(i-1)>"0100")then
		load<=(load(14 downto 0)&result(i-1))+"0000000000000011";
		else
		load<=load(14 downto 0)&result(i-1);
		end if;
		i<=i-1;
	end if;
end if;	
end process;
end behav;  								  

  
