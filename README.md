# BeamBender BigBox

A digital scandoubler and HDMI output card for the **Amiga 4000**, with the **Amiga 2000 and 3000** supported as well.

The card plugs into the video slot, taps the digital RGB signals before they ever reach a DAC, and outputs clean **HDMI** with audio. No analogue stage, no capture artefacts, no flicker.

> This project is a big-box adaptation of [**jbilander/BeamBender**](https://github.com/jbilander/BeamBender), Jörgen Bilander's scandoubler for the Amiga 1200 (and 500). The original design's approach and much of its analogue and HDMI circuitry carry over directly. Jörgen has also provided hardware guidance throughout this redesign. All credit for the concept belongs upstream.

**Status: revision 0.3 hardware built and working on the Amiga 4000D, 4000T, 3000 and 2000 (ECS and OCS). Every Amiga monitor mode captured, including the A2024; interlaced modes deinterlaced motion-adaptively on both modules.** See [Status](#status) for detail.

---

## What's different from the A1200 original

The A1200 version clips onto the Lisa chip and connects to the main board via an FFC cable. Big-box Amigas expose the same signals on the video slot, so this version is a **single PCB with no cables**. It takes digital RGB, syncs and the pixel clock straight off the slot fingers, along with audio and power.

| | A1200 BeamBender | BeamBender BigBox |
|---|---|---|
| Signal source | Lisa chip (PLCC-84 clip) | Video slot |
| Boards | Two, joined by FFC | One |
| FPGA | Gowin GW1NR-9 (on-board) | Colorlight i5 or i9 module (SO-DIMM socket) |
| Video RAM | FPGA-internal | 8 MB 32-bit SDRAM on module |
| Audio in | 3.5 mm jack | Video slot, plus aux header and jack, mixed |
| Power | External connector | Slot |

---

## Hardware

**FPGA:** a [Colorlight i5 v7.0](https://github.com/wuxx/Colorlight-FPGA-Projects) module in a 200-pin DDR2 SO-DIMM socket (TE 1473149-4). The module carries a Lattice **ECP5 LFE5U-25F** (24k LUT), **8 MB of 32-bit SDRAM** for field storage, plus its own configuration flash and regulators.

Using a module rather than a bare FPGA is deliberate. The ECP5 only comes in BGA, and this design has a hard no-BGA-in-my-hands rule. A dead module is a socket swap, not a rework station. **SO-DIMM pin 41 is left unconnected** specifically so that the i5 and the i9 are interchangeable, since it is the one ball that differs between the two.

**The i9 (LFE5U-45F, 44k LUT, 4 PLLs) is the recommended module.** It is pin-compatible, it drops straight into the same socket, and the extra fabric and the two extra PLLs are doing real work: the i9 build carries four VESA output formats that the i5 cannot clock, and it is the module with headroom for whatever comes next. Build with an i9 unless cost is the deciding factor.

The **i5 (LFE5U-25F)** remains fully supported as the cheaper option. It has its own bitstream and covers the CEA formats plus 1920x1200, which is everything most people need for a television or a modern monitor. What it gives up is the 4:3 VESA formats.

**Video out:** an **SiI9022A** HDMI transmitter fed 24-bit parallel RGB888 at up to 148.5 MHz. Bit-banged TMDS would not reach 1080p60 on a non-SERDES ECP5, so a real transmitter earns its place.

**Audio:** an **AK5720** 24-bit ADC digitises the audio and feeds I²S straight to the SiI9022A, bypassing the FPGA entirely. Ahead of it, an **OPA1692** inverting summing amplifier mixes the Amiga's line audio from the slot with an auxiliary input, so you can fold in another card's audio or an external source. The aux input appears on both an internal header and a switched 3.5 mm jack, where inserting a plug mechanically disconnects the header. The amplifier runs from the slot's +12 V through its own RC filter rather than the digital 5 V rail, and the ESD clamp on the external jack protects both entry points.

**HDMI +5 V:** HDMI requires the source to supply 5 V on pin 18, and plenty of DIY designs simply tie it to the board rail. That invites two failure modes: a shorted cable dragging your supply down, and cheap televisions pushing 5 V *back* into your system. A **TPS2553** load switch sits in that path instead, current-limited to a guaranteed minimum of 422 mA with reverse-current blocking, so neither can happen. Its enable and fault lines run to the FPGA, and the on-screen display reports the fault line today.

**Level shifting:** two 74LVC16244 buffers translate the Amiga's 5 V logic to 3.3 V. The ECP5 is *not* 5 V tolerant, so these are mandatory rather than optional.

**Board:** 157.5 x 90 mm, 4-layer, with dedicated ground and 3V3 planes.

![PCB Top](Images/BeamBender-BigBox-Top-3D.png)
![PCB Bottom](Images/BeamBender-BigBox-Bottom-3D.png)


### Where to buy the module

[Colorlight i5 + ext-board bundle on AliExpress](https://www.aliexpress.us/item/3256807602160285.html)

Buy the **module and the dev board together**. The BigBox card provides a JTAG header to program the module in place using an external programmer, but having the ext-board as well gives you a second, independent way to load and recover a bitstream, which may come handy.

---

## Clock architecture

Four clock inputs, on four dedicated ECP5 primary-clock pins.

| Clock | Source | ECP5 pin | PLL |
|---|---|---|---|
| **C28O**, 28.375 MHz PAL / 28.636 NTSC | Alice, via slot | 91 · `PCLKT2_1` | none, already the pixel clock |
| **VCDAC x2**, 14.19 MHz | Agnus/Alice CDAC, doubled on-board | 81 · `PCLKT3_1` | x2 to 28.375 MHz |
| **27 MHz** | on-board oscillator | 134 · `PCLKT7_1` | x5.5 to 148.5 MHz output |
| **24.576 MHz** | on-board oscillator | 89 · `PCLKT2_0` | none, audio MCLK reference |

Two details behind those choices:

**27 MHz is not arbitrary.** 148.5 MHz, the pixel clock for 1080p at both 50 and 60 Hz, is exactly 27 x 5.5, which the ECP5 PLL reaches cleanly. The module's own 25 MHz reference cannot produce it at any legal divider setting.

**The A2000 and A3000 have no 28 MHz clock on their video slots.** The fastest available is VCDAC at 7.09/7.16 MHz, which sits below the ECP5 PLL's 8 MHz input minimum. So an XOR gate and an RC delay double it to 14.19 MHz on-board, and the PLL takes it from there. Crude, cheap, and it adds no jitter of its own.

The two clocks that need PLLs sit on opposite die edges (banks 7 and 3), so each reaches its nearest PLL. That matters, because the LFE5U-25F only has two.

Both clock paths are confirmed on hardware: the A4000 runs from C28O, and the A3000 and A2000 run from the doubled VCDAC through the PLL. The card detects which is present and picks automatically, and the choice can be overridden from the menu.

The card takes the slot's separate horizontal and vertical syncs by default; composite sync alone works too, and is selected from the menu.

---

## Amiga 2000 / 3000 support

The pre-AGA video slot carries **12-bit color** (RGB444) rather than AGA's 24. Each nibble is replicated into both halves of an 8-bit channel, which is multiplication by 17. That maps 0 to 0 and 15 to 255 with no rounding error at any level.

Machine detection is passive. The AGA video slot extends the connector with pins 43 to 54, which don't exist at all on the A2000 and A3000. Pins 43 and 44 are ground, and 45 to 54 carry the extra color bits. A 10 kΩ pull-up on pin 43 therefore reads low on an A4000 and high everywhere else. The ten color lines on pins 45 to 54 get 100 kΩ pull-downs so their buffer inputs never float on a machine where those pins are absent.

The A3000 and the A2000, with OCS and with ECS chips, are all confirmed working.

---

## Programming

The module's JTAG pads aren't on the SO-DIMM edge, so four **spring-loaded pogo pins** contact them from below when the module is seated. A **1x6 JTAG header** runs in parallel for an external programmer. An FT232H or FT2232H dongle works directly with `openFPGALoader` or `ecpprog`.

Bitstreams can be loaded to SRAM for fast iteration, or written to the module's SPI flash through the same connection so the card boots on its own.

---

## Firmware

The gateware captures the Amiga's digital RGB into the module's SDRAM, scales it with integer nearest-neighbour, and drives the SiI9022A.

**Prebuilt bitstreams are in [`Firmware/`](Firmware).** One file per module, named for the module and the firmware version. Load one and the card works; nothing else is needed. The AmigaOS tools that drive the card over its control link are in [`BBLink/`](BBLink), with their own README.

The firmware **sources are not published yet**. They will be, once the gateware reaches a maturity worth handing to other people. Until then the binaries are the deliverable, and the open items below are an honest account of what they do and do not do.

**Output formats.** One bitstream carries them all and the format is chosen from the menu:

| | i9 (recommended) | i5 |
|---|---|---|
| 720x576 / 720x480 | yes | yes |
| 800x600 | yes | no |
| 1024x768 | yes | no |
| 1280x720 | yes | yes |
| 1280x1024 | yes | no |
| 1600x1200 | yes | no |
| 1920x1080 | yes | yes |
| 1920x1200 | yes | yes |

All formats run at 50 or 60 Hz, following the Amiga automatically or forced from the menu. The format is chosen from a list rather than cycled, so the monitor re-locks once, on the one you asked for.

**Input.** Every mode the Amiga's monitor drivers produce: PAL and NTSC, Euro36, Euro72, Super72, DblPAL, DblNTSC and Multiscan, in LoRes, HiRes and Super-Hires, progressive and interlaced. The card recognises which monitor it is looking at from the line length and the lines per field, and keeps a settings set for each - ten in all - so the geometry and sampling phase you set for one mode are there again the next time that mode appears. Super-Hires is captured at full width, 1280 samples per line, one per output pixel rather than averaged down. Interlaced modes are **deinterlaced motion-adaptively**: the card compares each field with the previous one of the same parity, block by block (16 pixels wide, one field line tall), weaves the two fields where the picture is still and interpolates the newer field where it moved - so a still Workbench stays as sharp as a weave and a moving pointer or a scrolling window does not comb. Plain weave and bob are still there, chosen from the menu (Deinterlace = Adaptive, Weave or Bob), and Display Info counts the moved blocks per field. Both modules do it. The one visible cost of the block scheme: static detail sharing a 16-pixel block with something moving is softened for as long as the movement lasts.

**The A2024** is supported as a 1024x1024 (PAL) or 1024x800 (NTSC) greyscale picture - BeamBender BigBox is the first Amiga scandoubler ever to display the A2024 modes. Commodore's monitor rebuilt its picture from four or six panels sent one per 15 kHz frame; the card does the same, assembling the panels in its frame buffer and showing the whole picture at 1:1 on 1280x1024 or 1080p. Both the 15Hz and 10Hz modes work, on PAL and NTSC.

**On-screen display.** A text menu on the card's three buttons covers output format and frequency, picture position, scale and offsets, capture width and height, scanline and picture effects, menu size and position, source clock and sync source, sampling phase and calibration, plus Display Info and Monitor Info pages. Settings are written to the module's SPI flash and restored at power-up.

**Monitor Info** reads the sink's EDID over the transmitter's DDC master and shows what the monitor actually claims to support, format by format, which is how you find out why a format is being refused.

**Sampling calibration** sweeps the capture phase against a static picture and finds the centre of the eye. Needed because there is no fine phase shift available on the C28O path, and because the A3000's doubled clock has a narrower window than the A4000's.

**The Amiga control link** is three wires between test points already on the card - no new connector - giving a clocked full-duplex link to AmigaOS. The tools in [`BBLink/`](BBLink) drive it: `BBLink` is a GadTools window with every setting, the live pages and the card's buttons, and it backs the settings up to a text file and restores them; `BBMode` tells the card which monitor the Amiga just switched to; `BBSurvey` walks every screen mode and logs what the card measured; `BBProbe` and `BBScreen` are the diagnostics; `BBLag` puts a field counter on the screen in digits big enough to film, for measuring the card's delay against the Amiga's own video. The wiring for the revision 0.3 board is in that README.

**Latency**, measured with BBLag and a 240 fps camera on a PAL HiRes screen: the picture on the card's HDMI monitor is between one and two fields (20 to 40 ms) behind the same picture on an analogue monitor, the HDMI monitor's own scaler included. One field of that is the frame buffer by design - the card shows the last field it has completely captured - and the rest drifts with the phase between the Amiga's field rate and the card's free-running output.

---

## Status

**The revision 0.3 board works.** Fabricated, assembled, and running on an **Amiga 4000D**, an **Amiga 4000T**, an **Amiga 3000** and an **Amiga 2000**. HDMI output, audio, the SDRAM frame buffer, the on-screen menu, settings in flash, every Amiga monitor mode including the A2024, and the Amiga link with its tools are all confirmed on hardware.

![Revision 0.3 board with an i5 module fitted](Images/Revision0.3-Board-With-i5.jpg)

What is confirmed working:

- [x] First article fab and bring-up
- [x] HDMI output with audio, on multiple sinks
- [x] SDRAM frame buffer, full-width Super-Hires, interlace weave and bob
- [x] Motion-adaptive deinterlacing, on both modules
- [x] A4000D and A4000T (C28O path), A3000 and A2000 (doubled VCDAC path), OCS and ECS
- [x] Capture-phase calibration on real hardware, on both machine types
- [x] On-screen menu, settings saved to the module's SPI flash, one set per monitor mode
- [x] EDID read-back from the sink, shown format by format on Monitor Info
- [x] Amiga control link and the AmigaOS tools: BBLink, BBMode, BBSurvey, BBProbe, BBScreen, BBLag
- [x] Latency measured: one to two fields to the HDMI monitor
- [x] i9 module support, with 800x600, 1024x768, 1280x1024 and 1600x1200
- [x] 1920x1200 on both modules
- [x] All the doubled-scan and productivity modes: DblPAL, DblNTSC, Super72, Euro36, Euro72, Multiscan
- [x] The A2024, 15Hz and 10Hz, PAL and NTSC, reassembled to the full 1024-line picture

What is still open:

- [ ] **Hot-plug** - the transmitter's interrupt register is read today but nothing polls it, so a sink unplugged and replugged is recovered by changing format or by a power cycle
- [ ] Measure actual current on the 5 V and 3.3 V rails

### Next steps

**Hardware.** Measure the rails. The next board revision folds the Amiga link's three jumpers in as traces.

**Firmware.** Hot-plug. Adaptive deinterlacing for the 512-line DblPAL interlace (today it weaves plainly: the motion memory covers 256 lines a field).

---

## Building one

The Gerbers have not been published, but can be generated from the KiCad files here. The PCB is designed around **JLCPCB** fabrication and assembly, with part selection biased toward their basic library. The Colorlight module and the pogo pins are hand-fitted afterwards.

Fit an **i9** module unless cost rules it out. A finished board needs no toolchain: take the matching bitstream from [`Firmware/`](Firmware) and load it.

---

## Credits

- **[Jörgen Bilander](https://github.com/jbilander)**, original BeamBender design, and ongoing guidance on this adaptation
- **[Salih Albayrak (aka Kavanoz)](https://github.com/kavanoz64)**, hardware design and implementation for BigBox
- **[Stefan Reinauer](https://github.com/reinauer)**, FPGA programming
- **Claude AI** (Anthropic), design review, component selection, gateware and documentation
- **[wuxx](https://github.com/wuxx/Colorlight-FPGA-Projects)** and the Colorlight reverse-engineering community, for module pinouts and documentation that the vendor doesn't publish

## License

Please check the licensing of the upstream [BeamBender](https://github.com/jbilander/BeamBender) project before redistributing derived work.
