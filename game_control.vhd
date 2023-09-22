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

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.pack_xtras.all;
--use work.lpm_components.all;

-- Nexys-4 Board:
-- 12-bit color: R (4 bits), G (4 bits), B (4 bits)
-- 4-bit grayscale images: R=G=B
entity game_control is
	generic (clock_pixel_ratio : integer:= 4); -- (Available clock)/25MHz (pixel clock)
				                               -- Only two available
	port (   clock  : in std_logic;	
			 resetn : in std_logic; -- low level reset		   
			 SW     : in std_logic_vector (11 downto 0); -- color 
			 button : in std_logic;
			 
			 R, G, B: out std_logic_vector (3 downto 0); -- component color
			 HS, VS : out std_logic); -- clock syncs
			 
			 --vga_clk: out std_logic;
			 -- debug signals
			 --video_on: out std_logic;
			 --hcount, vcount: out std_logic_vector (9 downto 0));
end game_control;

architecture structure of game_control is

	component vga_ctrl_ram
		generic (clock_pixel_ratio : integer:= 2;    -- changes clock dont use
				 NPIXELS           : INTEGER:= 32;   -- Picture: NPIXELSxNPIXELS. Max for Nexys-4: 525x525
				 nbits             : integer:= 12);  -- number of bits for each pixel. Example: 3, 8, 12, 15 
					
		port ( clock    : in std_logic;	
				 resetn : in std_logic;	   
				 SW     : in std_logic_vector (nbits-1 downto 0);
				 button : in std_logic;
				 RGB    : out std_logic_vector (nbits-1 downto 0);
				 HS, VS : out std_logic;
				 vga_clk: out std_logic;

				 -- debug signals
				 video_on       : out std_logic;
				 hcount, vcount : out std_logic_vector (9 downto 0));
	end component;

    signal RGB      : std_logic_vector (11 downto 0);
	signal vga_clk  : std_logic;
	
	-- debug signals
	signal video_on : std_logic; 
	signal hcount   : std_logic_vector (9 downto 0);
	signal vcount   : std_logic_vector (9 downto 0);
	
begin
		  ramd: vga_ctrl_ram generic map (clock_pixel_ratio, NPIXELS => 32, nbits => 12) 
				  port map (clock, resetn, SW, button, RGB, HS,VS, vga_clk, video_on, hcount, vcount);
			R <= RGB(11 downto 8); G <= RGB (7 downto 4); B <= RGB (3 downto 0);

end structure;
