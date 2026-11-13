# Loading the firmware

The files in this folder are the card's firmware, two per module, named for
the module and the firmware version, the C28 build with `-c28` after it:

```
BeamBender-BigBox_i9_<version>.bit         Colorlight i9  (LFE5U-45F), standard
BeamBender-BigBox_i9_<version>-c28.bit     Colorlight i9, C28
BeamBender-BigBox_i5_<version>.bit         Colorlight i5  (LFE5U-25F), standard
BeamBender-BigBox_i5_<version>-c28.bit     Colorlight i5, C28
```

Load a file for the module in your card. The programmer refuses a file for
the other module, so nothing can go wrong there. Every file runs with or
without the Si5351C clock generator: the card measures the clocks it has at
power-up and offers only the formats it can clock. Without the Si5351C the
i9 clocks the seven formats that need 40, 65, 108 or 162 MHz from its own
PLLs, and the i5 offers the other seven: 640x480, 720x576 / 720x480,
1280x720, 1280x800, 1680x1050, 1920x1080 and 1920x1200.

## Standard or -c28

Both have the same menus and settings. They differ in where the clock for
the five formats on 148.5 and 74.25 MHz (1920x1080, 1920x1200, 1680x1050,
1280x720 and 1280x800) comes from.

- **Standard:** the module's crystal, so every format runs at its exact
  rate. A PAL Amiga screen runs at 49.92 Hz, a little under the output's
  50 Hz, so once every 12.5 seconds the card shows a frame twice to keep
  in step. The file for most people, and the one for NTSC and interlaced
  screens.
- **`-c28`:** the Amiga's own clock. On a PAL screen at 1920x1080 with
  Output Frequency on Auto, every output frame is exactly one Amiga frame:
  nothing is shown twice, and a smooth scroll stays smooth. The monitor
  sees 49.92 Hz (50.38 Hz on a machine with an NTSC crystal), which all
  four monitors tried took. Only that format is locked, so for the lock
  choose 1920x1080 under Output Format (a card with no saved settings may
  start on 1280x1024). The other formats work as on the standard file,
  except 1280x720, 1280x800, 1680x1050, 1920x1200 and 1080p at 60 Hz,
  which run about 4.5 % slow (48 to 58 Hz) and which some monitors
  refuse. An interlaced PAL
  screen runs 0.16 % off the lock and drops a field every 12.5 seconds,
  and NTSC screens are not locked.

What follows is everything between a fresh module and a card that boots
into the firmware on its own: a JTAG adapter, the software, unlocking the
module's flash (once), and the command that writes the firmware. The card's
menus and buttons are in the [User Guide](../USER_GUIDE.md).

---

## 1. The JTAG adapter

The card programs the module in place, through a **1x6 JTAG header** on
the card, and the module's own JTAG pins reach it through spring-loaded
pogo pins under the SO-DIMM socket. Any JTAG adapter that openFPGALoader
supports will do; the ones that work well and cost little are the
**FTDI MPSSE** adapters:

- **FT232H** - single channel, the cheapest, and all that is needed:
  [Amazon](https://www.amazon.com/dp/B0H8CCVWT8) or
  [AliExpress](https://www.aliexpress.com/item/3256811623126850.html)
- **FT2232HL** (CJMCU-2232HL and similar) - two channels, equally good

Do **not** buy an FT232**R**L board: that chip has no MPSSE engine and
bit-bangs JTAG, which is slow enough that a bitstream takes minutes rather
than seconds.

### Wiring to the card

The header on the card (J2), pin 1 at the square pad - the signal names are also on the silkscreen next to it:

| card pin | signal | FT232H board | FT2232HL board (channel A) |
|---|---|---|---|
| 1 | TMS | D3 | AD3 |
| 2 | TDI | D1 | AD1 |
| 3 | TDO | D2 | AD2 |
| 4 | TCK | D0 | AD0 |
| 5 | GND | GND | GND |
| 6 | 3V3 | **leave unconnected** | **leave unconnected** |

Five wires: the four JTAG signals and ground. **Do not connect the
adapter's VCC / VTGT / 3V3 pin to the card.** The card is powered by the
Amiga it is plugged into, and that is how it should be powered while it is
programmed: the Amiga on, the card in its slot, the adapter supplying only
signals. A 3.3 V from the adapter would back-feed the card's rail.

On an FT232H board with an "I2C mode" switch, set it to **off** for JTAG.
Keep the wires short - a hand's length is fine - and if programming fails
at 10 MHz, drop the clock (section 4).

## 2. The software

Everything needed is in **oss-cad-suite**, a ready-built bundle of the
open-source FPGA tools for Windows, Linux and macOS - openFPGALoader and
the rest. Download the build for your machine from

<https://github.com/YosysHQ/oss-cad-suite-build/releases>

unpack it anywhere, and run the tools from its `bin` folder (or add that
folder to your PATH). There is nothing to build.

**Windows 11** needs one more thing: the FTDI adapter has to be bound to
the **WinUSB** driver so openFPGALoader can talk to it directly, and the
standard FTDI driver that Windows installs on its own gets in the way.
Run [Zadig](https://zadig.akeo.ie) as administrator, tick *Options > List
All Devices*, pick the adapter (for an FT2232HL pick **Interface 0**, the
channel the JTAG is wired to), choose **WinUSB** and *Replace Driver*.
After that the adapter appears under *Universal Serial Bus devices* in
Device Manager and stays bound. The step-by-step version of this, with
the pitfalls, is at
<https://github.com/kavanoz64/JTAG-Programming-on-Windows-11>.

Check that the adapter sees the module:

```
openFPGALoader -c ft232 --detect
```

(`-c ft2232` for an FT2232HL board.) It should report a Lattice ECP5 -
`LFE5U-45F` on an i9, `LFE5U-25F` on an i5.

## 3. Unlock the module's flash - once

A Colorlight module straight from the seller has its SPI flash
**write-protected**: the bitstream it shipped with can run, but the flash
cannot be rewritten. Until the protection bits are cleared, every attempt
to write the firmware to flash fails, however good the adapter and the
wiring. Clear them through the card's JTAG header, with the adapter and
software above:

```
openFPGALoader -c ft232 --unprotect-flash
```

(`-c ft2232` for an FT2232HL board.) **This is done once.** The flash stays
unprotected from then on, through every later programming.

The module may need one power cycle before its first write after this: turn
the Amiga off and on again, then write the firmware (section 4). Later
writes need no power cycle.

## 4. Writing the firmware

Into the module's flash - the card boots into it from then on:

```
openFPGALoader -c ft232 --freq 10000000 -f BeamBender-BigBox_i9_2026-11-12.01.bit
```

`--freq 10000000` runs the JTAG clock at 10 MHz, which an FT232H does
comfortably over short wires and writes a bitstream in seconds.
Use `-c ft2232` for an FT2232HL board, and the i5 file for an i5 module.

If the write fails on a new module, the flash is still protected (section
3); if it fails right after unlocking, power-cycle the card once and write
again.

A settings record the card has saved in its flash lives in a corner the
firmware does not touch, so your positions and sampling phases survive a
firmware update, as long as the new firmware reads the old record. When a
change breaks the format the card starts from defaults. 2026-10-28.05 was
such a change (record version 15): it and every later firmware read no
older record, so coming from 2026-10-28.04 or earlier, the card starts on
its defaults once. Back your settings up first with the BBLink tool (see the
`BBLink` folder) and restore them afterwards - the backup is a readable text
file. Back up with the BBLink made for the firmware on the card and restore
with the one made for the new firmware (the one in `BBLink`); its About box
names the firmware it was made for. The BBLink for an older firmware is in
`BBLink/Older-BBLink-Files`.

---

## Firmware history

Newest first, with the BBLink version made for each in parentheses. The
earlier versions are in [`Older-Firmware`](Older-Firmware), and the BBLink
tools made for each, from 2026-09-19.06 on, in
[`BBLink/Older-BBLink-Files`](../BBLink/Older-BBLink-Files) as
`BBLink_<version>.lha`.

### 2026-11-12.01 (BBLink 1.32)

- Monitor Info and Monitor Modes are back on the i5, beside DCTV, HAM-E and
  Overscan Auto.
- Input Mode shows the screen mode the card recognized and can no longer be
  set; a mode pinned in saved settings is ignored. BBMode is retired: take it
  out of the startup-sequence.
- An A2024 is recognized by its ID line as well as its colors.
- Overscan Auto keeps the line order on interlaced NTSC-based screens.
- With Overscan Auto on, the scale rows offer what the capture window fits.
- Load Settings no longer shows Busy and Saved on the Save row.

### 2026-11-10.03 (BBLink 1.30)

- DCTV and HAM-E pictures are decoded on the card, with neither box fitted.
- Overscan Auto (Input Sampling) captures more of the picture around the
  window, as much as fits at the scale in force.
- Calibrate Sampling runs in one pass, about six seconds.
- The MENU button no longer needs a long press on interlaced screens.
- The i5 leaves out Monitor Info and Monitor Modes to make room.

### 2026-10-30.03 (BBLink 1.30)

- Settings saved by 2026-10-28.04 or earlier are not read (a new settings
  format): back them up with BBLink before updating.
- Capture Width goes up to 800, in the screen's own pixels (up to 1360 on
  Super-Hires); BB-800x600 on ECS (Enhanced Chip Set) shows all 800 columns.
- Display Info's Capture Clock and frame rates read steady.
- New defaults: Status Lines Hidden, Menu Position Bottom Right, Menu
  Background 50%.
- The control link ignores short glitches on its lines.

### 2026-10-28.04 (BBLink 1.28)

- Fourteen output formats: 640x480, 1280x800, 1280x960, 1440x900, 1600x900
  and 1680x1050 added.
- The `-c28` files: 1920x1080 at 50 Hz locked to the Amiga's PAL frame.
- Pixel Smoothing (Soft, Softer, Softest) and Gamma (0.42 to 2.38).
- The Monitor Modes page: every output format and whether the monitor
  claims it.
- Monitor drivers with timing of their own are recognized as CUSTOM15 or
  CUSTOM24, each with its own settings. The BB- monitor drivers show
  800x600, 1024x768, 1280x1024 and 1280x720 Amiga screens 1:1.

### 2026-09-30.07 (BBLink 1.23)

- Si5351C clock generator support and an Si5351 Info page: with the
  Si5351C, the i5 runs every output format. The `-si1` files are for a
  board with only the Si5351C's CLK0 wired.
- Horizontal and vertical scales set separately, Auto or forced, with
  blended half steps from x1.5 to x5.5.
- Super-Hires is drawn on its own samples, and the menu gives sizes in the
  screen's own pixels and lines.
- The menu's six colors and its background can be set.

### 2026-09-22.03 (BBLink 1.19)

- Motion-adaptive deinterlacing decides pixel by pixel: still text keeps
  every line while the pointer moves. DblPAL interlaced included.
- BBKeyCon: Left Shift + Left Alt + a key presses the card's buttons from any
  screen.

### 2026-09-20.04 (BBLink 1.18)

- Hot plug: replug the cable or swap the monitor, and the picture comes back
  on its own within about a second.

### 2026-09-20.02 (BBLink 1.18)

- Motion-adaptive deinterlacing on both modules, in blocks of 16 pixels.
- BBLag, for measuring the delay to the monitor.

### 2026-09-19.06 (BBLink 1.18)

- Every Amiga monitor mode: Euro36, Euro72, Super72, DblPAL, DblNTSC and
  Multiscan as well as PAL and NTSC. The card recognizes the mode and keeps a
  settings set for each.
- The A2024, 15 Hz and 10 Hz, PAL and NTSC, as the full 1024-line picture.
- 1920x1200 on both modules and 1600x1200 on the i9; the output format is
  chosen from a list.
- Scale, capture width, bob deinterlacing and composite sync in the menu.
- Works on the A4000T and the A2000, with OCS (Original Chip Set) and ECS.
- The BBLink tools: BBLink (with settings backup and restore), BBMode,
  BBSurvey, BBProbe and BBScreen.

### 2026-09-14.12

- The first release: 1920x1080, 1280x720 and 720x576 / 720x480 with audio on
  both modules, plus 800x600, 1024x768 and 1280x1024 on the i9, at 50 or
  60 Hz.
- LoRes, HiRes and Super-Hires at full width, progressive and interlaced
  (woven).
- The on-screen menu, settings saved in the module's flash, Monitor Info and
  sampling calibration.
- Tested on the A4000D and the A3000.
