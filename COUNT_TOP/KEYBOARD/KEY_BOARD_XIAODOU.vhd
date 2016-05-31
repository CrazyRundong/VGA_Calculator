library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;   

entity xiaodou is
	port(
	din: in std_logic;
	dout :out std_logic;
	cp:in std_logic
	);
end xiaodou;

architecture  debounce of xiaodou is 
signal d1:std_logic;
signal d2:std_logic;
signal s:std_logic;
signal r:std_logic;
signal q:std_logic;
signal qn:std_logic; 
begin
-----registers that save the lastest two value--------
	process(cp)
	begin 
		if(cp'event and cp='1')then 
			d1<=din;
			d2<=d1;
		end if;
	end process;	
-----------RS trigger------------------
s<=d1 and d2;
r<=(not d1)and(not d2);
q<=r nor qn;
qn<=s nor q;
dout<=q;
end debounce;


	