# BeamBender BigBox

A digital scandoubler and HDMI output card for the **Amiga 4000**, with **Amiga 2000 / 3000** support as a secondary target.

The card plugs into the video slot, taps the digital RGB signals before they ever reach a DAC, and outputs clean **HDMI** with audio. No analogue stage, no capture artefacts, no flicker.

> This project is a big-box adaptation of [**jbilander/BeamBender**](https://github.com/jbilander/BeamBender), Jörgen Bilander's scandoubler for the Amiga 1200 (and 500). The original design's approach and much of its analogue and HDMI circuitry carry over directly. Jörgen has also provided hardware guidance throughout this redesign. All credit for the concept belongs upstream.

**Status: hardware built and working. Gateware working on A4000 and A3000.** See [Status](#status) for detail.

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

**The i9 (LFE5U-45F, 44k LUT, 4 PLLs) is the recommended module.** It is pin-compatible, it drops straight into the same socket, and the extra fabric and the two extra PLLs are doing real work: the i9 build carries three VESA output formats that will not fit in the i5, and it is the only module with headroom for the processing still to come. Build with an i9 unless cost is the deciding factor.

The **i5 (LFE5U-25F)** remains fully supported as the cheaper option. It has its own bitstream and covers the three CEA formats, which is everything most people need for a television or a modern monitor. What it gives up is the VESA formats and future headroom.

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

Both clock paths are confirmed on hardware: the A4000 runs from C28O, and the A3000 runs from the doubled VCDAC through the PLL. The card detects which is present and picks automatically, and the choice can be overridden from the menu.

---

## Amiga 2000 / 3000 support

The pre-AGA video slot carries **12-bit color** (RGB444) rather than AGA's 24. Each nibble is replicated into both halves of an 8-bit channel, which is multiplication by 17. That maps 0 to 0 and 15 to 255 with no rounding error at any level.

Machine detection is passive. The AGA video slot extends the connector with pins 43 to 54, which don't exist at all on the A2000 and A3000. Pins 43 and 44 are ground, and 45 to 54 carry the extra color bits. A 10 kΩ pull-up on pin 43 therefore reads low on an A4000 and high everywhere else. The ten color lines on pins 45 to 54 get 100 kΩ pull-downs so their buffer inputs never float on a machine where those pins are absent.

The A3000 is confirmed working. The A2000 is untested and is the main remaining hardware question.

---

## Programming

The module's JTAG pads aren't on the SO-DIMM edge, so four **spring-loaded pogo pins** contact them from below when the module is seated. A **1x6 JTAG header** runs in parallel for an external programmer. An FT232H or FT2232H dongle works directly with `openFPGALoader` or `ecpprog`.

Bitstreams can be loaded to SRAM for fast iteration, or written to the module's SPI flash through the same connection so the card boots on its own.

---

## Firmware

The gateware captures the Amiga's digital RGB into the module's SDRAM, scales it with integer nearest-neighbour, and drives the SiI9022A.

**Prebuilt bitstreams are in [`Firmware/`](Firmware).** One file per module, named for the module and the firmware version. Load one and the card works; nothing else is needed.

The firmware **sources are not published yet**. They will be, once the gateware reaches a maturity worth handing to other people. Until then the binaries are the deliverable, and the open items below are an honest account of what they do and do not do.

**Output formats.** One bitstream carries them all and the format is chosen from the menu:

| | i9 (recommended) | i5 |
|---|---|---|
| 1920x1080 | yes | yes |
| 1280x720 | yes | yes |
| 720x576 / 720x480 | yes | yes |
| 800x600 | yes | no |
| 1024x768 | yes | no |
| 1280x1024 | yes | no |

All formats run at 50 or 60 Hz, following the Amiga automatically or forced from the menu.

**Input.** LoRes, HiRes and Super-Hires, progressive and interlaced. Super-Hires is captured at full width, 1280 samples per line, one per output pixel rather than averaged down. Interlaced modes are **woven** - both fields assembled into one frame - which is the right answer for the static, text-heavy Workbench screens that dominate Super-Hires laced use.

**On-screen display.** A text menu on the card's three buttons covers output format, refresh rate, picture position and offsets, capture height, scanline and picture effects, menu size, source clock, sampling phase and a Display Info page. Settings are written to the module's SPI flash and restored at power-up, four independent sets so PAL and NTSC, 50 and 60 Hz can each keep their own geometry.

**Monitor Info** reads the sink's EDID over the transmitter's DDC master and shows what the monitor actually claims to support, which is how you find out why a format is being refused.

**Sampling calibration** sweeps the capture phase against a static picture and finds the centre of the eye. Needed because there is no fine phase shift available on the C28O path, and because the A3000's doubled clock has a narrower window than the A4000's.

**The Amiga control link** is three wires between test points already on the card - no new connector, no board revision - giving a clocked full-duplex link to AmigaOS. `BBLink` is a GadTools GUI that drives the whole menu from Workbench and writes a report; `BBProbe` is the command-line diagnostic. Useful when the card is in a machine you cannot reach, and much faster than three buttons.

---

## Status

**The board works.** Fabricated, assembled, and running on an **Amiga 4000D** and an **Amiga 3000**. HDMI output, audio, SDRAM framebuffer, the on-screen menu, settings in flash and the Amiga link are all confirmed on hardware.

What is confirmed working:

- [x] First article fab and bring-up
- [x] HDMI output with audio, on multiple sinks
- [x] SDRAM framebuffer at 74.25 MHz, full-width Super-Hires, interlace weave
- [x] A4000D (C28O path) and A3000 (doubled VCDAC path)
- [x] Capture-phase calibration on real hardware, on both machine types
- [x] On-screen menu, settings saved to the module's SPI flash
- [x] EDID read-back from the sink
- [x] Amiga control link and the AmigaOS tools
- [x] i9 module support, with the three extra VESA formats

What is still open:

- [ ] **A2000** - untested, the last unproven machine
- [ ] **Motion-adaptive deinterlacing** for LoRes and HiRes laced. Everything weaves today, which is right for a static screen and wrong for a moving one. The memory bandwidth for a second read stream is not there on the i5; the i9 is the candidate.
- [ ] **The doubled-scan and productivity modes** - DblPAL, DblNTSC, Super72, Euro36, Euro72. The card now *detects* them correctly; capturing them needs a runtime capture width and more than 256 lines per field, both of which are fixed at build time today.
- [ ] **A2024** - a 1024x1024 mode built from four interleaved 15 kHz fields. Detection is easy, the decode is not.
- [ ] **Hot-plug** - the transmitter's interrupt register is read today but nothing polls it, so a sink unplugged and replugged is recovered by changing format or by a power cycle
- [ ] Measure actual current on the 5 V and 3.3 V rails
- [ ] `PSEL` is now the Amiga link's data line rather than spare; an automatic HDMI switcher would need a different pin

### Next steps

**Hardware.** Test in an A2000. Measure the rails. A second board revision would fold in the Amiga link's three jumpers as traces and replace the parallel-port link with a byte-parallel one (a 74LVC165A on the existing spare pins), which is roughly eight times the throughput for one chip.

**Firmware.** Finish seeing the full mode list, then capturing it: the sync detection now tracks the line period rather than asserting it, which is what the doubled-scan modes need, and the remaining work is a runtime capture width and deeper field storage. Motion-adaptive deinterlacing on the i9 after that. A2024 last, being the hardest and the least used.

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
