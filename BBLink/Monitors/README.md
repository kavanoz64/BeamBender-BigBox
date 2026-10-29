# BeamBender monitor drivers

Four AmigaOS 3 monitor drivers for `DEVS:Monitors`, each adding one screen
mode named after itself. Written from scratch for BeamBender: their own
monitor IDs, so they sit beside every stock driver and any other
third-party one. They need graphics.library 39 (AmigaOS 3.0 or later) and
the ECS or AGA chips, and run on a 68000.

| Driver | Monitor ID | Mode | Line | Fields |
|---|---|---|---|---|
| BB-800x600 | 0x00B81000 | AGA: Super-High Res Laced (0x00B89024) | 17.65 kHz | 50.06 Hz |
| | | ECS: High Res Laced (0x00B89004) | 14.72 kHz | 45.8 Hz |
| BB-1024x768 | 0x00B91000 | Super-High Res Laced (0x00B99024) | 21.24 kHz | 50.03 Hz |
| BB-1280x1024 | 0x00BA1000 | Super-High Res Laced (0x00BA9024) | 17.65 kHz | 33.1 Hz |
| BB-HD720p | 0x00BB1000 | Super-High Res Laced, 1280x720 (0x00BB9024) | 17.65 kHz | 46.3 Hz |

The rates are for a PAL crystal; an NTSC one runs 0.9 % faster. A line is
TOTCLKS + 1 color clocks and the two fields TOTROWS + 1 and TOTROWS + 2
lines, as BeamBender measured them on an A4000. Version 1.2 (October 27,
2026) puts BB-800x600 and BB-1024x768 on TOTROWS 0x15F and 0x1A7 for fields
at 50 Hz (1.1's 0x160 and 0x1A8 gave 49.9 Hz). These are
not timings a monitor on the Amiga's 23-pin port will show. BeamBender
weaves the two fields and sends its own HDMI timing, so the field rate does
not show on its output. Colors: 256 on AGA, 4 in Super-High Res on ECS
(BB-800x600 is High Res on ECS for that reason: 16 colors).

## Try them from a Shell first

Nothing is changed until the Amiga is restarted, so a driver that does not
work costs a reboot and nothing more.

1. Unpack `bbmonitors.lha` into RAM: (the four programs and their icons).
2. `RAM:BB-1024x768 VERBOSE` prints the mode it added and its timing.
3. Prefs/ScreenMode lists `BB-1024x768`. Pick it, Test.
4. `BBSurvey BBMODES` (BBSurvey 1.10 or later; 1.11 for firmware
   2026-10-28.01 on) opens every BB- mode, measures it
   and writes `BBModes.log`: the material for tuning the drivers and the
   card's settings for them, and which field the card weaves where.

Then copy the ones you want, with their icons, to `DEVS:Monitors` and
restart. To remove one, delete it and its icon and restart.

## Options

As tooltypes in the icon (Icons > Information), or on the command line,
which wins. The icons list them in brackets, switched off, with the
built-in values. Numbers are decimal or hex (`0xA6` or `$A6`).

- `TOTCLKS` the line in color clocks (280 ns each), `TOTROWS` the field's
  last line (fields of TOTROWS + 1 and TOTROWS + 2 lines)
- `MINROW` the first line of the picture, `MINCOL` the first column (Low Res pixels)
- `HBSTRT` / `HBSTOP` the horizontal blank, `VBSTRT` / `VBSTOP` the vertical
  blank (color clocks from the field's start), `BEAMCON0`
- `RES=HIRES` or `RES=SHRES`: BB-800x600 only, High Res or Super-High Res
  whatever the chipset (High Res uses TOTCLKS 0xF0, TOTROWS 0x140)
- `VERBOSE` (command line): what was installed

A driver run twice says it is installed already and does nothing. It never
returns an error code above WARN, so a failure cannot stop the
startup-sequence's other monitors.

## The card

The firmware knows the four by their line and lines a field and gives
each a set of its own, named after the driver in Display Info (Settings
Set and Input both `BB-1024x768`), with the window `BBSurvey BBMODES`
measured on an A4000 as its default. That is every firmware from the
release 2026-10-28.01, and before it the src-cust test firmware from
2026-10-27.70 (the Input row named so from 2026-10-27.71): H 217, V 13, and the mode's own size. Super-High Res is stored as such whatever is
on the screen. On ECS the position is an estimate until it has been
measured, and BB-800x600's 800 High Res pixels are past the card's
724-sample High Res ceiling (`RES=SHRES` gives all 800, in 4 colors).
BBMode 1.2 pins the card on CUSTOM24 for BB-1024x768 and CUSTOM15 for the
other three, and the card picks the BB- set from there.

## Building

`_build_monitors.bat` in this folder (vbcc, `-DBBMON=1..4`), or the tools'
`_build_amiga.bat` in the folder above, which also runs it and puts
`bbmonitors.lha` and this guide (as `bbmonitors-README.md`) beside
`bblink.lha`. `mkicons.py` writes the
icons. The record layout and call order were learned by running working
drivers in a 68000 emulator and logging what they hand graphics.library;
bbmonitor.c's header describes the interface.
