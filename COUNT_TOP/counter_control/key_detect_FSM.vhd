library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;
entity detect_FSM is
port(
clk,rst,ef_key:in std_logic;
key_value:in std_logic_vector(3 downto 0);
result_end:out std_logic_vector(15 downto 0);
complete:out std_logic;
err:out std_logic
);
end detect_FSM;	 

architecture behavior of detect_FSM is 
component add0 is
port(
en_count:in std_logic;
opc1,opc2:in std_logic_vector(11 downto 0);
result:out std_logic_vector(15 downto 0));		
end component;
component sub0 is
port(
en_count:in std_logic;
opc1,opc2:in std_logic_vector(11 downto 0);
result:out std_logic_vector(15 downto 0));		
end component;
component cov_bcd is
port(
clk,rst,en_cov  :in std_logic;
result:in std_logic_vector(15 downto 0);
result_end:out std_logic_vector(15 downto 0)
);		
end component;
constant ADD:std_logic_vector(3 downto 0):="1010";
constant SUB:std_logic_vector(3 downto 0):="1011";
constant PRO:std_logic_vector(3 downto 0):="1100";
constant DIV:std_logic_vector(3 downto 0):="1101";
constant EQU:std_logic_vector(3 downto 0):="1110";

signal result1:std_logic_vector(15 downto 0);
signal result2:std_logic_vector(15 downto 0);
signal result3:std_logic_vector(15 downto 0);
signal result4:std_logic_vector(15 downto 0);

signal opc1: std_logic_vector(11 downto 0);
signal opc2:std_logic_vector(11 downto 0);
signal operator: std_logic_vector(3 downto 0);
signal result:std_logic_vector(15 downto 0);
signal en_count: std_logic;---对四种计数器均有效

constant inti : std_logic_vector (1 downto 0):="00";
constant key_detect1 : std_logic_vector (1 downto 0):="01";
constant key_detect2 : std_logic_vector (1 downto 0):="10";
constant wait_rst:std_logic_vector(1 downto 0):="11";

signal state:std_logic_vector(1 downto 0);

signal num:std_logic_vector(1 downto 0);  ----to count the number of inputed digit
signal err_t:std_logic;
signal en_cov:std_logic;--ALU输出使能，BCD转换进程输入使能

signal count:std_logic_vector(5 downto 0);
signal complete_t:std_logic;
begin 
	err<=err_t;
	complete<=complete_t;
	process(rst,clk)
	begin 
	if(rst='0')then
	opc1<=(others=>'0');
	opc2<=(others=>'0');
	operator<="0000";
	en_count<='0';
	state<=inti;
	en_cov<='0';
	complete_t<='0';
	count<=(others=>'0');
	elsif(clk'event and clk='1')then
		case state is
			when inti=>
			if ef_key='1' then
				state<=key_detect1;
			else state<=inti;
			end if;
			when key_detect1=>
			if ef_key='1' and err_t='0'then
				case key_value is
					when ADD =>operator<=key_value;
					           state<=key_detect2; 
					when SUB =>operator<=key_value;
							   state<=key_detect2;
					when PRO =>operator<=key_value;
							   state<=key_detect2;
					when DIV =>operator<=key_value;
					            state<=key_detect2;
					when EQU =>en_count<='1';
					           state<=inti;
					when others=>opc1<=opc1(8 downto 0)&"000"+opc1(10 downto 0)&'0'+key_value;
				end case;
			else  state<=key_detect1;
			end if;
			when key_detect2=>
			if ef_key='1' and err_t='0'then
				case key_value is
					when ADD|SUB|PRO|DIV =>state<=key_detect2;
					when EQU =>en_count<='1';
					           state<=wait_rst;
					when others=>opc2<=opc2(8 downto 0)&"000"+opc2(10 downto 0)&'0'+key_value;
				end case;
			else  state<=key_detect2;
			end if;
			when wait_rst=>
			if rst='1' then
			state<=wait_rst;
			if count="010000"then 
				 en_cov<='1';
			elsif count="100000"then
				 complete_t<='1';
		    else count<=count+'1';
		    end if;
			end if;
			when others=>state<=inti;
			end case;
	end if;
	end process;
	
	--字符输入监测器
	process(rst,ef_key)
	begin 
	if rst='0' then
	err_t<='0';
	num<="00";
	elsif ef_key'event and ef_key='1' then
		if((state=key_detect1)and (key_value=ADD or key_value=SUB or key_value=PRO or key_value=DIV) ) then 
			num<="00";
			err_t<='0';
		elsif((state=key_detect2) and (key_value=ADD or key_value=SUB or key_value=PRO or key_value=DIV))then 
			err_t<='1';
		elsif ((state=key_detect2) and (key_value=EQU)) then
			num<="00";
			err_t<='0';
		elsif num="11" then 
			err_t<='1';
		else num<=num+'1';
		end if;
	  end if;
	end process;
	
	--判断输出结果从哪个运算器输出，数据选择器
	process(en_count)
	begin
    if en_count='1' then 
	case operator is
		when add=>result<=result1;
		when sub=>result<=result2;
		when pro=>result<=result3;
		when div=>result<=result4;
		when  others=>result<=(others=>'0');
	end case;
	else null;
	end if;
	end process;
	
	u1:add0 port map(en_count=>en_count,opc1=>opc1,opc2=>opc2,result=>result1);
	u2:sub0 port map(en_count=>en_count,opc1=>opc1,opc2=>opc2,result=>result2);
--	u3:pro0 port map(en_count=>en_count,opc1=>opc1,opc2=>opc2,result=>result1);
--	u4:div0 port map(en_count=>en_count,opc1=>opc1,opc2=>opc2,result=>result2);
	u3:cov_bcd port map(clk=>clk,rst=>rst,en_cov=>en_cov,result=>result,result_end=>result_end);
	end behavior;