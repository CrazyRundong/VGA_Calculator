library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- this model drives VGA output
-- clk @ 40MHz, display = 800 * 600 @ 60Hz
-- IN-SYSTEM PORT: pixLocX, pixLocY : INTEGER

entity VGA_DRIVER is
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
        vgaVSYNC : out STD_LOGIC -- in frame
    );
end VGA_DRIVER;

architecture BEHAVIOR of VGA_DRIVER is
-- signals:
signal xCount : INTEGER range 0 to 1055; -- 128, 88, 800, 40: 1056
signal yCount : INTEGER range 0 to 627; -- 4, 23, 600, 1: 628
signal xPos : INTEGER range 0 to 799;
signal yPos : INTEGER range 0 to 599;
signal isInScreen : STD_LOGIC; -- if current (xCount, yCount) is in screen
signal vgaHSYNCtemp : STD_LOGIC;
signal vgaVSYNCtemp : STD_LOGIC;

begin
    countX : process(clk)
    begin
        if RISING_EDGE(clk) then
            if (not rst = '1') then
                xCount <= 0;
            elsif (xCount = 1055) then
                xCount <= 0;
            else
                xCount <= xCount + 1;
            end if;
        end if;
    end process;
    
    countY : process(clk)
    begin
        if RISING_EDGE(clk) then
            if (not rst = '1') then
                yCount <= 0;
            elsif (xCount = 1055) then 
                if (yCount = 627) then
                    yCount <= 0;
                else
                    yCount <= yCount + 1;
                end if;
            end if;
        end if;
    end process;
    
    calcPos : process(xCount, yCount)
    begin
        if (xCount >= 216) AND (xCount < 1016) AND (yCount >= 27) AND (yCount < 626) then
            isInScreen <= '1';
            xPos <= xCount - 216;
            yPos <= yCount - 27;
        else
            isInScreen <= '0';
            xPos <= 0;
            yPos <= 0;
        end if;
    end process;
    -- output (x, y) to get pix color info:
    pixLocX <= xPos;
    pixLocY <= yPos;
    
    inLineSync : process(clk, rst)
    begin
        if (not rst = '1') then
            vgaHSYNCtemp <= '1';
        elsif RISING_EDGE(clk) then
            if (xCount < 128) then
                vgaHSYNCtemp <= '0';
            else
                vgaHSYNCtemp <= '1';
            end if;
        end if;
    end process;
    vgaHSYNC <= vgaHSYNCtemp;
    
    inFrameSync : process(clk, rst)
    begin
        if (not rst = '1') then
            vgaVSYNCtemp <= '1';
        elsif RISING_EDGE(clk) then
            if (yCount < 4) then
                vgaVSYNCtemp <= '0';
            else
                vgaVSYNCtemp <= '1';
            end if;
        end if;
    end process;
    vgaVSYNC <= vgaVSYNCtemp;
    
    -- most important: get color and display:
    vgaOUT : process(xPos, yPos)
    begin
        if (isInScreen = '1') and (en = '1') then
            vgaRGB <= pixInfo;
        else
            vgaRGB <= "000";
        end if;
    end process;
end BEHAVIOR;