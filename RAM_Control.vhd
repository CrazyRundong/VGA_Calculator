----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:23:57 04/05/2016 
-- Design Name: 
-- Module Name:    RAM_Control - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
Library XilinxCoreLib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM_Control is
    port(
        -- global signals:
        clk : in STD_LOGIC; -- 40MHz, 250ns
        rst : in STD_LOGIC; -- '0' for reset
        -- data from cpu:
        CPU_Data : in STD_LOGIC_VECTOR(15 downto 0);
        RTS : in STD_LOGIC; -- '0' for data coming, "complete"
        EFK : in STD_LOGIC; -- '1' for key data coming
        Key_Data : in STD_LOGIC_VECTOR(3 downto 0);
        -- OUTPUTS TO VGA
        vgaRGB : out STD_LOGIC_VECTOR(2 downto 0); -- R, G, B
        vgaHSYNC : out STD_LOGIC; -- in line 
        vgaVSYNC : out STD_LOGIC);
end RAM_Control;

architecture Behavioral of RAM_Control is
------------------------------------------------------------
-- COMPONENTS
------------------------------------------------------------
-- component RAM: 16*256
component RAM_16_256 IS
	port (
        addr: IN std_logic_VECTOR(7 downto 0);
        clk: IN std_logic;
        din: IN std_logic_VECTOR(15 downto 0);
        dout: OUT std_logic_VECTOR(15 downto 0);
        we: IN std_logic); -- '1' for Write Enable
END component;
-- component VGA_Driver:
component VGA_DRIVER is
    port(
        -- INPUTS:
        en : in STD_LOGIC; -- '1' for display enable
        rst : in STD_LOGIC; -- global reset, LOW EFFECT
        clk : in STD_LOGIC; -- 40MHz
        pixInfo : in STD_LOGIC_VECTOR(2 downto 0); -- this pix is BLACK(0) or WHITE(1)
        -- IN-SYSTEM PORTS:
        pixLocX : out INTEGER; -- pos X of current pix (0 to 799)
        pixLocY : out INTEGER; -- pos Y of current pix (0 to 599)
        -- VGA OUTPUTS:
        vgaRGB : out STD_LOGIC_VECTOR(2 downto 0); -- R, G, B
        vgaHSYNC : out STD_LOGIC; -- in line 
        vgaVSYNC : out STD_LOGIC); -- in frame
end component;

-- typedef num sym
type num_sym is array(0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
type char_sym is array(0 to 15) of STD_LOGIC_VECTOR(15 downto 0);
type State is (Reset, Init, Display, dataFromCPU, dataFromKey);

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------
-- base address: (7 downto 0, 0x000 -> 0xFFFF)
-- pix info:
constant titleAdd : STD_LOGIC_VECTOR(7 downto 0) := X"00"; -- 16 * 5
constant numAdd : STD_LOGIC_VECTOR(7 downto 0) := X"50"; -- 8 * (2 + 1 + 2 + 1)
constant resultAdd : STD_LOGIC_VECTOR(7 downto 0) := X"80"; -- 8 * 4
constant endAdd : STD_LOGIC_VECTOR(7 downto 0) := X"A0"; -- oops, there a lot ramain...
-- constants for char and num sym: (3200bit total)
-- 8 * 16 (width * higth)
constant num_0 : num_sym := (X"00",X"00",X"00",X"18",X"24",X"42",X"42",X"42",X"42",X"42",X"42",X"42",X"24",X"18",X"00",X"00");--0
constant num_1 : num_sym := (X"00",X"00",X"00",X"08",X"38",X"08",X"08",X"08",X"08",X"08",X"08",X"08",X"08",X"3E",X"00",X"00");--1
constant num_2 : num_sym := (X"00",X"00",X"00",X"3C",X"42",X"42",X"42",X"02",X"04",X"08",X"10",X"20",X"42",X"7E",X"00",X"00");--2
constant num_3 : num_sym := (X"00",X"00",X"00",X"3C",X"42",X"42",X"02",X"04",X"18",X"04",X"02",X"42",X"42",X"3C",X"00",X"00");--3
constant num_4 : num_sym := (X"00",X"00",X"00",X"04",X"0C",X"0C",X"14",X"24",X"24",X"44",X"7F",X"04",X"04",X"1F",X"00",X"00");--4
constant num_5 : num_sym := (X"00",X"00",X"00",X"7E",X"40",X"40",X"40",X"78",X"44",X"02",X"02",X"42",X"44",X"38",X"00",X"00");--5
constant num_6 : num_sym := (X"00",X"00",X"00",X"18",X"24",X"40",X"40",X"5C",X"62",X"42",X"42",X"42",X"22",X"1C",X"00",X"00");--6
constant num_7 : num_sym := (X"00",X"00",X"00",X"7E",X"42",X"04",X"04",X"08",X"08",X"10",X"10",X"10",X"10",X"10",X"00",X"00");--7
constant num_8 : num_sym := (X"00",X"00",X"00",X"3C",X"42",X"42",X"42",X"24",X"18",X"24",X"42",X"42",X"42",X"3C",X"00",X"00");--8
constant num_9 : num_sym := (X"00",X"00",X"00",X"38",X"44",X"42",X"42",X"42",X"46",X"3A",X"02",X"02",X"24",X"18",X"00",X"00");--9
constant num_plus : num_sym := (X"00",X"00",X"00",X"00",X"00",X"08",X"08",X"08",X"7F",X"08",X"08",X"08",X"00",X"00",X"00",X"00");--+
constant num_sub : num_sym := (X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"7E",X"00",X"00",X"00",X"00",X"00",X"00",X"00");---
constant num_mult : num_sym := (X"00",X"00",X"00",X"00",X"10",X"10",X"D6",X"38",X"38",X"D6",X"10",X"10",X"00",X"00",X"00",X"00");--*
constant num_div : num_sym := (X"00",X"00",X"02",X"04",X"04",X"04",X"08",X"08",X"10",X"10",X"10",X"20",X"20",X"40",X"40",X"00");--/
constant num_equ : num_sym := (X"00",X"00",X"00",X"00",X"00",X"00",X"7E",X"00",X"00",X"7E",X"00",X"00",X"00",X"00",X"00",X"00");--=
-- title chars:
-- 16 * 16 (width * higth)
constant char_c0 : char_sym := (X"2040",X"3F7E",X"4890",X"8508",X"1000",X"0BF8",X"2008",X"27C8",X"2448",X"2448",X"27C8",X"2448",X"2448",X"27C8",X"2008",X"2018");
constant char_c1 : char_sym := (X"0FF0",X"0810",X"0810",X"0FF0",X"0810",X"0810",X"0FF0",X"0400",X"0800",X"1FFC",X"2244",X"4244",X"0484",X"0884",X"1128",X"0210");
constant char_c2 : char_sym := (X"0040",X"2040",X"1040",X"1040",X"0040",X"0040",X"F7FE",X"1040",X"1040",X"1040",X"1040",X"1040",X"1440",X"1840",X"1040",X"0040");
constant char_c3 : char_sym := (X"2040",X"3E7E",X"4890",X"8000",X"3FF8",X"2008",X"3FF8",X"2008",X"3FF8",X"2008",X"3FF8",X"0820",X"FFFE",X"0820",X"1020",X"2020");
constant char_c4 : char_sym := (X"0000",X"3E7C",X"2244",X"2244",X"3E7C",X"0120",X"0110",X"FFFE",X"0280",X"0C60",X"3018",X"C006",X"3E7C",X"2244",X"2244",X"3E7C");

------------------------------------------------------------
-- SIGNALS
------------------------------------------------------------
-- states:
    signal currentState, nextState : State;
    signal currentStoreLine_Title : STD_LOGIC_VECTOR(15 downto 0); -- current dealing 16bit
    signal currentStoreLine_CPU : STD_LOGIC_VECTOR(15 downto 0); -- current dealing 16bit
    signal currentStoreLine_Key : STD_LOGIC_VECTOR(15 downto 0); -- current dealing 16bit
-- reset circle
    signal ResetCircle : STD_LOGIC_VECTOR(3 downto 0);
    signal ResetCircle_En : STD_LOGIC;
-- load title
    signal title_RAM_addr: std_logic_VECTOR(7 downto 0);
    signal titleStore_En : STD_LOGIC; -- '1' for loading title
    signal titleStored : STD_LOGIC; -- '1' for store complete
    signal titleCharIdx : STD_LOGIC_VECTOR(2 downto 0); -- index of current title char, 0 to 4
-- RTS count:
    signal RTS_Count : STD_LOGIC_VECTOR(4 downto 0); -- wait when RTS -> '1'
    signal RTS_En : STD_LOGIC; -- '1' for start count for RTS circle
-- store CPU data flag:
    signal CPU_RAM_addr: std_logic_VECTOR(7 downto 0);
    signal CPU_NumIdx : STD_LOGIC_VECTOR(1 downto 0); -- index of current CPU num, 0 to 3
    signal CPU_DataStored : STD_LOGIC; -- '1' for stored
    signal CPU_DataStart_En : STD_LOGIC; -- '1' for started
    signal currentBCD_CPU : STD_LOGIC_VECTOR(3 downto 0);
-- store keybord info:
    signal key_RAM_addr: std_logic_VECTOR(7 downto 0);
    signal keyNumIdx : STD_LOGIC_VECTOR(2 downto 0); -- index of current key num, 0 to 5
    signal keyDataStored : STD_LOGIC; -- '1' for loading
    signal keyDataStore_En : STD_LOGIC; -- '1' for loaded
    signal currentBCD_Key : STD_LOGIC_VECTOR(3 downto 0);
-- current store index:
    signal storeLineIdx : STD_LOGIC_VECTOR(3 downto 0); -- storing line number
-- signal for main RAM:
  -- inputs:
    signal RAM_clk: std_logic;
    signal RAM_we: std_logic; -- '1' for Write Enable
    signal RAM_addr: std_logic_VECTOR(7 downto 0);
    signal RAM_din: std_logic_VECTOR(15 downto 0);
  -- only output of RAM
    signal RAM_dout: std_logic_VECTOR(15 downto 0);
-- signals for VGA Driver
  -- input:
    signal RGB_Info : STD_LOGIC_VECTOR(2 downto 0); -- R, G, B
    signal VGA_En : STD_LOGIC;
  -- output:
    signal pixLocX : INTEGER; -- pos X of current pix (0 to 799)
    signal pixLocY : INTEGER; -- pos Y of current pix (0 to 599)
  -- data from vga driver
    signal VGA_char_idx : STD_LOGIC_VECTOR(3 downto 0); -- 15 chars
    signal VGA_inChar_line : STD_LOGIC_VECTOR(3 downto 0); -- 16 lines
    signal VGA_inChar_column : STD_LOGIC_VECTOR(3 downto 0); -- 16 lines max
    signal VGA_addr : STD_LOGIC_VECTOR(7 downto 0); -- 8bit address
    

begin
------------------------------------------------------------
-- COMPONENT INSTANTS
-- VGA_DRIVER and RAM
------------------------------------------------------------
  -- main RAM:
    mainRAM : RAM_16_256
    port map (RAM_addr, RAM_clk, RAM_din, RAM_dout, RAM_we);
    -- connect RAM:
    RAM_addr <= title_RAM_addr OR CPU_RAM_addr OR key_RAM_addr OR VGA_addr;
    RAM_clk <= clk;
    RAM_din <= currentStoreLine_Title OR currentStoreLine_CPU OR currentStoreLine_Key;
  -- VGA Driver:
    mainVGA : VGA_DRIVER
    port map (VGA_En, rst, clk, RGB_Info, pixLocX, pixLocY, vgaRGB, vgaHSYNC, vgaVSYNC); 

------------------------------------------------------------
-- FSM PROCESSES
-- MAIN PROCESS: NEXT_STATE, STATE_TRANS, STATE_BEHAVIOR
------------------------------------------------------------
    stateReg : process(clk, rst)
    -- next state with 'rst'
    begin
        if (not rst = '1') then
            currentState <= Reset;
        elsif RISING_EDGE(clk) then
            currentState <= nextState;
        end if;
    end process;
    
    nextStateTrans : process(currentState, titleStored, RTS, RTS_Count, EFK, CPU_DataStored, CPU_DataStart_En)
    begin
        case currentState is
            when Reset =>
                if (ResetCircle = "1111") then
                    nextState <= Init;
                else
                    nextState <= Reset;
                end if;
            when Init =>
                -- if all title stored in RAM, to Display
                if (titleStored = '1') then
                    nextState <= Display;
                else
                    nextState <= Init;
                end if;
            when Display =>
                -- if data come, goto dataFromCPU or dataFromKey
                if (RTS /= '1') AND (EFK = '0') then
                -- data from cpu not keybord:
                    if (RTS_Count = "11111") then
                        nextState <= dataFromCPU;
                    else
                        nextState <= Display;
                    end if;
                elsif (RTS = '1') AND (EFK /= '0') then
                -- data from keybord
                    nextState <= dataFromKey;
                else
                    nextState <= Display;
                end if;
            when dataFromCPU =>
                -- if all 4 byte data stored, goto Display; else, go on store data:
                if (not CPU_DataStored = '1') then
                    -- if data not already stored:
                    nextState <= dataFromCPU;
                else -- CPU data store finished
                    nextState <= Display;
                end if;
            when dataFromKey =>
                if (not keyDataStored = '1') then
                -- key data not yet stored:
                    nextState <= dataFromKey;
                else -- key data stored
                    nextState <= Display;
                end if;
            when others =>
                nextState <= Reset;
        end case;
    end process;
    
    stateBehave : process(currentState, ResetCircle)
    -- Flag Signals Control
    begin
        case currentState is
            when Reset =>
                if (ResetCircle /= "1111") then
                    ResetCircle_En <= '1';
                else
                    ResetCircle_En <= '0';
                end if;
                -- other flag and data signals:
                -- flags:
                RAM_we <= '0';
                RTS_En <= '0';
                VGA_En <= '0';
                titleStore_En <= '0';
                CPU_DataStart_En <= '0';
                keyDataStore_En <= '0';
                
            when Init =>
                if (titleStored = '1') then
                -- if all title stored in RAM, to Display
                    titleStore_En <= '0';
                    RAM_we <= '0';
                else
                -- storeing title:
                    titleStore_En <= '1';
                    RAM_we <= '1';
                end if;
                VGA_En <= '0';
                
            when Display =>
                if (RTS /= '1') AND (EFK = '0') then
                -- data from cpu not keybord: wait for RTS circles
                    if (RTS_Count /= "11111") then
                    -- if RTS count havn't finish:
                        RTS_En <= '1';
                    else
                        RTS_En <= '0';
                    end if;
                else
                    RTS_En <= '0';
                end if;
                RAM_we <= '0'; -- disable RAM write
                VGA_En <= '1';
                
            when dataFromCPU =>
                -- if all 4 byte data stored, goto Display; else, go on store data:
                if (CPU_DataStored /= '1') then
                    CPU_DataStart_En <= '1';
                    RAM_we <= '1';
                else -- CPU data store finished
                    RAM_we <= '1';
                    CPU_DataStart_En <= '0';
                end if;
                VGA_En <= '0';
            
            when dataFromKey =>
                if (not keyDataStored = '1') then
                -- key data not yet stored:
                    keyDataStore_En <= '1';
                    RAM_we <= '1';
                else -- key data stored
                    RAM_we <= '0';
                    keyDataStore_En <= '0';
                end if;
                VGA_En <= '0';
                
            when others =>
                RAM_we <= '0';
                RTS_En <= '0';
                VGA_En <= '0';
                titleStore_En <= '0';
                CPU_DataStart_En <= '0';
                keyDataStore_En <= '0';
                ResetCircle_En <= '0';
        end case;
    end process;

------------------------------------------------------------
-- STATE: RESET
-- MAIN PROCESS: CPUNT RESET_CIRCLE
------------------------------------------------------------
    countReset : process(ResetCircle_En, rst, clk)
    begin
        if RISING_EDGE(clk) then
            if (rst /= '1') then
                ResetCircle <= "0000";
            else 
                if (ResetCircle_En = '1') AND (ResetCircle /= "1111")then
                -- start Reset Circle count and don't full count
                    ResetCircle <= ResetCircle + '1';
                else
                    ResetCircle <= ResetCircle;
                end if;
            end if;
        end if;
    end process;

------------------------------------------------------------
-- STATE: INIT
-- MAIN PROCESS: LOAD TITLE TO RAM 0X00
------------------------------------------------------------
    loadTitle : process(titleStore_En, storeLineIdx, titleCharIdx)
    begin
        if (titleStore_En = '1')then
        -- load title enable
        -- step1: prepare RAM_din:
            case titleCharIdx is
                when "000" =>
                    currentStoreLine_Title <= char_c0(CONV_INTEGER(storeLineIdx));
                when "001" =>
                    currentStoreLine_Title <= char_c1(CONV_INTEGER(storeLineIdx));
                when "010" =>
                    currentStoreLine_Title <= char_c2(CONV_INTEGER(storeLineIdx));
                when "011" =>
                    currentStoreLine_Title <= char_c3(CONV_INTEGER(storeLineIdx));
                when "100" =>
                    currentStoreLine_Title <= char_c4(CONV_INTEGER(storeLineIdx));
                when others =>
                    currentStoreLine_Title <= X"0000";
            end case;
            -- send to RAM_din;
        -- step2: get RAM address:
            -- RAM_addr <= titleAdd + TO_STDLOGICVECTOR(TO_BITVECTOR(titleCharIdx) SLL 4) + storeLineIdx; -- base + char_bias + line_bias
            title_RAM_addr <= titleAdd + (titleCharIdx & "0000") + ("00000" & storeLineIdx); -- base + char_bias + line_bias
        -- step3: check if all title data is loaded
            if (storeLineIdx = "1111") AND (titleCharIdx = "100") then
                titleStored <= '1';
            else
                titleStored <= '0';
            end if;
        else
            titleStored <= '0';
        end if;
    end process;

------------------------------------------------------------
-- STATE: DISPLAY
-- MAIN PROCESS: COUNT RTS CIRCLE IF DATA COMING
--               SCAN RAM AND DISPLAY TO VGA
------------------------------------------------------------
    countRTS : process(RTS_En, clk)
    begin
        if RISING_EDGE(clk) then
            if (RTS_En = '1') AND (RTS_Count /= "11111") then
                RTS_Count <= RTS_Count + '1';
            elsif (RTS_En = '1') AND (RTS_Count = "11111") then
                RTS_Count <= RTS_Count;
            else
                RTS_Count <= "00000";
            end if;
        end if;
    end process;
    
    displayRAM : process(VGA_En, pixLocX, pixLocY)
    begin
        if (VGA_En = '1') then
        -- WIDTH , HIGTH
        -- title: 16 * 16 * 5 = 0:79 , 0:15 => [0:639, 0:127]
        -- formula: 8 * 16 * 6 = 0:47 , 16:31 => [0:383, 128:255]
        -- result: 8 * 16 * 4 = 0:31 , 32:47 => [0:255, 256:383]
        -- if display each pix for 8 times, area => 640 * 384
        -- SIGNALS
        -- signal VGA_char_idx : STD_LOGIC_VECTOR(3 downto 0); -- 15 chars
        -- signal VGA_inChar_line : STD_LOGIC_VECTOR(3 downto 0); -- 16 lines
        -- signal VGA_inChar_column : STD_LOGIC_VECTOR(3 downto 0); -- 16 lines max
        -- signal VGA_addr : STD_LOGIC_VECTOR(7 downto 0); -- 8bit address
        
            -- Step1: get char locate info:
            if (pixLocY >= 0) AND (pixLocY <= 127) then
            -- title:
                if (pixLocX >= 0) AND (pixLocX <= 639) then
                    VGA_inChar_column <= CONV_STD_LOGIC_VECTOR(pixLocX MOD 16, 4);
                    VGA_inChar_line <= CONV_STD_LOGIC_VECTOR(pixLocY, 4);
                    VGA_char_idx <= CONV_STD_LOGIC_VECTOR(pixLocX / 16, 4);
                else
                    VGA_inChar_column <= "0000";
                    VGA_inChar_line <= "0000";
                    VGA_char_idx <= "0000";
                end if;
            elsif (pixLocY >= 128) AND (pixLocY <= 255) then
            -- fomular
                if (pixLocX >= 0) AND (pixLocX <= 383) then
                    VGA_inChar_column <= CONV_STD_LOGIC_VECTOR(pixLocX MOD 8, 4);
                    VGA_inChar_line <= CONV_STD_LOGIC_VECTOR(pixLocY MOD 16, 4);
                    VGA_char_idx <= CONV_STD_LOGIC_VECTOR(5 + pixLocX / 16, 4);
                else
                    VGA_inChar_column <= "0000";
                    VGA_inChar_line <= "0000";
                    VGA_char_idx <= "0000";
                end if;
            elsif (pixLocY >= 256) AND (pixLocY <= 383) then
            -- result
                if (pixLocX >= 0) AND (pixLocX <= 255) then
                    VGA_inChar_column <= CONV_STD_LOGIC_VECTOR(pixLocX MOD 8, 4);
                    VGA_inChar_line <= CONV_STD_LOGIC_VECTOR(pixLocY MOD 16, 4);
                    VGA_char_idx <= CONV_STD_LOGIC_VECTOR(11 + pixLocX / 16, 4);
                else
                    VGA_inChar_column <= "0000";
                    VGA_inChar_line <= "0000";
                    VGA_char_idx <= "0000";
                end if;
            else
                VGA_inChar_column <= "0000";
                VGA_inChar_line <= "0000";
                VGA_char_idx <= "0000";
            end if;
            
            -- Step2: Get Address:
            if (VGA_char_idx <= "0100") then
            -- we're looking for a char in title
                VGA_addr <= VGA_char_idx & VGA_inChar_line;
            else
            -- we're looking for a number
                VGA_addr <= ('0' & VGA_char_idx & "000") + ("00000" & VGA_inChar_line(3 downto 1)); -- char idx and line idx / 2
            end if;
            -- send to RAM
            
            -- Step3: Get RGB_Info:
            if (VGA_char_idx <= "0100") then
            -- we're looking for a char in title, Blue
                RGB_Info <= "00" & RAM_dout(15 - CONV_INTEGER(VGA_inChar_column));
            else
            -- we're looking for a number, White
                -- VGA_inChar_line(0); -- '0' for upper line
                RGB_Info(0) <= RAM_dout(15 - CONV_INTEGER(VGA_inChar_line(0) & VGA_inChar_column(2 downto 0)));
                RGB_Info(1) <= RAM_dout(15 - CONV_INTEGER(VGA_inChar_line(0) & VGA_inChar_column(2 downto 0)));
                RGB_Info(2) <= RAM_dout(15 - CONV_INTEGER(VGA_inChar_line(0) & VGA_inChar_column(2 downto 0)));
            end if;
        else
            RGB_Info <= "000";
            VGA_inChar_column <= "0000";
            VGA_inChar_line <= "0000";
            VGA_char_idx <= "0000";
            VGA_addr <= "00000000";
        end if;
    end process;
------------------------------------------------------------
-- STATE: DATA_FROM_CPU
-- MAIN PROCESS: LOAD CPU DATA TO RAM 0X80
------------------------------------------------------------
    storeCPU_Data : process(CPU_DataStart_En, CPU_NumIdx, storeLineIdx)
    begin
        if (CPU_DataStart_En = '1') then
        -- start store data from CPU:
        -- step1: prepare RAM_din 
            case CPU_NumIdx is
            -- check which number to store:
                when "00" =>
                    currentBCD_CPU <= CPU_Data(15 downto 12);
                when "01" =>
                    currentBCD_CPU <= CPU_Data(11 downto 8);
                when "10" =>
                    currentBCD_CPU <= CPU_Data(7 downto 4);
                when "11" =>
                    currentBCD_CPU <= CPU_Data(3 downto 0);
                when others =>
                    currentBCD_CPU <= "0000";
            end case;
            case currentBCD_CPU is
            -- store current line by storeLineIdx:
                when "0000" =>
                    currentStoreLine_CPU <= num_0(CONV_INTEGER(storeLineIdx)) & num_0(CONV_INTEGER(storeLineIdx + '1'));
                when "0001" =>
                    currentStoreLine_CPU <= num_1(CONV_INTEGER(storeLineIdx)) & num_1(CONV_INTEGER(storeLineIdx + '1'));
                when "0010" =>
                    currentStoreLine_CPU <= num_2(CONV_INTEGER(storeLineIdx)) & num_2(CONV_INTEGER(storeLineIdx + '1'));
                when "0011" =>
                    currentStoreLine_CPU <= num_3(CONV_INTEGER(storeLineIdx)) & num_3(CONV_INTEGER(storeLineIdx + '1'));
                when "0100" =>
                    currentStoreLine_CPU <= num_4(CONV_INTEGER(storeLineIdx)) & num_4(CONV_INTEGER(storeLineIdx + '1'));
                when "0101" =>
                    currentStoreLine_CPU <= num_5(CONV_INTEGER(storeLineIdx)) & num_5(CONV_INTEGER(storeLineIdx + '1'));
                when "0110" =>
                    currentStoreLine_CPU <= num_6(CONV_INTEGER(storeLineIdx)) & num_6(CONV_INTEGER(storeLineIdx + '1'));
                when "0111" =>
                    currentStoreLine_CPU <= num_7(CONV_INTEGER(storeLineIdx)) & num_7(CONV_INTEGER(storeLineIdx + '1'));
                when "1000" =>
                    currentStoreLine_CPU <= num_8(CONV_INTEGER(storeLineIdx)) & num_8(CONV_INTEGER(storeLineIdx + '1'));
                when "1001" =>
                    currentStoreLine_CPU <= num_9(CONV_INTEGER(storeLineIdx)) & num_9(CONV_INTEGER(storeLineIdx + '1'));
                when "1010" =>
                    currentStoreLine_CPU <= num_plus(CONV_INTEGER(storeLineIdx)) & num_plus(CONV_INTEGER(storeLineIdx + '1'));
                when "1011" =>
                    currentStoreLine_CPU <= num_sub(CONV_INTEGER(storeLineIdx)) & num_sub(CONV_INTEGER(storeLineIdx + '1'));
                when "1100" =>
                    currentStoreLine_CPU <= num_mult(CONV_INTEGER(storeLineIdx)) & num_mult(CONV_INTEGER(storeLineIdx + '1'));
                when "1101" =>
                    currentStoreLine_CPU <= num_div(CONV_INTEGER(storeLineIdx)) & num_div(CONV_INTEGER(storeLineIdx + '1'));
                when "1110" =>
                    currentStoreLine_CPU <= num_equ(CONV_INTEGER(storeLineIdx)) & num_equ(CONV_INTEGER(storeLineIdx + '1'));
                when others =>
                    currentStoreLine_CPU <= X"0000";
            end case;
            -- RAM_din <= currentStoreLine_CPU; -- send current line to RAM
        -- step2: prepare RAM_addr
            -- RAM_addr <= resultAdd + TO_STDLOGICVECTOR(TO_BITVECTOR(CPU_NumIdx) SLL 4) + TO_STDLOGICVECTOR(TO_BITVECTOR(storeLineIdx) SRL 1); -- base + char_bias + line_bias
            CPU_RAM_addr <= resultAdd + ("00" & CPU_NumIdx & "0000") + ("00000" & storeLineIdx(3 downto 1)); -- base + char_bias + line_bias
        -- step3: check if all CPU data is loaded
            if (storeLineIdx = "1110") AND (CPU_NumIdx = "11") then
                CPU_DataStored <= '1';
            else
                CPU_DataStored <= '0';
            end if;
        else
            CPU_DataStored <= '0';
        end if;
    end process;

------------------------------------------------------------
-- STATE: DATA_FROM_KEY
-- MAIN PROCESS: LOAD KEY DATA TO RAM 0XA0
------------------------------------------------------------
    storeKey_Data : process(keyDataStore_En, keyNumIdx, storeLineIdx, rst)
    begin
        if (keyDataStore_En = '1') then
        -- start store data from CPU:
        -- step1: prepare RAM_din 
            currentBCD_Key <= Key_Data;
            case currentBCD_Key is
            -- store current line by storeLineIdx:
                when "0000" =>
                    currentStoreLine_Key <= num_0(CONV_INTEGER(storeLineIdx)) & num_0(CONV_INTEGER(storeLineIdx + '1'));
                when "0001" =>
                    currentStoreLine_Key <= num_1(CONV_INTEGER(storeLineIdx)) & num_1(CONV_INTEGER(storeLineIdx + '1'));
                when "0010" =>
                    currentStoreLine_Key <= num_2(CONV_INTEGER(storeLineIdx)) & num_2(CONV_INTEGER(storeLineIdx + '1'));
                when "0011" =>
                    currentStoreLine_Key <= num_3(CONV_INTEGER(storeLineIdx)) & num_3(CONV_INTEGER(storeLineIdx + '1'));
                when "0100" =>
                    currentStoreLine_Key <= num_4(CONV_INTEGER(storeLineIdx)) & num_4(CONV_INTEGER(storeLineIdx + '1'));
                when "0101" =>
                    currentStoreLine_Key <= num_5(CONV_INTEGER(storeLineIdx)) & num_5(CONV_INTEGER(storeLineIdx + '1'));
                when "0110" =>
                    currentStoreLine_Key <= num_6(CONV_INTEGER(storeLineIdx)) & num_6(CONV_INTEGER(storeLineIdx + '1'));
                when "0111" =>
                    currentStoreLine_Key <= num_7(CONV_INTEGER(storeLineIdx)) & num_7(CONV_INTEGER(storeLineIdx + '1'));
                when "1000" =>
                    currentStoreLine_Key <= num_8(CONV_INTEGER(storeLineIdx)) & num_8(CONV_INTEGER(storeLineIdx + '1'));
                when "1001" =>
                    currentStoreLine_Key <= num_9(CONV_INTEGER(storeLineIdx)) & num_9(CONV_INTEGER(storeLineIdx + '1'));
                when "1010" =>
                    currentStoreLine_Key <= num_plus(CONV_INTEGER(storeLineIdx)) & num_plus(CONV_INTEGER(storeLineIdx + '1'));
                when "1011" =>
                    currentStoreLine_Key <= num_sub(CONV_INTEGER(storeLineIdx)) & num_sub(CONV_INTEGER(storeLineIdx + '1'));
                when "1100" =>
                    currentStoreLine_Key <= num_mult(CONV_INTEGER(storeLineIdx)) & num_mult(CONV_INTEGER(storeLineIdx + '1'));
                when "1101" =>
                    currentStoreLine_Key <= num_div(CONV_INTEGER(storeLineIdx)) & num_div(CONV_INTEGER(storeLineIdx + '1'));
                when "1110" =>
                    currentStoreLine_Key <= num_equ(CONV_INTEGER(storeLineIdx)) & num_equ(CONV_INTEGER(storeLineIdx + '1'));
                when others =>
                    currentStoreLine_Key <= X"0000";
            end case;
            -- RAM_din <= currentStoreLine_Key; -- send current line to RAM
        -- step2: prepare RAM_addr
            -- RAM_addr <= resultAdd + TO_STDLOGICVECTOR(TO_BITVECTOR(CPU_NumIdx) SLL 4) + TO_STDLOGICVECTOR(TO_BITVECTOR(storeLineIdx) SRL 1); -- base + char_bias + line_bias
            key_RAM_addr <= numAdd + ("0" & keyNumIdx & "0000") + ("00000" & storeLineIdx(3 downto 1)); -- base + char_bias + line_bias
        -- step3: check if all CPU data is loaded
            if (storeLineIdx = "1110") AND (keyNumIdx = "101") then
                keyDataStored <= '1';
            else
                keyDataStored <= '0';
            end if;
        else
            keyDataStored <= '0';
        end if;
    end process;
    
------------------------------------------------------------
-- OTHER PROCESSES
-- MAIN PROCESS: UPDATE LINE AND COLUMN INDEXS
------------------------------------------------------------
    updateLineIdx : process(clk, CPU_DataStart_En, keyDataStore_En, titleStore_En)
    -- update storeLineIdx, when load data from CPU, keybord or Title:
    begin
        if RISING_EDGE(clk) then
            if ((CPU_DataStart_En = '1') OR (keyDataStore_En = '1') OR (titleStore_En = '1')) then
                if (CPU_DataStart_En = '1') AND (keyDataStore_En /= '1') AND (titleStore_En /= '1') then
                -- now loading CPU data, storeLineIdx += 2, then CPU_NumIdx += 1:
                    if (storeLineIdx = "1110") AND (CPU_NumIdx /= "11") then
                    -- a result num is finished loading, next line
                        storeLineIdx <= "0000";
                    elsif (storeLineIdx = "1110") AND (CPU_NumIdx = "11") then
                    -- all result data were finished
                        storeLineIdx <= storeLineIdx;
                    else
                    -- plus 2 line per time
                        storeLineIdx <= storeLineIdx + "0010";
                    end if;
                elsif (CPU_DataStart_En /= '1') AND (keyDataStore_En = '1') AND (titleStore_En /= '1') then
                -- now loading key data, storeLineIdx += 2, then keyNumIdx += 1:
                    if (storeLineIdx = "1110") AND (keyNumIdx /= "101") then
                        storeLineIdx <= "0000";
                    elsif (storeLineIdx = "1110") AND (keyNumIdx = "101") then
                        storeLineIdx <= storeLineIdx;
                    else
                        storeLineIdx <= storeLineIdx + "0010";
                    end if;
                elsif (CPU_DataStart_En /= '1') AND (keyDataStore_En /= '1') AND (titleStore_En = '1') then
                -- load title char data, storeLineIdx += 1, then titleCharIdx += 1:
                    if (storeLineIdx = "1111") AND (titleCharIdx /= "100") then
                        storeLineIdx <= "0000";
                    elsif (storeLineIdx = "1111") AND (titleCharIdx = "100") then
                        storeLineIdx <= storeLineIdx;
                    else
                        storeLineIdx <= storeLineIdx + '1';
                    end if;
                else
                    storeLineIdx <= "0000";
                end if;
            else
                storeLineIdx <= "0000";
            end if;
        end if;
    end process;
    
    updateTitleCharIdx : process(clk, titleStore_En, storeLineIdx)
    -- update titleCharIdx, load all 5 char
    begin
        if RISING_EDGE(clk) then
            if (titleStore_En = '1') then
            -- only when load title data
                if (storeLineIdx = "1111") AND (titleCharIdx /= "100") then
                    titleCharIdx <= titleCharIdx + '1';
                else
                    titleCharIdx <= titleCharIdx;
                end if;
            else
                titleCharIdx <= "000";
            end if;
        end if;
    end process;
    
    updateCPU_NumIdx : process(clk, CPU_DataStart_En, storeLineIdx)
    -- update CPU_NumIdx, load all 4 num
    begin
        if RISING_EDGE(clk) then
            if (CPU_DataStart_En = '1') then
            -- only when load CPU data
                if (storeLineIdx = "1110") AND (CPU_NumIdx /= "11") then
                    CPU_NumIdx <= CPU_NumIdx + '1';
                else
                    CPU_NumIdx <= CPU_NumIdx;
                end if;
            else
                CPU_NumIdx <= "00";
            end if;
        end if;
    end process;
    
    updateKeyNumIdx : process(clk, storeLineIdx, keyDataStore_En)
    -- update keyNumIdx, total 6 num
    -- NOTE: load 1 key num per time, so keyDataStore_En don't have to always be '1'
    begin
        if RISING_EDGE(clk) then
            if (CPU_DataStart_En = '1') then
            -- only when load CPU data
                if (storeLineIdx = "1110") AND (keyNumIdx /= "101") then
                    keyNumIdx <= keyNumIdx + '1';
                else
                    keyNumIdx <= keyNumIdx;
                end if;
            elsif (CPU_DataStart_En /= '1') AND (keyNumIdx /= "000") then
                keyNumIdx <= keyNumIdx;
            else
                keyNumIdx <= "000";
            end if;
        end if;
    end process;
    
end Behavioral;