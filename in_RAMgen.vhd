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
use ieee.math_real.log2;
use ieee.math_real.ceil;

use std.textio.all; -- for text file definitions
use ieee.std_logic_textio.all; -- for proper read/write/hread/hwrite

library UNISIM;
use UNISIM.vcomponents.all;

-- This only works for Artix-7 or 7-series PL
-- Primitive used: RAM36E1:
-- ***********************
-- Data: in blocks of 2Kx18. Actually 2Kx16 (the others are parity bits)

-- The way to see this memory is as a memory of NDATA positions, each with B bits (B<=16)
-- Address: 0 to nrows*ncols-1. This memory stores a nrows*ncols array on the memory in a raster scan fashion
-- nrows does not have to be equal to ncols.
 
entity in_RAMgen is	
	generic ( nrows: integer:= 128;
	          ncols: integer:= 128; -- NDATA : nrows*ncols pixels, each of B bits (B<=16)
	          -- Restriction: Is using FILE_IMG (i.e., INIT_VALUES="YES"), nrows*ncols MUST BE a multiple of 16.
	         FILE_IMG: string:="myimg128_128.txt"; -- Optional argument. Only used when INIT_VALUES="YES".
	                                                -- It specifies the initial memory values.
	         INIT_VALUES: string:= "YES"); -- "YES" "NO". If "NO", FILE_IMG is not considered.
	                                      -- If "YES", you MUST specify a valid text file:
	                                      -- The text file will hve nrows*ncols rows, each row made up of 4 hex characters (16 bits)
	                                      -- See example: "my_img128_128.txt"
	port (   clock: in std_logic;	
			 inRAM_idata: in std_logic_vector (15 downto 0); -- up to 16 bits.
			 inRAM_add: in std_logic_vector (integer(ceil(log2(real(nrows*ncols) ) ))-1 downto 0); -- need to figure out what this does, I think this controls the position
			 inRAM_we, inRAM_en: in std_logic;
			 inRAM_odata: out std_logic_vector (15 downto 0)); -- 16 bits output			 
end in_RAMgen;

architecture structure of in_RAMgen is
	
	constant NDATA: INTEGER:= nrows*ncols;
	constant N: INTEGER:= (NDATA-1)/2048 + 1; -- n: # of BRAMs = ceil(NDATA/2048)-- 2048: Size of each RAMB18E1 memory block
	constant Nrows64x4: integer:= (NDATA-1)/16 + 1; -- ceil(NDATA/16): number of rows with 64x4 bits in nrows*ncols 16-bit pixels
	-- note that our Get_Rows function doesn't work if Nrows64x64 is not a multiple of 16 while INIT_VALUES = "YES"
	--    we might need to fix this in the future.
	
	constant NADD: INTEGER:= integer(ceil(log2(real(NDATA) ) )); -- number of bits for the address
		
	type chunk is array (nrows*ncols - 1 downto 0) of std_logic_vector (15 downto 0); -- Data size: 16 bits
	
	-- 2Kx16 memory: INIT: 128 rows, each holding 64 hexadecimal values. 128*(64*4)/16 = 2048 16-bit words
	type chunk_row is array (128*N -1 downto 0) of bit_vector (64*4 - 1 downto 0);
	
	-- we have to read the pixel values from the text file
	impure function ReadfromFile (FileName : in string; nnrows: in integer; nncols: in integer) return chunk is
		--FILE IN_FILE  : text open read_mode is FileName; -- VHDL 93 declaration\
		FILE IN_FILE  : text open READ_MODE is FileName; 
		-- Vivado bug: if it has to open it, if the file is bigger than 2^13, synthesis takes like 1 hour.. so don't even open the file
		variable BUFF : line;
		variable val  : chunk;
	begin

-- This is as specified in Vivado synthesis guide (though original 'read' is used, but this was tested and the synthesis time was the same)
		-- The problem is when using more than 2^13 as nncols by nnrows, it takes a very long time! This doesn't happen in ISE
--		for i in 0 to nncols*nnrows-1 loop -- order in file is that of Raster Scan (row by row)
--			readline (IN_FILE, BUFF);
--			--hread (BUFF, val(i)); -- read hexadecimal, but output is in binary (unsigned)
--			read (BUFF, val(i)); -- read hexadecimal, but output is in binary (unsigned)
--		end loop;

-- IMPORTANT: problem is the size of the index in the loop. If it is too much, it will take forever
                for i in 0 to nnrows-1 loop
                    for j in 0 to nncols-1 loop
                         readline(IN_FILE, BUFF);
                         hread (BUFF, val(i*ncols + j)); --read (BUFF, val(i*nncols + j));
                    end loop;
                end loop;
		return val;
	end function;

	impure function Get_Rows (FileName: in string) return chunk_row is -- impure: used when it depends on a text file, if the file changes, the function output will change.
	-- The signal IN_val goes from 0 to nrows*ncols-1
		variable valr: chunk_row;
		variable IMG_val: chunk;
	begin
	    if INIT_VALUES = "YES" then
		      IMG_val:= ReadfromFile(FileName,ncols,nrows);
		      -- There are N BRAMs (N=ceil(nrows*ncols/2048). Each BRAM has 2048 16-bit words, or 128 256-bit words.  
		      --   The INIT values of the BRAM are specified as 128 rows, each row holding a 256-bit word
		      --   We then need to fill up 128*N INIT rows.
		      --   Available data: nrows*ncols 16-bit words, or ceil(nrows*ncols/16) 256-bit words. Note that ceil(nrows*ncols/16) <= 128*N
            --   We fill up data from row 0 to 128*N - 1:
            --  We first fill up INIT data from row 0 to Nrows64x4=ceil(nrows*ncols/16)
            for i in 0 to Nrows64x4 - 1 loop -- number of INIT rows we need to fill up (for all generated memories)
                -- Each row has 64 hexadecimal values, or 256 bits
                for j in 0 to 15 loop -- we complete each row by piecing together 16 16-bit words (each memory position is one 16-bit data word)
                    --valr(i)(64*4 - j*16 -1 downto 64*4 - (j+1)*16) := to_bitvector(IN_val(i*16 + j)); 
                    valr(i)(64*4 - j*16 -1 downto 64*4 - (j+1)*16) := to_bitvector(IMG_val(i*16 + 15-j)); -- reverse pixel order, start from the right (this is how INIT is organized)
                                                                       -- data(0): |IMG_val(15)|IMG_val(14)|...|IMG_val(0)|. IMG_val(0) is the first pixel (raster scan starting from 0,0)				                                                   
                end loop;
            end loop;

            for i in Nrows64x4 to 128*N- 1 loop -- remaining INIT rows we need to fill up
                -- Each row has 64 hexadecimal values, or 256 bits
                valr(i) := (others => '0');				                                                   
            end loop;            
            
        else
            for i in 0 to 128*N-1 loop
                valr(i) := (others => '0');
            end loop;
        end if;		
		return valr;
	end function;

	constant DATA: chunk_row:= Get_Rows(FILE_IMG);
	
	type chunkDv is array (N-1 downto 0) of std_logic_vector (31 downto 0);
	signal DOv: chunkDv;
	
	type chunkwev is array (N-1 downto 0) of std_logic_vector (3 downto 0);
	signal wev: chunkwev;
	
	signal DI: std_logic_vector (31 downto 0);
	signal TADDR: std_logic_vector (15 downto 0);
	signal addr: std_logic_vector (10 downto 0); -- LSBs (for the 2Kx16 BRAMs)
    signal sel: std_logic_vector (NADD-11-1 downto 0); -- MSBs (for the MUX)	
	signal we: std_logic_vector (N -1 downto 0); -- write enable for each BRAM
	
begin

gp: if NADD <= 11 generate -- If one BRAM (2048 words of 16 bits) is used.
        we(0) <= '1' and inRAM_we;
        addr(10 downto NADD) <= (others =>'0');
        addr(NADD-1 downto 0) <= inRAM_add; -- address for the BRAM
        inRAM_odata <= DOv(0)(15 downto 0); -- multiplexor
    end generate;
    
gr: if NADD > 11 generate -- If more than one BRAM (2048 words of 16 bits) is used.
        sel <= inRAM_add(NADD-1 downto 11);        
        -- Generic encoder:
        br: process (inRAM_we, sel)
        begin
            we <= (others => '0');
            we(conv_integer(unsigned(sel))) <= '1' and inRAM_we; -- If sel = 15 --> bit 15 is 1 and inRAM_we
        end process;            
        
        -- This only works when we use fewer than 32 bits on 2**conv_integer(sel), otherwise Vivado won't say anything, but simulation (which takes forever) fails.        
        --    wet <= conv_std_logic_vector (2**conv_integer(sel), 2**(NADD-11));        
        --wi: for i in 0 to 2**(NADD-11) - 1 generate
        --         we(i) <= wet(i) and inRAM_we;
        --     end generate;         
        addr <= inRAM_add(10 downto 0); -- address inside each BRAM
        inRAM_odata <= DOv(conv_integer(sel))(15 downto 0); -- multiplexor
    end generate;	
    			        			
   DI <= x"0000"&inRAM_idata;
   --addr <= inRAM_add(10 downto 0); -- address for each BRAM
   TADDR <= '0'&addr&"0000";
	
	--inRAM_odata <= DOv(conv_integer(sel))(15 downto 0); -- multiplexor
	
ki: for i in 0 to N-1 generate
			
			wev(i) <= (others => we(i));
			
			-- RAMB36E1: 36K-bit Configurable Synchronous Block RAM
			--           Artix-7
			-- Xilinx HDL Language Template, version 14.7

			RAMB36E1_inst : RAMB36E1
			generic map (
				-- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE" 
				RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
				-- Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
				SIM_COLLISION_CHECK => "ALL",
				-- DOA_REG, DOB_REG: Optional output register (0 or 1)
				DOA_REG => 0,
				DOB_REG => 0,
				EN_ECC_READ => FALSE,                                                            -- Enable ECC decoder,
																															-- FALSE, TRUE
				EN_ECC_WRITE => FALSE,                                                           -- Enable ECC encoder,
																															-- FALSE, TRUE
				-- INITP_00 to INITP_0F: Initial contents of the parity memory array
				INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_02 => X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
				INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_05 => X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
				INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_09 => X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
				INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_0B => X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
				INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
				INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
				-- INIT_00 to INIT_7F: Initial contents of the data memory array
				INIT_00 => DATA(i*128),
				INIT_01 => DATA(i*128 + 1),
				INIT_02 => DATA(i*128 + 2),
				INIT_03 => DATA(i*128 + 3),
				INIT_04 => DATA(i*128 + 4),
				INIT_05 => DATA(i*128 + 5),
				INIT_06 => DATA(i*128 + 6),
				INIT_07 => DATA(i*128 + 7),
				INIT_08 => DATA(i*128 + 8),
				INIT_09 => DATA(i*128 + 9),
				INIT_0A => DATA(i*128 + 10),
				INIT_0B => DATA(i*128 + 11),
				INIT_0C => DATA(i*128 + 12),
				INIT_0D => DATA(i*128 + 13),
				INIT_0E => DATA(i*128 + 14),
				INIT_0F => DATA(i*128 + 15),
				INIT_10 => DATA(i*128 + 16),
				INIT_11 => DATA(i*128 + 17),
				INIT_12 => DATA(i*128 + 18),
				INIT_13 => DATA(i*128 + 19),
				INIT_14 => DATA(i*128 + 20),
				INIT_15 => DATA(i*128 + 21),
				INIT_16 => DATA(i*128 + 22),
				INIT_17 => DATA(i*128 + 23),
				INIT_18 => DATA(i*128 + 24),
				INIT_19 => DATA(i*128 + 25),
				INIT_1A => DATA(i*128 + 26),
				INIT_1B => DATA(i*128 + 27),
				INIT_1C => DATA(i*128 + 28),
				INIT_1D => DATA(i*128 + 29),
				INIT_1E => DATA(i*128 + 30),
				INIT_1F => DATA(i*128 + 31),
				INIT_20 => DATA(i*128 + 32),
				INIT_21 => DATA(i*128 + 33),
				INIT_22 => DATA(i*128 + 34),
				INIT_23 => DATA(i*128 + 35),
				INIT_24 => DATA(i*128 + 36),
				INIT_25 => DATA(i*128 + 37),
				INIT_26 => DATA(i*128 + 38),
				INIT_27 => DATA(i*128 + 39),
				INIT_28 => DATA(i*128 + 40),
				INIT_29 => DATA(i*128 + 41),
				INIT_2A => DATA(i*128 + 42),
				INIT_2B => DATA(i*128 + 43),
				INIT_2C => DATA(i*128 + 44),
				INIT_2D => DATA(i*128 + 45),
				INIT_2E => DATA(i*128 + 46),
				INIT_2F => DATA(i*128 + 47),
				INIT_30 => DATA(i*128 + 48),
				INIT_31 => DATA(i*128 + 49),
				INIT_32 => DATA(i*128 + 50),
				INIT_33 => DATA(i*128 + 51),
				INIT_34 => DATA(i*128 + 52),
				INIT_35 => DATA(i*128 + 53),
				INIT_36 => DATA(i*128 + 54),
				INIT_37 => DATA(i*128 + 55),
				INIT_38 => DATA(i*128 + 56),
				INIT_39 => DATA(i*128 + 57),
				INIT_3A => DATA(i*128 + 58),
				INIT_3B => DATA(i*128 + 59),
				INIT_3C => DATA(i*128 + 60),
				INIT_3D => DATA(i*128 + 61),
				INIT_3E => DATA(i*128 + 62),
				INIT_3F => DATA(i*128 + 63),
				INIT_40 => DATA(i*128 + 64),
				INIT_41 => DATA(i*128 + 65),
				INIT_42 => DATA(i*128 + 66),
				INIT_43 => DATA(i*128 + 67),
				INIT_44 => DATA(i*128 + 68),
				INIT_45 => DATA(i*128 + 69),
				INIT_46 => DATA(i*128 + 70),
				INIT_47 => DATA(i*128 + 71),
				INIT_48 => DATA(i*128 + 72),
				INIT_49 => DATA(i*128 + 73),
				INIT_4A => DATA(i*128 + 74),
				INIT_4B => DATA(i*128 + 75),
				INIT_4C => DATA(i*128 + 76),
				INIT_4D => DATA(i*128 + 77),
				INIT_4E => DATA(i*128 + 78),
				INIT_4F => DATA(i*128 + 79),
				INIT_50 => DATA(i*128 + 80),
				INIT_51 => DATA(i*128 + 81),
				INIT_52 => DATA(i*128 + 82),
				INIT_53 => DATA(i*128 + 83),
				INIT_54 => DATA(i*128 + 84),
				INIT_55 => DATA(i*128 + 85),
				INIT_56 => DATA(i*128 + 86),
				INIT_57 => DATA(i*128 + 87),
				INIT_58 => DATA(i*128 + 88),
				INIT_59 => DATA(i*128 + 89),
				INIT_5A => DATA(i*128 + 90),
				INIT_5B => DATA(i*128 + 91),
				INIT_5C => DATA(i*128 + 92),
				INIT_5D => DATA(i*128 + 93),
				INIT_5E => DATA(i*128 + 94),
				INIT_5F => DATA(i*128 + 95),
				INIT_60 => DATA(i*128 + 96),
				INIT_61 => DATA(i*128 + 97),
				INIT_62 => DATA(i*128 + 98),
				INIT_63 => DATA(i*128 + 99),
				INIT_64 => DATA(i*128 + 100),
				INIT_65 => DATA(i*128 + 101),
				INIT_66 => DATA(i*128 + 102),
				INIT_67 => DATA(i*128 + 103),
				INIT_68 => DATA(i*128 + 104),
				INIT_69 => DATA(i*128 + 105),
				INIT_6A => DATA(i*128 + 106),
				INIT_6B => DATA(i*128 + 107),
				INIT_6C => DATA(i*128 + 108),
				INIT_6D => DATA(i*128 + 109),
				INIT_6E => DATA(i*128 + 110),
				INIT_6F => DATA(i*128 + 111),
				INIT_70 => DATA(i*128 + 112),
				INIT_71 => DATA(i*128 + 113),
				INIT_72 => DATA(i*128 + 114),
				INIT_73 => DATA(i*128 + 115),
				INIT_74 => DATA(i*128 + 116),
				INIT_75 => DATA(i*128 + 117),
				INIT_76 => DATA(i*128 + 118),
				INIT_77 => DATA(i*128 + 119),
				INIT_78 => DATA(i*128 + 120),
				INIT_79 => DATA(i*128 + 121),
				INIT_7A => DATA(i*128 + 122),
				INIT_7B => DATA(i*128 + 123),
				INIT_7C => DATA(i*128 + 124),
				INIT_7D => DATA(i*128 + 125),
				INIT_7E => DATA(i*128 + 126),
				INIT_7F => DATA(i*128 + 127),
				-- INIT_A, INIT_B: Initial values on output ports
				INIT_A => X"000000000",
				INIT_B => X"000000000",
				-- Initialization File: RAM initialization file
				INIT_FILE => "NONE",
				-- RAM Mode: "SDP" or "TDP" 
				RAM_MODE => "TDP",
				-- RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
				RAM_EXTENSION_A => "NONE",
				RAM_EXTENSION_B => "NONE",
				-- READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
				READ_WIDTH_A => 18,                                                               -- 0-72
				READ_WIDTH_B => 18,                                                               -- 0-36
				WRITE_WIDTH_A => 18,                                                              -- 0-36
				WRITE_WIDTH_B => 18,                                                              -- 0-72
				-- RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
				RSTREG_PRIORITY_A => "RSTREG",
				RSTREG_PRIORITY_B => "RSTREG",
				-- SRVAL_A, SRVAL_B: Set/reset value for output
				SRVAL_A => X"000000000",
				SRVAL_B => X"000000000",
				-- Simulation Device: Must be set to "7SERIES" for simulation behavior
				SIM_DEVICE => "7SERIES",
				-- WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
				WRITE_MODE_A => "WRITE_FIRST",
				WRITE_MODE_B => "WRITE_FIRST" 
			)
			port map (
				-- Cascade Signals: 1-bit (each) output: BRAM cascade ports (to create 64kx1)
				CASCADEOUTA => open,     -- 1-bit output: A port cascade
				CASCADEOUTB => open,     -- 1-bit output: B port cascade
				-- ECC Signals: 1-bit (each) output: Error Correction Circuitry ports
				DBITERR => open,             -- 1-bit output: Double bit error status
				ECCPARITY => open,         -- 8-bit output: Generated error correction parity
				RDADDRECC => open,         -- 9-bit output: ECC read address
				SBITERR => open,             -- 1-bit output: Single bit error status
				-- Port A Data: 32-bit (each) output: Port A data
				DOADO => DOv(i),                 -- 32-bit output: A port data/LSB data
				DOPADOP => open,             -- 4-bit output: A port parity/LSB parity
				-- Port B Data: 32-bit (each) output: Port B data
				DOBDO => open,                 -- 32-bit output: B port data/MSB data
				DOPBDOP => open,             -- 4-bit output: B port parity/MSB parity
				-- Cascade Signals: 1-bit (each) input: BRAM cascade ports (to create 64kx1)
				CASCADEINA => '0',       -- 1-bit input: A port cascade
				CASCADEINB => '0',       -- 1-bit input: B port cascade
				-- ECC Signals: 1-bit (each) input: Error Correction Circuitry ports
				INJECTDBITERR => '0', -- 1-bit input: Inject a double bit error
				INJECTSBITERR => '0', -- 1-bit input: Inject a single bit error
				-- Port A Address/Control Signals: 16-bit (each) input: Port A address and control signals (read port
				-- when RAM_MODE="SDP")
				ADDRARDADDR => TADDR,     -- 16-bit input: A port address/Read address
				CLKARDCLK => clock,         -- 1-bit input: A port clock/Read clock
				ENARDEN => inRAM_en,             -- 1-bit input: A port enable/Read enable
				REGCEAREGCE => '0',     -- 1-bit input: A port register enable/Register enable
				RSTRAMARSTRAM => '0', -- 1-bit input: A port set/reset
				RSTREGARSTREG => '0', -- 1-bit input: A port register set/reset
				WEA => WEv(i),                     -- 4-bit input: A port write enable
				-- Port A Data: 32-bit (each) input: Port A data
				DIADI => DI,                 -- 32-bit input: A port data/LSB data
				DIPADIP => (others => '0'),             -- 4-bit input: A port parity/LSB parity
				-- Port B Address/Control Signals: 16-bit (each) input: Port B address and control signals (write port
				-- when RAM_MODE="SDP")
				ADDRBWRADDR => (others => '0'),     -- 16-bit input: B port address/Write address
				CLKBWRCLK => clock,         -- 1-bit input: B port clock/Write clock
				ENBWREN => '0',             -- 1-bit input: B port enable/Write enable
				REGCEB => '0',               -- 1-bit input: B port register enable
				RSTRAMB => '0',             -- 1-bit input: B port set/reset
				RSTREGB => '0',             -- 1-bit input: B port register set/reset
				WEBWE => (others => '0'),                 -- 8-bit input: B port write enable/Write enable
				-- Port B Data: 32-bit (each) input: Port B data
				DIBDI => (others => '0'),                 -- 32-bit input: B port data/MSB data
				DIPBDIP => (others =>'0')              -- 4-bit input: B port parity/MSB parity
			);

	 end generate;

end structure;