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

entity dino_control is
        
    generic (clock_pixel_ratio : integer:= 2;
             NPIXELS : INTEGER := 32;-- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525 -- this is the size of the image, anything over 128x128 takes a very long time to load -- going to keep the dino at 32x32
             nbits   : integer := 12;  -- number of color bits
                                    
            -- these are the sprite files for the dino, they dont need to be changed in the port map                
            FILE_IMG_1: STRING := "dino.txt";	
            FILE_IMG_2: STRING := "dino_left.txt";		
            FILE_IMG_3: STRING := "dino_right.txt"
           );
            -- I also want to add a position out line for the dino so we know were to  write it to in control file
            Port (clock      : IN std_logic;
                  button     : IN std_logic;
                  resetn     : in std_logic;
            	  inRAM_add  : IN std_logic_vector (ceil_log2(NPIXELS*NPIXELS)-1 downto 0); -- this is the adress line of the ram -- all the images should have the same adress line here so there is no need to make more signals
            	  height    : OUT integer range 0 to 100;
                  inRAM_odata: OUT std_logic_vector (15 downto 0)); -- this is where the pixel color will be sent out of
end dino_control;

architecture structure of dino_control is

component dino_statemachine 
      Port (clock          : IN std_logic;
            resetn         : IN std_logic;
            E              : IN std_logic;
            sclr           : IN std_logic;
            button         : IN std_logic; 
            height         : OUT integer range 0 to 100;      
            state_position : OUT integer range 0 to 4
            );
end component;

	constant NDATA: INTEGER := NPIXELS*NPIXELS;
	constant NBPR : INTEGER := ceil_log2(NPIXELS); -- bits per row (or per column)
	
	signal inRAM_idata        : std_logic_vector (15 downto 0); -- pixel colours
	signal inRAM_we, inRAM_en : std_logic; -- write and enable
	
	type chunk is array (2 downto 0) of std_logic_vector (15 downto 0);
	signal inRAM_odata_dino: chunk; --we can easily select which state we want with index i, index j is the pixel color
	
	signal E      : std_logic := '1';
	signal sclr   : std_logic := '0'; 
	     
	
	signal state_position: integer range 0 to 4;

begin

    --controls the position and state of the dino
    dino_state: dino_statemachine port map(clock, resetn, E, sclr, button, height, state_position);
     
    --these load the images to ram block            
    iram_dino: in_RAMgen generic map (nrows => npixels, ncols => npixels, FILE_IMG => FILE_IMG_1, INIT_VALUES => "YES")
           port map (clock, inRAM_idata, inRAM_add, inRAM_we, inRAM_en, inRAM_odata_dino(0));
            
    iram_dino_left: in_RAMgen generic map (nrows => npixels, ncols => npixels, FILE_IMG => FILE_IMG_2, INIT_VALUES => "YES") 
           port map (clock, inRAM_idata, inRAM_add, inRAM_we, inRAM_en, inRAM_odata_dino(1));        
            
    iram_dino_right: in_RAMgen generic map (nrows => npixels, ncols => npixels, FILE_IMG => FILE_IMG_3, INIT_VALUES => "YES")
           port map (clock, inRAM_idata, inRAM_add, inRAM_we, inRAM_en, inRAM_odata_dino(2));          
           
    inRAM_idata <= (others => '0'); inRAM_en <= '1'; inRAM_we <= '0'; -- enable needs to be high to read from the ram          
                     
    inRAM_odata <= inRAM_odata_dino(state_position); --which ram signal goes to our main control file             

end structure;
