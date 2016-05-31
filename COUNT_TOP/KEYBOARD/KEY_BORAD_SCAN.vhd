library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;   

entity key_scan is
	port(
	clk:in std_logic;
	rst:in std_logic;
	col:in std_logic_vector(3 downto 0);
	scan:out std_logic_vector(3 downto 0);
	key_value:out std_logic_vector(3 downto 0)
	);
end key_scan; 

architecture behavioral of key_scan is
signal cnt:std_logic_vector(1 downto 0);
signal scan_r:std_logic_vector(3 downto 0);
signal scan_temp:std_logic_vector(3 downto 0);
signal dl:std_logic_vector(3 downto 0);
signal col_d:std_logic_vector(3 downto 0);	  
signal value_reg:std_logic_vector(3 downto 0);

component xiaodou is
port(
din: in std_logic;
dout :out std_logic;
cp: in std_logic
);	
end component;

begin  
	u0:xiaodou port map(din =>col(0),dout=>col_d(0),cp=>clk);
	u1:xiaodou port map(din =>col(1),dout=>col_d(1),cp=>clk);
	u2:xiaodou port map(din =>col(2),dout=>col_d(2),cp=>clk);
	u3:xiaodou port map(din =>col(3),dout=>col_d(3),cp=>clk);
-------timer----------	
	process(clk,rst) 
	begin 
	if(rst='0')then 
	cnt<="00";
	elsif(clk'event and clk='1')then
		cnt<=cnt+1;
	end if;
	end process;
--------change of scan signal----------
process(cnt)
begin
case cnt is
when"00"=>scan_temp<="1110";
when"01"=>scan_temp<="1101";
when"10"=>scan_temp<="1011";
when others=>scan_temp<="0111";
end case;
end process; 

------register that keep scan signal and col signal asychronous---------
process(clk)
begin 
if(clk'event and clk='1')then 
	dl<=scan_temp;
	scan_r<=dl;
end if;
end process;

process(clk,rst)
begin 
if(rst='0')then
	value_reg<="1111";
elsif(clk'event and clk='1')then 
	case scan_r is
		when "1110"=>
		    case  col_d is 
			when"0111"=>value_reg<="0000";
			when"1011"=>value_reg<="0001";
			when"1101"=>value_reg<="0010";
			when"1110"=>value_reg<="0011";
			when others=>value_reg<="1111";
			end case;
	    when "1101"=>
		    case  col_d is 
			when"0111"=>value_reg<="0100";
			when"1011"=>value_reg<="0101";
			when"1101"=>value_reg<="0110";
			when"1110"=>value_reg<="0111";
			when others=>value_reg<="1111";
			end case;
		when "1011"=>
		    case  col_d is 
			when"0111"=>value_reg<="1000";
			when"1011"=>value_reg<="1001";
			when"1101"=>value_reg<="1010";
			when"1110"=>value_reg<="1011";
			when others=>value_reg<="1111";
			end case;
		when "0111"=>
		    case  col_d is 
			when"0111"=>value_reg<="1100";
			when"1011"=>value_reg<="1101";
			when"1101"=>value_reg<="1110";
			when"1110"=>value_reg<="1111";
			when others=>value_reg<="1111";
			end case;
			when others=>value_reg<="1111";
	end case;
	end if;
end process; 
key_value<=value_reg;
scan<=scan_temp;
end behavioral;	