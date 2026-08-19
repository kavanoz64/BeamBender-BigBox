-- BeamBender BigBox - FPGA top level
-- Lattice ECP5 LFE5U-25F (Colorlight i5 v7.0 module, CABGA381)
-- Pin locations are in beambender.lpf, not here.
-- Generated from the KiCad PCB netlist. Keep port names in sync with the .lpf.

library ieee;
use ieee.std_logic_1164.all;

entity beambender_top is
    port (
        -- Clocks
        clk_c28o       : in    std_logic;                   -- 28.375 MHz PAL / 28.636 NTSC from Alice (A4000). PCLKT2_1
        clk_14m        : in    std_logic;                   -- VCDAC doubled, 14.19 MHz (A2000/A3000). PCLKT3_1, PLL x2
        clk_27m        : in    std_logic;                   -- 27 MHz oscillator. PCLKT7_1, PLL x5.5 -> 148.5 MHz
        clk_24m576     : in    std_logic;                   -- 24.576 MHz oscillator. PCLKT2_0, audio MCLK reference
        -- Amiga video input (via 74LVC16244)
        amiga_r        : in    std_logic_vector(7 downto 0); -- Amiga digital RGB, level shifted
        amiga_g        : in    std_logic_vector(7 downto 0); -- Amiga digital RGB, level shifted
        amiga_b        : in    std_logic_vector(7 downto 0); -- Amiga digital RGB, level shifted
        amiga_hsync_n  : in    std_logic;                   -- Amiga horizontal sync (active low)
        amiga_vsync_n  : in    std_logic;                   -- Amiga vertical sync (active low)
        amiga_csync_n  : in    std_logic;                   -- Amiga composite sync (active low)
        amiga_pixelsw  : in    std_logic;                   -- Amiga pixel switch / genlock key
        amiga_psel     : in    std_logic;                   -- Amiga PSEL, reserved for auto HDMI switching
        -- Machine detect
        aga_detect     : in    std_logic;                   -- Low = A4000 (AGA slot), high = A2000/A3000
        -- OSD buttons
        btn_1          : in    std_logic;                   -- OSD button 1 (RC debounced, active low)
        btn_2          : in    std_logic;                   -- OSD button 2 (RC debounced, active low)
        btn_3          : in    std_logic;                   -- OSD button 3 (RC debounced, active low)
        -- HDMI transmitter (SiI9022A)
        hdmi_r         : out   std_logic_vector(7 downto 0); -- RGB888 to SiI9022A
        hdmi_g         : out   std_logic_vector(7 downto 0); -- RGB888 to SiI9022A
        hdmi_b         : out   std_logic_vector(7 downto 0); -- RGB888 to SiI9022A
        hdmi_pclk      : out   std_logic;                   -- Pixel clock to SiI9022A IDCK (148.5 MHz)
        hdmi_de        : out   std_logic;                   -- Data enable to SiI9022A
        hdmi_hsync     : out   std_logic;                   -- Horizontal sync to SiI9022A
        hdmi_vsync     : out   std_logic;                   -- Vertical sync to SiI9022A
        hdmi_reset_n   : out   std_logic;                   -- SiI9022A reset (active low)
        hdmi_int_n     : in    std_logic;                   -- SiI9022A interrupt (active low)
        hdmi_cec       : inout std_logic;                   -- CEC to SiI9022A (open drain)
        -- HDMI +5V load switch (TPS2553)
        hdmi_pwr_en    : out   std_logic;                   -- TPS2553 enable. 10k pull-up to 3V3: HDMI +5V on by default
        hdmi_fault_n   : in    std_logic;                   -- TPS2553 fault flag, open drain, 100k pull-up (active low)
        -- I2C (SiI9022A control)
        i2c_scl        : out   std_logic;                   -- I2C clock to SiI9022A
        i2c_sda        : inout std_logic;                   -- I2C data to SiI9022A
        -- Audio ADC (AK5720) - config only, no I2S data path
        adc_mclk       : out   std_logic;                   -- Master clock to AK5720 + SiI9022A (24.576 MHz)
        adc_reset_n    : out   std_logic;                   -- AK5720 power down / reset (active low)
        adc_fsel       : out   std_logic;                   -- AK5720 sample rate mode select (static)
        adc_dif        : out   std_logic                    -- AK5720 audio data format select (static)
    );
end entity beambender_top;

architecture rtl of beambender_top is
begin
    -- TODO: capture, deinterlace, scale, HDMI timing, OSD
end architecture rtl;
