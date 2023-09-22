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

library work;
use work.pack_xtras.all;

-- Note that hcount, vcount are 2 clocks ahead of hs, vs, video_on.
-- Delay explanation:
-- 1 cycle: because hs,vs,video_on, hcount, vcount are updated only when vga_tick = '1'
-- 1 cycle: because hs,vs are the outputs of a flip flop

-- Any change in the generation of vga_tick will extend the first cycle. For example, if vga_tick occurred every 4
-- cycles, we would have 3 cycles instead of 1 cycle, thereby hs,vs,video_on would be 4 cycles delayed.

-- Assumption: pixel clock: 25 MHz
-- VGA mode: 640x480 pixels
-- Field frequency: 60 Hz

-- 'hcount' (or 'vcount') and 'vga_tick' indicate  when we can put data.
-- The data (pixel) will pass through a register than only pass data when vga_tick = 1.
-- 'hs', 'vs', 'video_on' are synchronized with the output of the register
entity vga_display is
	generic (clock_pixel_ratio : integer:= 2); -- only 2,4 are available, others do not work!
	-- '2' means: 50MHz/25 MHz
	-- '4' means: 100MHz/25 MHz
	port ( clock: in std_logic;	
			 resetn: in std_logic;			   
			 vga_tick: out std_logic;
			 video_on: out std_logic;
			 hcount, vcount: out std_logic_vector (9 downto 0);
			 HS, VS: out std_logic );
end vga_display;

architecture structure of vga_display is

-- VGA 640-by-480 sync parameters
	constant bits_vga_tick: integer:= ceil_log2(clock_pixel_ratio);
   constant HD: integer:=640; -- horizontal display area
	constant HF: integer:=16; -- horizontal front porch
	constant HB: integer:=48; -- horizontal back porch
	constant HR: integer:=96; -- horizontal retrace
	constant VD: integer:=480; -- vertical display area
	constant VF: integer:= 10; -- vertical front porch
	constant VB: integer:= 33; -- vertical back porch
	constant VR: integer:=2; -- vertical retrace
		
	type state is (S1,S2);
	signal y: state;

	signal reset: std_logic;
	signal HC, VC: std_logic_vector (9 downto 0);	
	signal E_HC, E_VC, sclr_HC, sclr_VC: std_logic;
	signal d_VS, d_HS, e_VS, e_HS: std_logic;
	signal d_video_on, e_video_on: std_logic;
	signal sclr_vga_tick, vga_tick_buf: std_logic;

begin
	
	Transitions: process (resetn, clock)
	begin
		if resetn = '0' then
			y <= S1;
		elsif (clock'event and clock = '1') then
			case y is
				when S1 =>	y <= S2;
				when S2 =>	y <= S2;
			end case;
		end if;
	end process;

	Outputs: process (y, VC, HC, vga_tick_buf)
	begin
		-- Initialization of signals
		  sclr_vga_tick <= '0'; sclr_HC <= '0'; sclr_VC <= '0';
		d_VS <= '0'; e_VS <= '0'; d_HS <= '0'; e_HS <= '0';
		sclr_VC <= '0'; E_VC <= '0'; sclr_HC <= '0'; E_HC <= '0';
		d_video_on <= '0'; e_video_on <= '0';  
	
		case y is
			when S1 =>
				E_HC <= '1'; sclr_HC <= '1'; -- HC <= 0
				E_VC <= '1'; sclr_VC <= '1'; -- VC <= 0
				sclr_vga_tick <= '1'; -- vga_tick <= 0
				e_video_on <= '1'; d_video_on <= '0'; -- video_on <= 0;
			
			when S2 =>
				if vga_tick_buf = '1' then
					
					if (HC < HD) and (VC < VD) then -- HC < 640 & VC < 480
						d_video_on <= '1'; e_video_on <= '1'; -- video_on <= 1
					else
						d_video_on <= '0'; e_video_on <= '1'; -- video_on <= 0
					end if;
					
					if (VC >= VD + VF) and (VC <= VD+VF+VR-1) then -- 490 <= VC <= 491
						d_VS <= '0'; e_VS <= '1'; -- VS <= 0
						--d_VS <= '1'; e_VS <= '1'; -- VS <= 1
					else
						d_VS <= '1'; e_VS <= '1'; -- VS <= 1
						--d_VS <= '0'; e_VS <= '1'; -- VS <= 0
					end if;
					
					if (HC >= HD + HF) and (HC <= HD+HF+HR-1) then -- 656 <= HC <= 751
						d_HS <= '0'; e_HS <= '1';
						--d_HS <= '1'; e_HS <= '1';
					else
						d_HS <= '1'; e_HS <= '1';
						--d_HS <= '0'; e_HS <= '1';
					end if;
					
					if (HC = HD+HF+HB+HR-1) then
						E_HC <='1'; sclr_HC <= '1'; -- HC <= 0
						if (VC = VD+VF+VB+VR-1) then
							E_VC <= '1'; sclr_VC <= '1'; -- VC <= 0
						else
							E_VC <= '1'; -- VC <= VC + 1
						end if;
					else				
						E_HC <= '1'; -- HC <= HC + 1
					end if;
				end if;
				
		end case;
	end process;

-- 'vga_tick' implementation:
cVGA: my_genpulse_sclr generic map (COUNT => clock_pixel_ratio)
      port map (clock => clock, resetn => resetn, E => '1', sclr => sclr_vga_tick, z => vga_tick_buf);
	
da: dffe port map (d => d_VS, clrn => resetn, prn => '1', clk => clock, ena => e_VS, q => VS);
db: dffe port map (d => d_HS, clrn => resetn, prn => '1', clk => clock, ena => e_HS, q => HS);

dv: dffe port map (d => d_video_on, clrn => '1', prn => '1', clk => clock, ena => e_video_on, q => video_on);

cHC: my_genpulse_sclr generic map (COUNT => HD+HF+HB+HR)
     port map (clock => clock, resetn => resetn, E => E_HC, sclr => sclr_HC, q => HC);

cVC: my_genpulse_sclr generic map (COUNT => VD+VF+VB+VR)
     port map (clock => clock, resetn => resetn, E => E_VC, sclr => sclr_VC, q => VC);
	  
vga_tick <= vga_tick_buf; 
hcount <= HC;
vcount <= VC;

end structure;
