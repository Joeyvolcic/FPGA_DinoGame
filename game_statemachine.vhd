library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use ieee.math_real.floor;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gsm is
    Port (  clock               : IN std_logic;
            resetn              : IN std_logic;
            button              : IN std_logic;
            collision_detection : IN std_logic;
            pause               : out std_logic   
            );
end gsm;

architecture structure of gsm is

type state is (S1,S2,S3);
signal w: state;
--S1, is initialize
--S2, is game start
--S3 is gg

begin
 
   
    Transitions: process (resetn, clock, button, collision_detection)
        begin
            if resetn = '0' then
                w <= S1;

            elsif (clock'event and clock = '1') then
           
            case w is
           
                when S1 => if ( button = '1' ) then w <= S2; end if;
                    pause <= '0';
               
                when S2 => if (collision_detection = '1') then w <= S3; end if;
                    pause <= '1';
               
                when S3 => if (button = '1') then w <= S2; end if;
                    pause <= '0';            
          
            end case;
        end if;
           

        end process;

end structure;