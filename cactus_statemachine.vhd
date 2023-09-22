----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/08/2023 12:58:03 PM
-- Design Name: 
-- Module Name: dino - structure
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

entity cactus_statemachine is
    Port (  clock          : IN std_logic;
            resetn         : IN std_logic;
            E              : IN std_logic;
            sclr           : IN std_logic;
            button         : IN std_logic; 
            distance       : OUT integer range 0 to 1000
            -- collision signal
            );
end cactus_statemachine;

architecture structure of cactus_statemachine is

component my_genpulse_sclr is
	--generic (COUNT: INTEGER:= (10**8)/2); -- (10**8)/2 cycles of T = 10 ns --> 0.5 s
	generic (COUNT: INTEGER:= (10**8)/2); -- (10**2)/2 cycles of T = 10 ns --> 0.5us
	port (clock, resetn, E, sclr: in std_logic;
			Q: out std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
			z: out std_logic);
end component;

type state is (S1,S2,S3,S4); -- I dont know if it is better to pass out the state signal or it is better to pass out a binary number, or maybe an integer
signal w: state;
--S1, is normal dino
--S2, is the right foot up
--S3 is the left foot up
--S4 is dead dino
	
signal z: std_logic;
signal distance_temp: integer range 0 to 1000 := 450;

begin

    
    cHC: my_genpulse_sclr generic map (COUNT => (10**8)/160) -- this controls the length between anination frames, i.e how fast the cactus will move
         port map (clock => clock, resetn => resetn, E => E, sclr => sclr, q => open, z => z);
    
    Transitions: process (resetn, z, distance_temp)
        begin
            if resetn = '0' then
                w <= S1;
            elsif (z'event and z = '1') then
                case w is
                    when S1 =>	w <= S2;
                        
                    when S2 =>	 w <= S3; -- if collision = '1' then we need to pause this process
                        distance_temp <= 450;
                    when S3 =>	if (distance_temp <= 10) then w <= S4; end if; 
                         distance_temp <= distance_temp - 1; -- sliding animation
                    when S4 => w <= S1; 
                         distance_temp <= 1000; -- removes from screen
                        
                end case;
            end if;
            
            distance  <= distance_temp;
        end process;

end structure;
