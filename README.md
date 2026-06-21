# Atari Breakout — x86 Assembly (NASM/DOS)

A classic Atari Breakout arcade game built entirely in x86 16-bit assembly for DOS. The player controls a paddle to bounce a ball and break through 32 colored bricks, with real-time keyboard input, collision physics, scoring, a live timer, and PC speaker sound effects — all rendered directly to video memory.

## Features

- Real-time keyboard control via a custom hardware interrupt handler (INT 09h)
- Physics-based ball movement with 45°/90° bounce angles
- Collision detection for walls, paddle (with angle-based deflection), and bricks
- 32 bricks arranged in a 4-row staggered, color-coded layout
- Live score tracking (10 points per brick, 320 max) and a 3-life system
- In-game timer displayed in M:SS format
- Audio feedback through direct PC speaker control (distinct tones for hits and life loss)
- Welcome, win, and game-over screens with final stats
- Fast rendering via direct writes to video memory (segment B800h)

## Tech Stack

- **Language:** x86 16-bit real-mode Assembly (NASM syntax)
- **Platform:** MS-DOS / DOSBox
- **Interfaces used:** BIOS interrupts (`INT 10h`, `INT 15h`), DOS interrupts (`INT 21h`), hardware keyboard interrupt (`INT 09h`), direct port I/O for PC speaker

## Concepts Demonstrated

- Low-level hardware interrupt handling (installing and restoring a custom keyboard ISR)
- BIOS and DOS system service calls
- Direct memory-mapped video I/O (text-mode rendering without OS/library support)
- Real-time collision detection algorithms
- PC speaker programming via direct port control (timer/speaker ports `42h`, `43h`, `61h`)
- Game loop and finite-state design (menu → playing → win/lose states)
- Modular assembly programming using labels, procedures, and a structured data segment

## How to Run

**Requirements:** [NASM](https://www.nasm.us/) assembler and [DOSBox](https://www.dosbox.com/) (or a real DOS environment)

Assemble the source into a DOS executable:

```bash
nasm breakout.asm -o breakout.com
```

Run it in DOSBox:

```text
dosbox
mount c: /path/to/game
c:
breakout.com
```

**Controls:**

| Key | Action |
|-----|--------|
| Left / Right Arrow | Move paddle |
| Space | Launch / unpause ball |
| Enter | Start game (from menu) |
| Esc | Exit |

## What I Learned

Building this project meant working without any of the conveniences of a high-level language — no standard library, no automatic memory management, and no built-in graphics calls. Implementing the game loop, collision detection, and rendering by hand gave a much deeper understanding of how a CPU actually executes a program: how interrupts hijack control flow, how the BIOS and DOS expose hardware through interrupt vectors, and how something as simple as a moving ball on screen comes down to direct manipulation of memory-mapped video RAM. It also reinforced good low-level discipline — register preservation across calls, careful flag management, and structuring assembly into reusable procedures despite the lack of native function abstractions.
