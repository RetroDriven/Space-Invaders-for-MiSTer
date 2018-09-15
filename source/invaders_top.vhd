-- Space Invaders top level for
-- ps/2 keyboard interface with sound and scan doubler MikeJ
--
-- Version : 0300
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : added the ROM from mw8080.vhd
--
--      0300 : MikeJ tidy up for audio release

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity invaders_top is
	port(
		Clk					: in std_logic;
		Clk_x2				: in std_logic;
		Clk_x4				: in std_logic;
		
		I_RESET				: in std_logic;
		
		dn_addr          	: in std_logic_vector(15 downto 0);
		dn_data         	: in std_logic_vector(7 downto 0);
		dn_wr				: in std_logic;
		
		video_r				: out std_logic_vector(2 downto 0);
		video_g				: out std_logic_vector(2 downto 0);
		video_b				: out std_logic_vector(2 downto 0);
		video_hblank		: out std_logic;
		video_vblank		: out std_logic;
		video_hs			: out std_logic;
		video_vs			: out std_logic;
		
		r				: out std_logic_vector(7 downto 0);
		g				: out std_logic_vector(7 downto 0);
		b				: out std_logic_vector(7 downto 0);
		de				: out std_logic;
		hs				: out std_logic;
		vs				: out std_logic;		
		
		audio_out			: out std_logic_vector(7 downto 0);
		
		info					: in std_logic;
--		bonus					: in std_logic;
		bases					: in std_logic_vector(1 downto 0);
		
		btn_coin			: in std_logic;
		btn_one_player		: in std_logic;
		btn_two_player		: in std_logic;
		btn_fire			: in std_logic;
		btn_right			: in std_logic;
		btn_left			: in std_logic

		--

		--
		);
end invaders_top;

architecture rtl of invaders_top is

	signal I_RESET_L       : std_logic;
	signal Rst_n_s         : std_logic;

	signal DIP             : std_logic_vector(8 downto 1);
	signal RWE_n           : std_logic;
	signal Video           : std_logic;
	signal VideoRGB        : std_logic_vector(2 downto 0);
	signal VideoRGB_X2     : std_logic_vector(7 downto 0);
	signal HSync           : std_logic;
	signal VSync           : std_logic;
	signal HSync_X2        : std_logic;
	signal VSync_X2        : std_logic;

	signal AD              : std_logic_vector(15 downto 0);
	signal RAB             : std_logic_vector(12 downto 0);
	signal RDB             : std_logic_vector(7 downto 0);
	signal RWD             : std_logic_vector(7 downto 0);
	signal IB              : std_logic_vector(7 downto 0);
	signal SoundCtrl3      : std_logic_vector(5 downto 0);
	signal SoundCtrl5      : std_logic_vector(5 downto 0);


--	signal Tick1us         : std_logic;

	signal Reset           : std_logic;

	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);
	signal ram_we          : std_logic;
	--
	signal HCnt            : std_logic_vector(11 downto 0);
	signal VCnt            : std_logic_vector(11 downto 0);
	signal HSync_t1        : std_logic;
	signal Overlay_G1      : boolean;
	signal Overlay_G2      : boolean;
	signal Overlay_R1      : boolean;
	signal Overlay_G1_VCnt : boolean;
	
	signal rom_cs			: std_logic;
  --

begin

  I_RESET_L <= not I_RESET;
  
  video_r 		<= (VideoRGB(2) & VideoRGB(2) & VideoRGB(2));
  video_g 		<= (VideoRGB(1) & VideoRGB(1) & VideoRGB(1));
  video_b 		<= (VideoRGB(0) & VideoRGB(0) & VideoRGB(0));
  video_hs 		<=  HSync;
  video_vs 		<=  VSync;
  video_hblank 	<= not HSync;
  video_vblank 	<= not VSync;
  
  r 		<= (VideoRGB_X2(2) & VideoRGB_X2(2) & VideoRGB_X2(2) & VideoRGB_X2(2) & VideoRGB_X2(2) & VideoRGB_X2(2) & VideoRGB_X2(2) & VideoRGB_X2(2));
  g 		<= (VideoRGB_X2(1) & VideoRGB_X2(1) & VideoRGB_X2(1) & VideoRGB_X2(1) & VideoRGB_X2(1) & VideoRGB_X2(1) & VideoRGB_X2(1) & VideoRGB_X2(1));
  b 		<= (VideoRGB_X2(0) & VideoRGB_X2(0) & VideoRGB_X2(0) & VideoRGB_X2(0) & VideoRGB_X2(0) & VideoRGB_X2(0) & VideoRGB_X2(0) & VideoRGB_X2(0));
  hs 		<=  HSync_X2;
  vs 		<=  VSync_X2;
  de 	<= not(HSync_X2 or VSync_X2);

  
  --

	DIP(8 downto 5) <= "1111";
	DIP(1) <= info;
--	DIP(2) <= bonus;
	DIP(2) <= '0';
	DIP(3) <= bases(1);
	DIP(4) <= bases(0);
	

	core : entity work.invaders
		port map(
			Rst_n      => I_RESET_L,
			Clk        => Clk,
			MoveLeft   => btn_left,
			MoveRight  => btn_right,
			Coin       => btn_coin,
			Sel1Player => btn_one_player,
			Sel2Player => btn_two_player,
			Fire       => btn_fire,
			DIP        => DIP,
			RDB        => RDB,
			IB         => IB,
			RWD        => RWD,
			RAB        => RAB,
			AD         => AD,
			SoundCtrl3 => SoundCtrl3,
			SoundCtrl5 => SoundCtrl5,
			Rst_n_s    => Rst_n_s,
			RWE_n      => RWE_n,
			Video      => Video,
			HSync      => HSync,
			VSync      => VSync
			);
	--
	-- ROM
	--
	
rom_cs  <= '1' when dn_addr(15 downto 8) < X"20"     else '0';

cpu_prog_rom : work.dpram generic map (13,8)
port map
(
	clock_a   => Clk_x4,
	wren_a    => dn_wr and rom_cs,
	address_a => dn_addr(12 downto 0),
	data_a    => dn_data,

	clock_b   => Clk,
	address_b => AD(12 downto 0),
	q_b       => IB
);	
	
	--
	-- SRAM
	--
	cpu_video_ram0 : entity work.gen_ram
generic map( dWidth => 8, aWidth => 13)
port map(
	clk  => Clk,
	we   => ram_we,
	addr => RAB,
	d    => RWD,
	q    => RDB
);
	
	ram_we <= not RWE_n;

	--
	-- Glue
	--
-----	process (Rst_n_s, Clk)
--		variable cnt : unsigned(3 downto 0);
---	begin
--		if Rst_n_s = '0' then
--			cnt := "0000";
--			Tick1us <= '0';
---		elsif Clk'event and Clk = '1' then
--			Tick1us <= '0';
--			if cnt = 9 then
--				Tick1us <= '1';
--				cnt := "0000";
---			else
--				cnt := cnt + 1;
--			end if;
--		end if;
--	end process;

  --
  -- Video Output
  --
  p_overlay : process(Rst_n_s, Clk)
	variable HStart : boolean;
  begin
	if Rst_n_s = '0' then
	  HCnt <= (others => '0');
	  VCnt <= (others => '0');
	  HSync_t1 <= '0';
	  Overlay_G1_VCnt <= false;
	  Overlay_G1 <= false;
	  Overlay_G2 <= false;
	  Overlay_R1 <= false;
	elsif Clk'event and Clk = '1' then
	  HSync_t1 <= HSync;
	  HStart := (HSync_t1 = '0') and (HSync = '1');-- rising

	  if HStart then
		HCnt <= (others => '0');
	  else
		HCnt <= HCnt + "1";
	  end if;

	  if (VSync = '0') then
		VCnt <= (others => '0');
	  elsif HStart then
		VCnt <= VCnt + "1";
	  end if;

	  if HStart then
		if (Vcnt = x"1F") then
		  Overlay_G1_VCnt <= true;
		elsif (Vcnt = x"95") then
		  Overlay_G1_VCnt <= false;
		end if;
	  end if;

	  if (HCnt = x"027") and Overlay_G1_VCnt then
		Overlay_G1 <= true;
	  elsif (HCnt = x"046") then
		Overlay_G1 <= false;
	  end if;

	  if (HCnt = x"046") then
		Overlay_G2 <= true;
	  elsif (HCnt = x"0B6") then
		Overlay_G2 <= false;
	  end if;

	  if (HCnt = x"1A6") then
		Overlay_R1 <= true;
	  elsif (HCnt = x"1E6") then
		Overlay_R1 <= false;
	  end if;

	end if;
  end process;

  p_video_out_comb : process(Video, Overlay_G1, Overlay_G2, Overlay_R1)
  begin
	if (Video = '0') then
	  VideoRGB  <= "000";
	else
	  if Overlay_G1 or Overlay_G2 then
		VideoRGB  <= "010";
	  elsif Overlay_R1 then
		VideoRGB  <= "100";
	  else
		VideoRGB  <= "111";
	  end if;
	end if;
  end process;
  
  u_dblscan : entity work.DBLSCAN
	port map (
	  RGB_IN(7 downto 3) => "00000",
	  RGB_IN(2 downto 0) => VideoRGB,
	  HSYNC_IN           => HSync,
	  VSYNC_IN           => VSync,

	  RGB_OUT            => VideoRGB_X2,
	  HSYNC_OUT          => HSync_X2,
	  VSYNC_OUT          => VSync_X2,
	  --  NOTE CLOCKS MUST BE PHASE LOCKED !!
	  CLK                => Clk,
	  CLK_X2             => Clk_x2
	);


  --
  -- Audio
  --
  u_audio : entity work.invaders_audio
	port map (
	  Clk => Clk,
	  P3  => SoundCtrl3,
	  P5  => SoundCtrl5,
	  Aud => audio_out
	  );

end;
