---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2013).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity my_genpulse_sclr is
	generic (COUNT: INTEGER:= (10**8)/2); -- (10**8)/2 cycles of T = 10 ns --> 0.5 s
	--generic (COUNT: INTEGER:= (10**2)/2); -- (10**2)/2 cycles of T = 10 ns --> 0.5us
	port (clock, resetn, E, sclr: in std_logic;
			Q: out std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
			z: out std_logic);
end my_genpulse_sclr;

architecture Behavioral of my_genpulse_sclr is
	constant nbits: INTEGER:= integer(ceil(log2(real(COUNT))));
	signal Qt: std_logic_vector (nbits -1 downto 0);
begin

	process (resetn, clock)
	begin
		if resetn = '0' then
			Qt <= (others => '0');
		elsif (clock'event and clock = '1') then
			if E = '1' then
				if sclr = '1' then
					Qt <= (others => '0');
				else
					if Qt = conv_std_logic_vector (COUNT-1,nbits) then
						Qt <= (others => '0');
					else
						Qt <= Qt + conv_std_logic_vector (1,nbits);
					end if;
				end if;
			end if;
		end if;
	end process;
	
	z <= '1' when Qt = conv_std_logic_vector (COUNT-1,nbits) else '0';
   Q <= Qt;
	
end Behavioral;

