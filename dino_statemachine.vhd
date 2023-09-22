library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use ieee.math_real.floor;



entity dino_statemachine is
  Port (clock   : IN std_logic;
        resetn  : IN std_logic;
        E       : IN std_logic;
        sclr    : IN std_logic;
        button  : IN std_logic;
        height        : OUT integer range 0 to 100;      
        state_position: OUT integer range 0 to 4  
        );
        
end dino_statemachine;

architecture structure of dino_statemachine is

component my_genpulse_sclr is	
	generic (COUNT: INTEGER:= (10**2)/2); -- (10**2)/2 cycles of T = 10 ns --> 0.5us
	port (clock  : IN std_logic;
	      resetn : IN std_logic;
	      E      : IN std_logic;
	      sclr   : IN std_logic;
		  Q      : OUT std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
		  z      : OUT std_logic);
end component;

type state is (S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13); -- I dont know if it is better to pass out the state signal or it is better to pass out a binary number, or maybe an integer
signal y: state; -- animation state

constant max_amimation_count: integer := 10**8/2;

signal animation_tick: std_logic;
signal amimation_sclr: std_logic;

begin

animation_clock: my_genpulse_sclr generic map (COUNT => max_amimation_count / 6) --this determines the speed of the animation
     port map (clock => clock, resetn => resetn, E => E, sclr => sclr, q => open, z => animation_tick);
    

animation_transitions: process (resetn, animation_tick, button)
	begin
	
		--S1, S2, is normal dino
        --S3, S4 is the right foot up
        --S5, S6 is the left foot up
        --rest are jump
        
        if resetn = '0' then
            y <= S1; 
        elsif (button = '1') then -- asyncronous jump, it feels weird if it only happens on an animation tick
                y <= S8;
        elsif (animation_tick'event and animation_tick = '1') then
            case y is
                when S1 => y <= S2; 
                    state_position <= 0;
                    height <= 0;
                    
                when S2 => y <= S3;
                    state_position <= 0;
                    height <= 0;
                    
                when S3 => y <= S4;  
                    state_position <= 1;
                    height <= 0;
                    
                when S4 => y <= S5; 
                 
                    state_position <= 1;
                    height <= 0;
                    
                when S5 =>   y <= S6; 
                    state_position <= 2;
                    height <= 0;
                    
                when S6 =>   y <= S3;  
                
                    state_position <= 2;                                
                    height <= 0;
                when S7 => y <= S8; 
                
                    state_position <= 0;
                    height <= 18;
                    
                when S8 => y <= S9;
                    state_position <=0;
                    height <= 33;
                    
                when S9 => y <= S10;  
                
                    state_position <= 0;
                    height <= 42;
                    
                when S10 => y <= S11; 
                 
                    state_position <= 0;
                    height <= 45;
                    
                when S11 => y <= S12; 
                    state_position <= 0;
                    height <= 42;
                    
                when S12 => y <= S13;  
                    state_position <= 0;                                
                    height <= 33; 
                
                when S13 => y <= S2;  
                    state_position <= 0;                                
                    height <= 18;             
            end case;
        end if;
    end process;

end structure;













