# PicoRV32-Based RISC-V SoC with Hardware-Accelerated Sobel Image Accelerator on FPGA

> Status: work in progress. Items marked **TODO** will be filled in after they are tested on the board.

## 1. Overview

This project adds a custom hardware block to a PicoRV32 RISC-V SoC. The block removes noise from an image (Gaussian blur) and then finds its edges (Sobel filter). The CPU only controls the block through memory-mapped registers (MMIO), and the heavy pixel work is done in hardware.

- **Board:** Real Digital Boolean board (Spartan-7 XC7S50)
- **Tool:** Vivado
- **CPU:** PicoRV32 (provided, not modified)
- **Software language:** C
- **Custom hardware:** Verilog (RTL)

## 2. Why edge detection?

Edge detection is the first step in many vision systems, such as lane detection in cars, factory inspection, and medical imaging. These systems need results quickly, and a small processor like PicoRV32 is slow at pixel-by-pixel work, so a hardware block helps.

## 3. Pipeline

```
Input image (grayscale)
      |
      v
 +---------------+      +---------------+
 | Gaussian 3x3  | ---> |  Sobel 3x3    | ---> Edge image
 | (noise removal)|     | (edge finder) |
 +---------------+      +---------------+
```

A 64x64 input gives a 62x62 image after blur and a 60x60 image after Sobel (each 3x3 stage removes the border pixels).

## 4. How the filters work

**Gaussian blur** (weights, then divide by 16, which is a right shift by 4):

```
1 2 1
2 4 2
1 2 1
```

**Sobel** (two filters, then edge strength = |Gx| + |Gy|, clipped to 255):

```
Gx: -1 0 +1      Gy: -1 -2 -1
    -2 0 +2           0  0  0
    -1 0 +1          +1 +2 +1
```

Both filters use only adders, subtractors and shifts, so no multiplier is needed. Each stage uses two line buffers (they remember the last two image rows) and a 3x3 window of registers, so the block accepts one pixel per clock cycle.

An optional threshold turns the edge strength into a black and white output.

## 5. Repository structure

```
rtl/
  gaussian3x3_stream.v   Gaussian blur stage
  sobel3x3_stream.v      Sobel stage (with optional threshold)
  edge_pipeline.v        Connects blur to Sobel
sim/
  tb_edge.v              Testbench (8x8 test image)
sw/                      TODO: C code for PicoRV32
host/                    TODO: Python script for image in / image out over UART
docs/                    TODO: block diagram, screenshots
```

PicoRV32 (`picorv32.v`) and the provided bus and peripherals are used unmodified.

## 6. Register map (MMIO)

**TODO:** to be finalized after the provided MMIO address map is known. Planned registers:

| Register | Purpose |
|---|---|
| CTRL | Reset / enable, mode (edge strength or threshold) |
| THRESHOLD | Edge threshold value |
| DATA_IN | Write input pixels |
| DATA_OUT | Read output pixels |
| STATUS | Output valid / busy flags |

## 7. Simulation

Test image: 8x8, left half = 20, right half = 80 (one vertical edge).
Expected output (4x4, each row): `60, 180, 180, 60`.

How to run: add the three files in `rtl/` as design sources and `sim/tb_edge.v` as a simulation source in Vivado, then run Behavioral Simulation.

**Simulation result:** TODO (confirm and add screenshot).

## 8. Results

All numbers below must be **measured on the board**, not estimated.

| Item | Software only | With hardware block |
|---|---|---|
| Cycles for one 64x64 image | TODO | TODO |
| Speedup | | TODO |

| FPGA resource | Used | Available |
|---|---|---|
| LUTs | TODO | TODO |
| Flip-flops | TODO | TODO |
| Block RAM | TODO | TODO |

Timing (clock frequency, slack): TODO

## 9. Compliance with the hackathon rules

| Rule | How this project follows it |
|---|---|
| PicoRV32 and bus are not modified | Only a new peripheral is added |
| At least one custom RTL block, used through MMIO and controlled by software | Gaussian + Sobel block |
| C is the application language | TODO (C driver) |
| Application runs on the FPGA board using Vivado | TODO (board test) |
| No hardcoded or precomputed outputs | All pixels are computed by the hardware block |
| Total memory at most 128 KB | TODO (check final memory use) |
| Resource and timing constraints are met | TODO (Vivado reports) |

## 10. Demo

**TODO:** photos / screenshots showing the original image, the blurred image and the edge image.

## 11. Future work

- Median filter for salt-and-pepper noise
- Programmable 3x3 weights (one block for blur, Sobel and other filters)
- Edge direction output (horizontal vs vertical edges)
- Larger images

## 12. Credits

- PicoRV32 by Claire Xenia Wolf, ISC license: https://github.com/YosysHQ/picorv32
- Team: **TODO** (names)
