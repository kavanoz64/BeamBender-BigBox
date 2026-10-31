# BeamBender monitor drivers

Four AmigaOS 3 monitor drivers that add screen modes made for BeamBender
BigBox. The Amiga's own chipset draws the screen, interlaced; the card
weaves the two fields and shows the picture 1:1 on the output format of the
same size. A 1024x768 Workbench on a 1024x768 monitor, with no graphics
card.

| Driver | Resolution | Colors on ECS | Colors on AGA |
|---|---|---|---|
| BB-800x600 | 800x600 | 16 (High Res) | 256 |
| BB-1024x768 | 1024x768 | 4 | 256 |
| BB-1280x1024 | 1280x1024 | 4 | 256 |
| BB-HD720p | 1280x720 | 4 | 256 |

They need AmigaOS 3.0 or later and either AGA or both ECS chips (an ECS
Agnus and the ECS Denise, as in the A3000 and A600); with an original chip
they do not install. Any CPU will do, a 68000 included. They have monitor
IDs of their own, so they sit beside the stock drivers and any others.

These modes are for BeamBender: a monitor on the Amiga's own 23-pin video
port will not show them.

## Installing

1. Unpack `bbmonitors.lha`.
2. Copy the drivers you want, each with its icon, to `DEVS:Monitors`.
3. Restart the Amiga.
4. Choose the mode in Prefs/ScreenMode, for example `BB-1024x768`.

To remove a driver, delete it and its icon from `DEVS:Monitors` and restart.

## On the card

- With Input Mode on Auto (the default) the card recognizes each mode and
  gives it a settings set of its own, named after the driver: Display Info
  shows `BB-1024x768`.
- Choose the output format of the same size for the 1:1 picture: 800x600,
  1024x768, 1280x1024 or 1280x720.
- BBMode, from the BBLink tools, knows the four modes.
- On ECS, BB-800x600 is High Res, for 16 colors rather than 4. `RES=SHRES`
  makes it Super-High Res, in 4 colors.
- The default picture position was measured on an A4000; on an ECS machine
  it may need a touch of Horizontal or Vertical Position (Input Sampling).

## Options

Tooltypes in the driver's icon (Icons > Information):

- `RES=HIRES` or `RES=SHRES`, BB-800x600 only: High Res or Super-High Res on
  either chipset.

The icons also list the timing tooltypes, switched off; leave them as they
are.
