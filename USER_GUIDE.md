# BeamBender BigBox User Guide

How to use the card from its three buttons and its on-screen menu. Written for firmware **2026-10-28.04**, the version in [Firmware/](Firmware/README.md). 2026-10-24.01 has the same menu without the six formats, Monitor Modes and the custom monitors added in 2026-10-28.01, and without Gamma (2026-10-28.03).

- **Programming the card:** [Loading the firmware](Firmware/README.md), and [Programming](README.md#programming) on the main page for the JTAG header.
- **From the Amiga:** everything here can also be done from AmigaOS with the [BBLink tools](BBLink/README.md). [BBKeyCon](BBLink/README.md#bbkeycon) puts the three buttons on the keyboard.

**Contents:** [Buttons](#the-buttons) · [Using the menu](#using-the-menu) · [Main menu](#main-menu) · [Input Sampling](#input-sampling) · [Output Geometry](#output-geometry) · [Settings](#settings) · [Pages](#pages) · [Calibrating](#calibrating-the-sampling) · [Saving](#saving-your-settings) · [Border and status lines](#border-and-status-lines) · [Rescue](#rescue-back-to-defaults)

---

## The buttons

The three buttons come through the card's bracket at the back of the computer: **MENU**, **UP** and **DOWN** (SW1, SW2 and SW3 on the board). Each has a press and a hold. A hold is **1 second** on MENU and **half a second** on UP and DOWN. It acts while you are still holding, and letting go afterwards does nothing more.

**Menu closed**

| Button | Press | Hold |
|---|---|---|
| MENU | opens the menu on the row you left it on, submenu included | status lines on or off |
| UP | nothing | Display Info page |
| DOWN | nothing | Si5351 Info page |

**Menu open**

| Button | Press | Hold |
|---|---|---|
| MENU | acts on the selected row ([below](#using-the-menu)) | closes the menu, from any row or submenu |
| UP | previous row | keeps moving up |
| DOWN | next row | keeps moving down |

Closing with a hold changes nothing else: the next MENU press opens the menu on the same row, so you can change a value, close the menu to look at the picture and come back with two presses. The rows wrap round from the last to the first.

At power-up the card shows the Display Info page over the picture (Startup Page under [Settings](#settings)). Any button takes it away.

## Using the menu

The selected row has a `>` in front of it and a yellow bar. What a MENU press does depends on the row:

| Row | MENU press |
|---|---|
| a choice of a few values (Status Lines, Deinterlace, the scales ...) | steps to the next value, which applies at once |
| a number (positions, offsets, capture size, Sampling Phase) | starts an edit: the yellow bar moves to the value, UP and DOWN change it live (hold for bigger steps, twice a second), and MENU (press or hold) ends the edit |
| a bar (Gamma) | opens it, the bar highlighted: UP adds a block and DOWN takes one away, live (hold to repeat), stopping at either end; MENU closes it |
| ending in `>>` | opens the submenu on its **Go Back <<** row; MENU on Go Back returns to the main menu |
| a page (Display Info, Monitor Info, About) | opens the page; any button goes back to the menu |
| an action (Calibrate, Load, Save, Reset) | runs it; the row shows Busy, then the result |

**Output Format** is chosen, not stepped, so the monitor re-syncs only once: MENU opens the choice, UP shows the next higher resolution and DOWN the next lower (only the formats this card can clock), MENU applies it and holding MENU cancels.

A row reading **N/A** does not apply to the picture on screen (SHRes Downsampling on a HiRes screen, for example), and the bar skips it.

Every change is live at once, and is lost at power-off unless you [save it](#saving-your-settings).

## Main menu

| Row | Values (default **bold**) | What it does |
|---|---|---|
| Exit Menu | | closes the menu |
| Output Format | 640x480, 720x480 / 720x576, 800x600, 1024x768, 1280x720, 1280x800, 1280x960, 1280x1024, 1440x900, 1600x900, 1600x1200, 1680x1050, 1920x1080, 1920x1200 | the HDMI resolution. SD reads 720x576 at 50 Hz and 720x480 at 60 Hz. The formats on offer depend on the module and the Si5351C ([table](README.md#firmware)). With no saved format the card starts on 1280x1024 where it can clock it, otherwise on 1920x1080. On the `-c28` firmware, choose 1920x1080 for the lock to the Amiga ([more](Firmware/README.md#standard-or--c28)). |
| Output Frequency | **A-50Hz / A-60Hz**, F-50Hz, F-60Hz | A follows the Amiga and shows the rate in use; F is forced. MENU steps Auto, 50 Hz, 60 Hz. |
| Status Lines | **Shown**, Hidden | the two lines of readings ([below](#border-and-status-lines)) |
| Menu Position | Center, Top Left, **Top Right**, Bottom Left, Bottom Right | where the menu sits |
| Display Info | page | what the card sees and does ([Pages](#pages)) |
| Monitor Info | page | who the monitor is; MENU there opens Monitor Modes, the formats it says it accepts |
| Input Sampling >> | submenu | how the Amiga's picture is captured |
| Output Geometry >> | submenu | where the picture sits on the monitor, and its scale |
| Settings >> | submenu | the things you set once |
| About | page | credits, firmware version and module |
| Load Settings | Busy, Loaded, Failed | reads the saved settings back, undoing unsaved changes |
| Save Settings | Busy, Saved, Failed | writes the settings to the module's flash |
| Reset to Defaults | | puts the live settings back to defaults (Save keeps them, Load undoes it) |

## Input Sampling

These rows are kept per **settings set**: one for each monitor mode on each chipset (ECS, AGA), PAL and NTSC apart. They always show the set of the screen on display, and a new screen mode on the Amiga brings up its own set.

| Row | Values (default **bold**) | What it does |
|---|---|---|
| Input Mode | PAL, NTSC, EURO36, A2024 PAL, A2024 NTSC, SUPER72, DBLPAL, DBLNTSC, EURO72, MULTISCAN, **Auto**, CUSTOM15, CUSTOM24 | Auto recognises the monitor mode by itself. Pick one by hand to set a mode up without the card changing its mind, or if Auto gets it wrong. It also chooses which set the rows below edit. CUSTOM15 and CUSTOM24 are monitor drivers with timing of their own, on a 15 or 24 kHz line. The four BB- drivers ([BBLink/Monitors](BBLink/Monitors/README.md)) are recognised on Auto, CUSTOM15 or CUSTOM24, each with a set named after it. |
| Calibrate Sampling | action | finds the best Sampling Phase ([how](#calibrating-the-sampling)) |
| Sampling Phase | 0 to 159 | the fine sampling edge, 0.22 ns a step. N/A on 28M. |
| Pixel Phase | a few steps | the coarse sampling edge: which capture clock in each pixel is used |
| Source Clock | 28M, 14Mx2, **7Mx4** | the clock the card samples with: 7 MHz times four, 14 MHz doubled, or the slot's 28 MHz clock itself (which has no fine phase) |
| Horizontal Position | number | where capture starts on the Amiga's line |
| Vertical Position | number | the first line captured (half lines on an interlaced screen) |
| Capture Width | 320 to 724 | HiRes pixels captured per line, in steps of 4 |
| Capture Height | from 180 | lines captured |
| LoRes Capture | **Half**, Full | a LoRes screen stored one sample per pixel (so a 320-pixel screen reaches x6) or both. Acts on LoRes screens only. |

Position and Capture choose which part of the Amiga's picture is taken; Output Geometry moves where it lands on the monitor.

## Output Geometry

Kept per output format.

| Row | Values (default **bold**) | What it does |
|---|---|---|
| Horizontal Offset | number | moves the picture left or right |
| Horizontal Scale | **Auto**, x1 to x6 in half steps | output pixels per screen pixel |
| Vertical Offset | number | moves the picture up or down |
| Vertical Scale | **Auto**, x1 to x6 in half steps | output lines per screen line |

Auto picks the largest whole scale that fits and centres the picture. The half steps (x1.5 to x5.5) blend the middle row or column of each pair, so there are no uneven lines. Scales that do not fit are skipped. On a Super-Hires screen the horizontal scale is per Super-Hires pixel, so x0.5 can appear on the SD formats. A new output format, or a new screen on the Amiga, puts both scales back on Auto.

## Settings

| Row | Values (default **bold**) | What it does |
|---|---|---|
| Menu Background | 0%, 25%, 50%, 75%, **100%** | how solid the menu's background is |
| Menu Size | x1 to x4, as the format allows | menu magnification, kept per output format |
| Scanline Effect | **Off**, Light, Medium, Deep | dark lines between the Amiga's lines, at vertical scale x2 and up |
| SHRes Downsampling | Sharp, **Soft** | Super-Hires on 720x576/480, 800x600 and 1024x768, too narrow for its 1280 samples: Sharp drops every other sample, Soft averages each pair |
| Deinterlace | **Adaptive**, Weave, Bob | interlaced screens: Adaptive weaves the still parts and interpolates only what moves, Weave always interleaves the two fields, Bob shows each field on its own |
| Startup Page | Off, **Display Info** | the page shown at power-up |
| BBLink Protocol | **Enabled**, Disabled | whether the card answers the Amiga tools. Disabled takes it off the parallel port's handshake lines, for a printer or another parallel-port device. |
| Audio | **On**, Off | HDMI audio |
| Pixel Smoothing | **Off**, Soft, Softer, Softest | softens every pixel's edges over a third, two thirds or all of the pixel, for a less blocky scaled picture |
| Gamma | 0.42 to 2.38 in eleven steps, **1.00** | the midtones: above 1.00 lighter, below darker, black and white unchanged. Drawn as a bar, no blocks at 0.42, five at 1.00, ten at 2.38. The menu and the status lines keep their colours. |

## Pages

Any button press on a page goes back to the menu. Holding DOWN on any page opens Si5351 Info.

- **Display Info:** the hardware, the input status in words, field lines, capture size and clock, the settings set in use, the output, buffer counters and the link. The first page to look at when something is wrong.
- **Monitor Info:** what the monitor reports over HDMI: maker, product and native resolution. MENU opens Monitor Modes; UP or DOWN goes back to the menu.
- **Monitor Modes:** every output format, smallest first, and whether the monitor's EDID (Extended Display Identification Data, its description of itself) claims it at 50 and 60 Hz. Use it to see why a format will not show; a monitor may also show formats it does not list. Any button goes back to Monitor Info.
- **Si5351 Info:** the clock generator, if fitted. Hold DOWN to reach it; it has no menu row.
- **About:** credits, the project address, the firmware version and the module.

## Calibrating the sampling

Needs a still picture (Workbench is fine) and Source Clock on 7Mx4 or 14Mx2.

1. Input Sampling >> Calibrate Sampling, press MENU.
2. The status lines turn into the calibration page while the card sweeps the phase twice (COARSE, then FINE) and scores each step.
3. It stops on SELECT with the best phase chosen. UP and DOWN pick another, applied live so you can see it.
4. MENU accepts it; holding MENU cancels and puts the old phase back. The menu returns.
5. Save Settings to keep it.

## Saving your settings

**Save Settings** writes everything (every settings set, every format's geometry) to the module's flash, and the card reads it back at every power-up. **Load Settings** reads it back now. **Reset to Defaults** changes only the live settings. [BBLink](BBLink/README.md) can also back the settings up to a text file on the Amiga and restore them.

## Border and status lines

While the status lines are shown, the screen has a coloured border:

| Border | Means |
|---|---|
| green | syncs locked, pixels arriving |
| red | no HSYNC |
| blue | no VSYNC |
| grey | no RGB activity |

The top status line is the capture and the output: position, phases, clock, sync, rate, output format, scale and capture size, ending in A, W or B (Adaptive, Weave, Bob) on an interlaced screen. The bottom line is the input: mode, field, line rate, lines, line length, RGB activity, Super-Hires pair counters and buffer underflow and overflow counts. Hide both with Status Lines, or by holding MENU with the menu closed.

## Rescue: back to defaults

If saved settings leave you without a usable picture (a format the monitor refuses, say), you can erase them without seeing the screen:

1. Hold **MENU, UP and DOWN together** for five seconds. "Rescue Mode initiated." appears with a countdown from 5.
2. At 0 the saved settings are erased and the card shows "Power cycle the computer."
3. Power cycle. The card starts on defaults.

Let go before the countdown ends and nothing is erased.
