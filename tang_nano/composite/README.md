Simulates Conway's Game of Life on the TANG Nano board 2704pr.

Outputs to a PAL composite signal. The TV Out outputs about 6 gray levels so to use as is you will need 3 resistors.

```
PIN 1 (g3 IOT17B) -> R470 -> Composite+
PIN 2 (g4 IOT17A) -> R560 -> Composite+
PIN 3 (g5 IOT14B) -> R680 -> Composite+
PIN 19 (GND) -> Composite-
```

Button B, when pressed, randomizes the center of the field.
Button A, when pressed, pauses the simulation.

The field is 256x256 pixels. This simplifies the implementation for wraparounds.
The Crystal on my board is 24MHz and appears to be fine for PAL output.


## Files

tvout.v - Top module instantiates all others
memory.v - COPIES PSRAM to BSRAM and vice-versa. One line (32 bytes) at a time. This is also the burst limit of the PSRAM so it turned out lucky.
video_sync.v - Responsible for generating the sync signals for PAL. VBlank, HBlank are generated here.
pixel_signal.v - Reads from PSRAM via memory.v and outputs a pixel signal to the CRT
conway.v - The implementation of the game of life. Reads PSRAM into cache, processes and writes back.

## General timing

For each row: 
    - Read PSRAM into the video line BSRAM for generating the pixel signal.
    - Read PSRAM into the 3rd processing line in BSRAM
    - Process the processing cache lines into the 1 resulting line also in BSRAM
    - Write the resulting line from BSRAM to PSRAM
    - Shift up the bottom 2 processing lines to the top in BSRAM.


