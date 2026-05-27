# The validation-app ladder

Each app consumes both adapters via `libs/` (built + linked as artifacts) and pulls a specific adapter milestone into existence. Build them in order — earlier rungs unblock later ones.

| # | App | Develops platform → | Develops vulkan → | Validates |
| --- | --- | --- | --- | --- |
| 0 | **event-logger** *(warm-up, platform only)* | v0.6.0 | — | window + `Event` mapping; `nm` shows **no `vk*`** |
| 1 | **clear-color** ← *first both-libs milestone* | v0.6.0 | v0.2.0 | the surface bridge end-to-end (window → surface → swapchain → clear → present) |
| 2 | **snake** | (v0.6.0) | v0.3.0 (VMA) | a real game loop + the first geometry (one quad buffer), timing, action input |
| 3 | **breakout** | (v0.6.0) | v0.3.0 | instancing / batching throughput through VMA |
| 4 | **tetris** | v0.7.0 (input contexts) | v0.3.0 | pushing `ui_menu` on pause masks gameplay actions |
| 5 | **pong** | v0.8.0 (gamepads) | v0.3.0 | multi-gamepad + analog axis modifiers |
| 6 | **life** | (v0.6.0) | v0.4.0 (shaders) | a real fragment/compute shader + large dynamic buffer churn |

## Decoupling checks (`nm`)

The architecture rests on each adapter dragging only its own concern. Two apps prove it — treat these as required:

- **event-logger** (`renderer = .none`, platform only) → `nm <bin> | grep -i 'vk[A-Z]\|VK_'` must print **nothing** (platform drags no Vulkan).
- A **headless vulkan** sketch (no window, offscreen render) → `nm <bin> | grep -i 'SDL_\|x11\|wayland'` must print **nothing** (vulkan drags no windowing).

## Why no "spinning cube"

A textured 3D cube is a typical engine's *first 3D milestone* — building it here would just pre-build a renderer. These stay **2D (quads + ortho)** so they exercise the adapters (window, surface, buffers, shaders, input) without turning into an engine.
