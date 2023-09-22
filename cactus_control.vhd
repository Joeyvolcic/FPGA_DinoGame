library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use ieee.math_real.floor;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.pack_xtras.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cactus_control is
        
    generic (clock_pixel_ratio : integer:= 2;
             NPIXELS : INTEGER := 32;-- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525 -- this is the size of the image, anything over 128x128 takes a very long time to load -- going to keep the dino at 32x32
             nbits   : integer := 12;  -- number of color bits
                                    
            -- these are the sprite files for the dino, they dont need to be changed in the port map                
             FILE_IMG_1: STRING := "cactus3.mem"	
             );
    -- I also want to add a position out line for the dino so we know were to  write it to in control file
    Port (clock      : IN std_logic;
          button     : IN std_logic;
          resetn     : in std_logic;
          inRAM_add  : IN std_logic_vector (ceil_log2(NPIXELS*NPIXELS)-1 downto 0); -- this is the adress line of the ram -- all the images should have the same adress line here so there is no need to make more signals
          distance   : OUT integer range 0 to 600;
          inRAM_odata: OUT std_logic_vector (15 downto 0)); -- this is where the pixel color will be sent out of
end cactus_control;

architecture structure of cactus_control is

component cactus_statemachine is
    Port (  clock          : IN std_logic;
            resetn         : IN std_logic;
            E              : IN std_logic;
            sclr           : IN std_logic;
            button         : IN std_logic; 
            distance       : OUT integer range 0 to 1000
            );
end component;

	constant NDATA: INTEGER := NPIXELS*NPIXELS;
	constant NBPR : INTEGER := ceil_log2(NPIXELS); -- bits per row (or per column)
	
	signal inRAM_idata        : std_logic_vector (15 downto 0); 
	signal inRAM_we, inRAM_en : std_logic; -- write and enable
	
--	signal resetn : std_logic := '1';
	signal sclr   : std_logic := '0'; 
	signal E      : std_logic := '1';     
	

begin 

    

    cactus_state: cactus_statemachine port map(clock, resetn, E, sclr, button, distance);                  
                     
    iram_cactus: in_RAMgen generic map (nrows => npixels, ncols => npixels, FILE_IMG => FILE_IMG_1, INIT_VALUES => "YES")
           port map (clock, inRAM_idata, inRAM_add, inRAM_we, inRAM_en, inRAM_odata);
             
           
    inRAM_idata <= (others => '0'); inRAM_en <= '1'; inRAM_we <= '0'; -- enable needs to be high to read from the ram          
                     

end structure;
