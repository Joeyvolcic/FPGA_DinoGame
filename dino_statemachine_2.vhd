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

entity dino_statemachine_2 is
    Port (  clock          : IN std_logic;
            resetn         : IN std_logic;
            E              : IN std_logic;
            sclr           : IN std_logic;
            button         : IN std_logic; 
            height         : OUT integer range 0 to 100;      
            state_position : OUT integer range 0 to 4
            );
end dino_statemachine_2;

architecture structure of dino_statemachine_2 is

component my_genpulse_sclr is
	--generic (COUNT: INTEGER:= (10**8)/2); -- (10**8)/2 cycles of T = 10 ns --> 0.5 s
	generic (COUNT: INTEGER:= (10**8)/2); -- (10**2)/2 cycles of T = 10 ns --> 0.5us
	port (clock, resetn, E, sclr: in std_logic;
			Q: out std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
			z: out std_logic);
end component;

type state is (S1,S2,S3,S4); -- I dont know if it is better to pass out the state signal or it is better to pass out a binary number, or maybe an integer
signal y: state;
--S1, is normal dino
--S2, is the right foot up
--S3 is the left foot up
--S4 is dead dino
	
signal z: std_logic;


begin

    
    cHC: my_genpulse_sclr generic map (COUNT => (10**8)/2)
         port map (clock => clock, resetn => resetn, E => E, sclr => sclr, q => open, z => z);
    
    Transitions: process (resetn, z)
        begin
            if resetn = '0' then
                y <= S2;
            elsif (z'event and z = '1') then
                case y is
                    when S1 =>	y <= S2;
                        state_position <= 0;
                    when S2 =>	y <= S3;
                        state_position <= 1;
                    when S3 =>	y <= S1;
                        state_position <= 2;
                    when S4 =>	y <= S1; -- still needs logic behine when the state is triggered
                        state_position <= 4;
                end case;
            end if;
        end process;

end structure;
































