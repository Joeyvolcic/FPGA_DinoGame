----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/13/2023 02:51:01 PM
-- Design Name: 
-- Module Name: button_press_extender - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity button_press_extender is
  Port (   clock      : IN STD_LOGIC;
           button     : IN STD_LOGIC;
           button_out : OUT STD_LOGIC );
end button_press_extender;

architecture Behavioral of button_press_extender is

    signal start_counter : std_logic; 
    signal counter_value : integer := 0;
    
begin

 process (clock, counter_value)
    begin
    if rising_edge(clock) then
            if (button = '1' ) then
                start_counter <= '1';
            elsif (counter_value = 0 or counter_value = integer ((10**7))) then
                start_counter <= '0';
            else    
                start_counter <= '1';
            end if;
            
            if start_counter = '1' then
                if counter_value = integer ((10**7)) then
                    counter_value <= 0;
                else
                    counter_value <= counter_value + 1;
                end if;
            end if;
        end if;
        
        if (counter_value > 1 and counter_value <= 3) then  
            button_out <= '1';
        else    
            button_out <= '0';
        end if;
        
    end process;


end Behavioral;
