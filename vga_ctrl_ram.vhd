---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2014).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------
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
--use work.lpm_components.all;

-- NPIXELS: Only square images allowed, with NPIXELS being a power of 2.
entity vga_ctrl_ram is	
	generic (clock_pixel_ratio : INTEGER := 2;    -- dont change
	         NPIXELS           : INTEGER := 32;   -- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525 -- this is the size of the image, anything over 128x128 takes a very long time to load	
	         nbits             : INTEGER := 12);  -- number of bits for each pixel. Example: 3, 8, 12, 15 
	            
	port (   clock  : in std_logic;	
			 resetn : in std_logic;	   
			 SW     : in std_logic_vector (nbits-1 downto 0);
			 button : in std_logic;
			 RGB    : out std_logic_vector (nbits-1 downto 0);
			 HS, VS : out std_logic;
			 vga_clk: out std_logic;
			 
			 -- debug signals
			 video_on      : out std_logic;
			 hcount, vcount: out std_logic_vector (9 downto 0));
end vga_ctrl_ram;

architecture structure of vga_ctrl_ram is


component dino_control is
    generic (clock_pixel_ratio : integer:= 2;
             NPIXELS           : INTEGER:= 32;-- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525 -- this is the size of the image, anything over 128x128 takes a very long time to load -- going to keep the dino at 32x32
             nbits             : integer:= 12;  -- number of color bits
                                    
            -- these are the sprite files for the dino, they dont need to be changed in the port map                
            FILE_IMG_1: STRING := "dino.txt";	
            FILE_IMG_2: STRING := "dino_left.txt";		
            FILE_IMG_3: STRING := "dino_right.txt"
           );
            
    Port (clock       : in std_logic;
          button      : in std_logic;
          resetn      : in std_logic;
          inRAM_add   : in std_logic_vector (ceil_log2(NPIXELS*NPIXELS)-1 downto 0);
          inRAM_odata : out std_logic_vector (15 downto 0);
          height      : out integer range 0 to 100);       
    end component;
    
 component cactus_control is       
    generic (clock_pixel_ratio : integer:= 2;
             NPIXELS : INTEGER := 32;-- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525 -- this is the size of the image, anything over 128x128 takes a very long time to load -- going to keep the dino at 32x32
             nbits   : integer := 12;  -- number of color bits                              
                 
            -- these are the sprite files for the cactus, they dont need to be changed in the port map                
             FILE_IMG_1: STRING := "cactus3.txt"    
             );
             
     Port (clock      : IN std_logic;
           button     : IN std_logic;
           resetn     : IN std_logic;
           inRAM_add  : IN std_logic_vector (ceil_log2(NPIXELS*NPIXELS)-1 downto 0); -- this is the adress line of the ram -- all the images should have the same adress line here so there is no need to make more signals
           distance   : OUT integer range 0 to 1000;
           inRAM_odata: OUT std_logic_vector (15 downto 0)); -- this is where the pixel color will be sent out of
end component;   

component gsm 
        Port ( 
        clock               : IN std_logic;
        resetn              : IN std_logic;
        button              : IN std_logic;
        collision_detection : IN std_logic;
        pause               : OUT std_logic   
        );
end component;

	
	constant NDATA      : INTEGER:= NPIXELS*NPIXELS;
	constant NBPR       : INTEGER:= ceil_log2(NPIXELS); -- bits per row (or per column)

    signal height       : integer range 0 to 100; -- dino jump height   
	signal inRAM_add    : std_logic_vector (ceil_log2(NDATA)-1 downto 0); -- this is the adress line of the ram
	signal inRAM_odata  : std_logic_vector (15 downto 0); -- this is the output of the ram, ie the pixel colour
	
    signal inRAM_add_cactus   : std_logic_vector (ceil_log2(NDATA)-1 downto 0); -- this is the adress line of the ram
    signal inRAM_odata_cactus : std_logic_vector (15 downto 0); -- this is the output of the ram, ie the pixel colour
    signal distance           : integer range 0 to 1000; -- cactus position change
    
    signal pause          : std_logic; -- determines if the objects move
	
	signal RGB_buf        : std_logic_vector (nbits-1 downto 0);
	signal vga_tick       : std_logic;
	signal video_on_buf   : std_logic;
	signal hcount_buf     : std_logic_vector (9 downto 0);
    signal vcount_buf     : std_logic_vector (9 downto 0);

	signal in_RGB         : std_logic_vector (nbits-1 downto 0);
	signal sel_RGB_dino   : std_logic; -- only dino display pixels
	signal sel_RGB_cactus : std_logic; -- only cactus display pixels
	signal sel_RGB_ground : std_logic; 
	signal sel_RGB        : std_logic_vector (2 downto 0); -- this controls all the display pixels
	
	
	
	signal collision_detection: std_logic;  
begin
  
    vga_clk <= vga_tick;
    
    vga: vga_display generic map (clock_pixel_ratio => clock_pixel_ratio)
          port map (clock, resetn, vga_tick, video_on_buf, hcount_buf, vcount_buf, HS,VS);
         
    -- game state control      
    game_state: gsm port map(clock => clock, resetn => resetn, button => button, collision_detection => collision_detection, pause => pause);
     
    -- all the rom control modules should go right here, they should send out an adress line and a data line
    dino: dino_control port map (clock => clock, resetn => pause, button => button, inRAM_add => inRAM_add, inRAM_odata => inRAM_odata, height => height);  
    cuctus: cactus_control port map(clock => clock, resetn => pause, button => button, inRAM_add => inRam_add_cactus, distance => distance, inRAM_odata => inRAM_odata_cactus);
    --end control modules  
             
   
    -- these calculate all the positions on the screen where we want to display stuff
            --dino signals
            inRam_add <= (vcount_buf(NBPR-1 downto 0) + 15 + height) -- height is the jump change
                        & (hcount_buf(NBPR-1 downto 0) + 28); -- 28 is the offset value to center the sprite in the window
            
            sel_RGB_dino <= '1' when 
                        (100 < hcount_buf) and (hcount_buf  < (2**NBPR) + 100) and (240 - height < vcount_buf) and (vcount_buf < (2**NBPR) + 240 - height) -- we can add to the values of hcount_buff and 2**NBPR and this will change the position the ram is written to, thisi changes the position we look at
                        and inRAM_odata /= "111111111111" else '0'; -- this checks to see if the backround in the ram is white, if its white we display sw colour instead
            
            --cactus signals
            inRam_add_cactus <= (vcount_buf(NBPR-1 downto 0) + 15)
                              & (hcount_buf(NBPR-1 downto 0) + 28 - distance); -- formula for how much we need to add is vchange % NPIXELS (vchange mod 32), this is how we change the location of the image being displayed 
            
            sel_RGB_cactus <= '1' when -- the window adjustment is opposite of the adress adjustment
                (50 + distance < hcount_buf) and (hcount_buf  < (2**NBPR) + 50 + distance) and (240 < vcount_buf) and (vcount_buf < (2**NBPR) + 240 ) -- we can add to the values of hcount_buff and 2**NBPR and this will change the position the ram is written to, thisi changes the position we look at
                and inRAM_odata_cactus /= "111111111111" else '0';
                
            --ground signals    
            sel_RGB_ground <= '1' when
                (50 < hcount_buf) and (hcount_buf  < 590) and (272 < vcount_buf) and (vcount_buf < 274) -- we can add to the values of hcount_buff and 2**NBPR and this will change the position the ram is written to, thisi changes the position we look at
                 else '0';      
                   
    
            collision_detection <= sel_RGB_dino and sel_RGB_cactus; -- since we know the position on the screen with select signals, if they are both one there must be a collision
            
            -- allows us to select what happens when we display pixels
            sel_RGB(2) <= sel_RGB_dino;
            sel_RGB(1) <= sel_RGB_cactus;
            sel_RGB(0) <= sel_RGB_ground;
        
     

            with sel_RGB select    
            in_RGB <= inRAM_odata(11 downto 0) when "100",        -- dino display only
                      inRAM_odata_cactus(11 downto 0) when "010", -- cactus display only
                      "111100000000" when "110",                  -- collision pixel display
                      "010101010101" when "001",                  -- ground displayed
                      sw when others;                             -- background colour
                         
             
    ro: my_rege generic map (N => nbits)
        port map (clock => clock, resetn => '1', E => vga_tick, sclr => '0', D => in_RGB, Q => RGB_buf);
    
         RGB <= rgb_buf when video_on_buf = '1' else (others => '0');
         -- This is very important, zeros MUST BE WRITEN when we are in the back or front porch	 	 
         -- Usually, the controller will perform this task by itself:
         -- 'vga_display' provides hc, vc, so that we know that we are not in hc=[0,639], we MUST write zero
    
    video_on <= video_on_buf;
    hcount <= hcount_buf;
    vcount <= vcount_buf;

end structure;