library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;
entity counter_vga_top is
port(
clk,rst:in std_logic;
col:in std_logic_vector(3 downto 0);
scan:out std_logic_vector(3 downto 0);
err:out std_logic;
vgaRGB : out STD_LOGIC_VECTOR(2 downto 0); -- R, G, B
vgaHSYNC : out STD_LOGIC; -- in line 
vgaVSYNC : out STD_LOGIC
);	
end counter_vga_top;

architecture behavior of counter_vga_top is 
signal CPU_Data :  STD_LOGIC_VECTOR(15 downto 0);
signal RTS : STD_LOGIC; -- '1' for data coming, "complete"
signal EFK :  STD_LOGIC; -- '1' for key data coming
signal Key_Data : STD_LOGIC_VECTOR(3 downto 0);
component count_top is 
port(
clk,rst:in std_logic;
col:in std_logic_vector(3 downto 0);
scan:out std_logic_vector(3 downto 0);
key_value0:out std_logic_vector(3 downto 0);
result_end:out std_logic_vector(15 downto 0);
ef_key:out std_logic;
complete:out std_logic;
err:out std_logic
);
end component;
component RAM_Control is
    port(
        -- global signals:
        clk : in STD_LOGIC; -- 40MHz, 250ns
        rst : in STD_LOGIC; -- '0' for reset
        -- data from cpu:
        CPU_Data : in STD_LOGIC_VECTOR(15 downto 0);
        RTS : in STD_LOGIC; -- '1' for data coming, "complete"
        EFK : in STD_LOGIC; -- '1' for key data coming
        Key_Data : in STD_LOGIC_VECTOR(3 downto 0);
        -- OUTPUTS TO VGA
        vgaRGB : out STD_LOGIC_VECTOR(2 downto 0); -- R, G, B
        vgaHSYNC : out STD_LOGIC; -- in line 
        vgaVSYNC : out STD_LOGIC);
end component;
begin
u1:count_top port map(clk=>clk,rst=>rst,col=>col,scan=>scan,err=>err,ef_key=>EFK,key_value0=>Key_Data,
complete=>RTS,result_end=>CPU_Data);
u2:RAM_Control port map(clk=>clk,rst=>rst,CPU_Data=>CPU_Data,
RTS=>RTS,EFK=>EFK,Key_data=>Key_data,vgaRGB=>vgaRGB,vgaHSYNC=>vgaHSYNC,vgaVSYNC=>vgaVSYNC);	
end behavior;

