# Loading the firmware

The files in this folder are the card's firmware, one per module, named for
the module and the firmware version:

```
BeamBender-BigBox_i9_<version>.bit     Colorlight i9  (LFE5U-45F)
BeamBender-BigBox_i5_<version>.bit     Colorlight i5  (LFE5U-25F)
```

Load the one that matches the module in your card. The programmer refuses
the other one, so nothing can go wrong there. What follows is everything
between a fresh module and a card that boots into the firmware on its own:
unlocking the module's flash (once), a JTAG adapter, the software, and the
two commands.

---

## 1. Unlock the module's flash - once, on the Colorlight dev board

A Colorlight module straight from the seller has its SPI flash
**write-protected**: the bitstream it shipped with can run, but the flash
cannot be rewritten. Until the protection bits are cleared, every attempt
to write the firmware to flash fails, however good the adapter and the
wiring.

The easiest way to clear them is with the module seated in the **Colorlight
ext-board** (the dev board sold in a bundle with the module), which has a
JTAG programmer built in. With the module on the dev board and the board
plugged into USB, run

```
ecpdap flash scan
ecpdap flash unprotect
```

`scan` shows the protection bits (`BP0: true, BP1: true, BP2: true` on a
new module); `unprotect` clears them. **This is done once.** The flash
stays unprotected from then on, through every later programming, so the
dev board is not needed again after this step. Tom Verbeure's write-up of
the i5 as a development board is where this comes from and has the detail:
<https://tomverbeure.github.io/2021/01/22/The-Colorlight-i5-as-FPGA-development-board.html>

`ecpdap` is part of the oss-cad-suite package described in section 3, so
install that first. (openFPGALoader from the same package can do the same
with `openFPGALoader -b colorlight-i5 --unprotect-flash`.)

If you skipped the dev board, the same commands work through the card's
JTAG header with your own adapter, once section 2 is done.

## 2. The JTAG adapter

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

## 3. The software

Everything needed is in **oss-cad-suite**, a ready-built bundle of the
open-source FPGA tools for Windows, Linux and macOS - openFPGALoader,
ecpdap, and the rest. Download the build for your machine from

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

## 4. Loading the firmware

Two commands, one difference between them. **Into the FPGA's memory**, to
try it - it runs immediately and is gone at the next power cycle:

```
openFPGALoader -c ft232 --freq 10000000 -m BeamBender-BigBox_i9_2026-09-19.06.bit
```

**Into the module's flash**, to keep it - the card boots into it from then
on:

```
openFPGALoader -c ft232 --freq 10000000 -f BeamBender-BigBox_i9_2026-09-19.06.bit
```

That is `-m` for memory and `-f` for flash; everything else is the same.
`--freq 10000000` runs the JTAG clock at 10 MHz, which an FT232H does
comfortably over short wires and loads a bitstream in a few seconds.
Use `-c ft2232` for an FT2232HL board, and the i5 file for an i5 module.

If the flash write fails and the memory load works, the flash is still
protected: section 1.

A settings record the card has saved in its flash lives in a corner the
firmware does not touch, so your positions and sampling phases survive a
firmware update. When a new firmware changes the record's format the card
says so and starts from defaults; back your settings up first with the
BBLink tool (see the `BBLink` folder) and restore them afterwards.
