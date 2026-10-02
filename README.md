# Endless Runner Game — CS50x Final Project

An endless side-scrolling runner game built with Lua and the LÖVE (Love2D) engine. The objective is to jump over obstacles, survive as long as possible, and beat your high score. There is no win condition.

# How to Play

| Key | Action |

| `Space` | Jump |
| `R` | Restart after Game Over |
| `Esc` | Quit (press twice to confirm) |

The game gets faster the longer you survive. Your highest score is saved and persists between sessions.

# Requirements

- [LÖVE 11.x](https://love2d.org/) — tested on LÖVE 11.4

# Running the Game

1. Install LÖVE from [love2d.org](https://love2d.org/)
2. Clone or download this repository
3. Drag the game folder onto the LÖVE executable

# Project Structure

 main.lua          — All game code and logic
 Background.png    — Scrolling background image
 Foreground.png    — Scrolling ground/foreground image
 Run.png           — Player run sprite sheet (3 frames)
 Jump.png          — Player jump sprite
 Death.png         — Player death sprite
 Obstacle_1.png    — Obstacle variant 1
 Obstacle_2.png    — Obstacle variant 2
 Obstacle_3.png    — Obstacle variant 3
 BGMusic.wav       — Background music
 Jump.wav          — Jump sound effect
 GameOver.wav      — Game over sound effect


# Code Explanation

The entire game runs inside three LÖVE callbacks:

1. **`love.load()`** runs once at startup, loading all assets into memory, setting window properties, initializing fonts and audio, reading the saved high score from disk, and calling `resetGame()`.

2. **`love.update(dt)`** runs every frame, receiving `dt` (delta time in seconds since the last frame). It handles all movement, physics, collision, and score logic.

3. **`love.draw()`** runs every frame after update, drawing everything to the screen in order: background, foreground, obstacles, player, UI.

Using delta time throughout means the game runs at the same speed regardless of frame rate. `resetGame()` is separated from `love.load()` so the player can restart without reloading assets from disk.

**Physics:** The player uses simple kinematic physics rather than a physics engine. Gravity (1700 px/s²) is applied every frame. Jumping sets `velocityY` to −700 px/s, which gravity pulls back toward zero until the player lands. Landing is detected by checking if `player.y` has passed the ground line, at which point `y` is clamped and `velocityY` is reset to zero.

**Parallax scrolling:** The background and foreground scroll at different speeds to create a sense of depth. Each layer is drawn twice side by side to create a seamless loop.

**Obstacles:** They are spawned with randomized timings, each picking randomly from three image variants and a random scale between 2.8× and 4×. Obstacles are stored in a table and iterated each frame to update position and check collision. Off-screen obstacles are removed using `table.remove(obstacles, i)`, iterating in reverse to avoid index shifting.

**Collision:** Uses axis-aligned bounding box (AABB) detection with a uniform inward padding of 10 px on all sides, giving the player a more forgiving hitbox.

**Animation:** The player has three visual states: run, jump, and death. The run animation uses a 3-frame horizontal sprite sheet with LÖVE's Quad system advancing frames at a fixed interval (`animSpeed = 0.10` s/frame). The jump sprite is a single frame, written to be extensible if a multi-frame animation were added later. The death state swaps in a static image and freezes, since no further updates occur after `gameOver = true`.

**Scoring:** Score increases continuously as a function of time, and game speed also increases over time, creating a compounding difficulty curve. The high score is written to a plain text file via `love.filesystem`, persisting across sessions without requiring a database.

# Known Limitations

- Only keyboard input is supported — the game is not playable on mobile or with a mouse
- All game variables are globals; in a larger project these would be refactored into tables or modules to avoid naming conflicts and improve readability

# Asset Credits

All assets (PNG and WAV files) were sourced from PoorGameDev on itch.io, from the 2D pixel art endless runner package by Demonstick Games:

[https://demonstick-games.itch.io/pixel-art-2d-endless-runner-package]

# Video Demo:  

https://youtu.be/mivfk1uXKmQ

# AI Use

The code was written entirely by me. I used Claude by Anthropic to help find errors and assist with debugging when issues were difficult to spot— only to assist my own process, and not beyond two or three bug-fix instances.
