// BeamBender BigBox - FPGA top level
// Lattice ECP5 LFE5U-25F (Colorlight i5 v7.0 module, CABGA381)
// Pin locations live in beambender.lpf, not here.
// Generated from the KiCad PCB netlist. Do not hand-edit port names
// without updating the .lpf to match.

`default_nettype none

module beambender_top (
    // ---- Clocks ----
    input  wire       clk_c28o       , // 28.375 MHz PAL / 28.636 NTSC from Alice (A4000). PCLKT2_1
    input  wire       clk_14m        , // VCDAC doubled, 14.19 MHz (A2000/A3000). PCLKT3_1, PLL x2
    input  wire       clk_27m        , // 27 MHz local oscillator. PCLKT7_1, PLL x5.5 -> 148.5 MHz
    input  wire       clk_24m576     , // 24.576 MHz local oscillator. PCLKT2_0, audio MCLK ref

    // ---- Amiga video input (via 74LVC16244) ----
    input  wire [7:0] amiga_r        , // Amiga digital RGB, level shifted
    input  wire [7:0] amiga_g        , // Amiga digital RGB, level shifted
    input  wire [7:0] amiga_b        , // Amiga digital RGB, level shifted
    input  wire       amiga_hsync_n  , // Amiga horizontal sync (active low)
    input  wire       amiga_vsync_n  , // Amiga vertical sync (active low)
    input  wire       amiga_csync_n  , // Amiga composite sync (active low)
    input  wire       amiga_pixelsw  , // Amiga pixel switch / genlock key
    input  wire       amiga_psel     , // Amiga PSEL, reserved for auto HDMI switching

    // ---- Machine detect ----
    input  wire       aga_detect     , // Low = A4000 (AGA slot), high = A2000/A3000

    // ---- OSD buttons ----
    input  wire       btn_1          , // OSD button 1 (debounced RC, active low)
    input  wire       btn_2          , // OSD button 2 (debounced RC, active low)
    input  wire       btn_3          , // OSD button 3 (debounced RC, active low)

    // ---- HDMI transmitter (SiI9022A) ----
    output wire [7:0] hdmi_r         , // RGB888 to SiI9022A
    output wire [7:0] hdmi_g         , // RGB888 to SiI9022A
    output wire [7:0] hdmi_b         , // RGB888 to SiI9022A
    output wire       hdmi_pclk      , // Pixel clock to SiI9022A IDCK (148.5 MHz)
    output wire       hdmi_de        , // Data enable to SiI9022A
    output wire       hdmi_hsync     , // Horizontal sync to SiI9022A
    output wire       hdmi_vsync     , // Vertical sync to SiI9022A
    output wire       hdmi_reset_n   , // SiI9022A reset (active low)
    input  wire       hdmi_int_n     , // SiI9022A interrupt (active low)
    inout  wire       hdmi_cec       , // CEC to SiI9022A (open drain)

    // ---- I2C (SiI9022A control) ----
    output wire       i2c_scl        , // I2C clock to SiI9022A
    inout  wire       i2c_sda        , // I2C data to SiI9022A

    // ---- Audio ADC (AK5720) ----
    // I2S data path runs AK5720 -> SiI9022A directly; FPGA only
    // supplies MCLK and the static configuration pins.
    output wire       adc_mclk       , // Master clock to AK5720 + SiI9022A (24.576 MHz)
    output wire       adc_reset_n    , // AK5720 power down / reset (active low)
    output wire       adc_fsel       , // AK5720 sample rate select
    output wire       adc_dif          // AK5720 audio data format select
);

    // TODO: capture, deinterlace, scale, HDMI timing, OSD

endmodule

`default_nettype wire
