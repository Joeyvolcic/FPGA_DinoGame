-- Here we declare components, functions, procedures, and types defined by the user

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.log2;
use ieee.math_real.ceil;

package pack_xtras is
		
	type std_logic_2d is array (NATURAL RANGE <>, NATURAL RANGE <>) of std_logic;
		
	function ceil_log2(dato: in integer) return integer;
		
	component dffe
		 Port ( d : in  STD_LOGIC;
				  clrn: in std_logic:= '1';
				  prn: in std_logic:= '1';
				  clk : in  STD_LOGIC;
				  ena: in std_logic;
				  q : out  STD_LOGIC);
	end component;
	
	component vga_display
		generic (clock_pixel_ratio : integer:= 2); -- only 2,4 are available, others do not work!
		-- '2' means: 50MHz/25 MHz
		-- '4' means: 100MHz/25 MHz
		port ( clock: in std_logic;	
				 resetn: in std_logic;			   
				 vga_tick: out std_logic;
				 video_on: out std_logic;
				 hcount, vcount: out std_logic_vector (9 downto 0);
				 HS, VS: out std_logic );
	end component;
	
	component my_genpulse_sclr
        --generic (COUNT: INTEGER:= (10**8)/2); -- (10**8)/2 cycles of T = 10 ns --> 0.5 s
        generic (COUNT: INTEGER:= (10**2)/2); -- (10**2)/2 cycles of T = 10 ns --> 0.5us
        port (clock, resetn, E, sclr: in std_logic;
                Q: out std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
                z: out std_logic);
    end component;
    
	component my_rege
		generic (N: INTEGER:= 4);
			port ( clock, resetn: in std_logic;
					 E, sclr: in std_logic; -- sclr: Synchronous clear
					 D: in std_logic_vector (N-1 downto 0);
					 Q: out std_logic_vector (N-1 downto 0));
	end component;
	
	    component in_RAMgen
        generic ( nrows: integer:= 128;
                  ncols: integer:= 128;
	             -- NDATA : integer:= 128*128); -- 256*256, 128*128 -- DATA samples, each of B bits (B<=16)
                 -- so far for 2D memories, let's only accept PxP, where P is a power of 2
                 FILE_IMG: string:="myimg128_128.txt"; -- initial values for the memory: (256*256)x16 bits. This is fixed (for now).
                 INIT_VALUES: string:= "NO"); -- "YES" "NO". If "NO", FILE_IMG is not considered.
        port (   clock: in std_logic;	
                 inRAM_idata: in std_logic_vector (15 downto 0); -- up to 16 bits
                 inRAM_add: in std_logic_vector (integer(ceil(log2(real(nrows*ncols) ) ))-1 downto 0);
                 inRAM_we, inRAM_en: in std_logic;
                 inRAM_odata: out std_logic_vector (15 downto 0)); -- 16 bits output			 
    end component;
    
    component dino_control is

    generic (clock_pixel_ratio : integer:= 2;
             NPIXELS: INTEGER:= 32;-- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525 -- this is the size of the image, anything over 128x128 takes a very long time to load -- going to keep the dino at 32x32
             nbits: integer:= 12;  -- number of color bits
                                    
            -- these are the sprite files for the dino, they dont need to be changed in the port map                
            FILE_IMG_1: STRING:= "dino.txt";	
            FILE_IMG_2: STRING:= "dino_left.txt";		
            FILE_IMG_3: STRING:= "dino_right.txt"
           );
            
            Port (clock: in std_logic;
            button : in std_logic;
            inRAM_add: in std_logic_vector (ceil_log2(NPIXELS*NPIXELS)-1 downto 0);
            inRAM_odata: out std_logic_vector (15 downto 0);
            height : out integer range 0 to 100
            );
            
end component;

end package pack_xtras;

package body pack_xtras is
	
	function ceil_log2(dato: in integer) return integer is
		variable i, valor: integer;
	begin
		i:= 0; valor:= dato;
		while valor /= 1 loop
			valor := valor - (valor/2); -- 'valor/2' truncates the fractional part towards zero
			i:= i + 1;					-- Ej.: 15/2 = 7
		end loop;
		return i;
	end function ceil_log2;	
	
end package body pack_xtras;