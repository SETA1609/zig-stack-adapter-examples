# The validation-app ladder

Each app consumes both adapters via `libs/` (built + linked as artifacts) and pulls a specific adapter milestone into existence. Build them in order — earlier rungs unblock later ones.

| # | App | Develops platform → | Develops vulkan → | Validates |
| --- | --- | --- | --- | --- |
| 0 | **event-logger** *(warm-up, platform only)* | v0.6.0 | — | window + `Event` mapping; `nm` shows **no `vk*`** |
| 1 | **clear-color** ← *first both-libs milestone* | v0.6.0 | v0.2.0 | the surface bridge end-to-end (window → surface → swapchain → clear → present) |
| 2 | **hello-triangle** | (v0.6.0) | v0.3.0 (VMA) | first graphics pipeline + first vertex buffer + (precompiled) shaders — one static triangle |
| 3 | **snake** | (v0.6.0) | v0.3.0 | a real fixed-timestep game loop, timing, action input — first actual *game* (reuses the triangle's pipeline for its quads) |
| 4 | **breakout** | (v0.6.0) | v0.3.0 | instancing / batching throughput through VMA |
| 5 | **tetris** | v0.7.0 (input contexts) | v0.3.0 | pushing `ui_menu` on pause masks gameplay actions |
| 6 | **pong** | v0.8.0 (gamepads) | v0.3.0 | multi-gamepad + analog axis modifiers |
| 7 | **life** | (v0.6.0) | v0.4.0 (shaders) | runtime GLSL→SPIR-V (shaderc) + compute + large dynamic buffer churn |
| 8 | **hello-cube** ← *tail / 3D smoke* | (v0.6.0) | v0.4.0 (shaders) + depth | perspective MVP + a depth attachment — the stack survives 3D (untextured single cube) |

## Decoupling checks (`nm`)

The architecture rests on each adapter dragging only its own concern. Two apps prove it — treat these as required:

- **event-logger** (`renderer = .none`, platform only) → `nm <bin> | grep -i 'vk[A-Z]\|VK_'` must print **nothing** (platform drags no Vulkan).
- A **headless vulkan** sketch (no window, offscreen render) → `nm <bin> | grep -i 'SDL_\|x11\|wayland'` must print **nothing** (vulkan drags no windowing).

## Why hello-triangle sits between clear-color and snake

`clear-color` (rung 1) only does acquire → clear → present — **no pipeline, no geometry**. `snake` (rung 3) is a whole *game*. Dropping the first graphics pipeline, the first vertex buffer, *and* a game loop into one rung would conflate three new things. `hello-triangle` (rung 2) isolates the first of them: stand up a `VkPipeline` + a VMA vertex buffer + a vertex/fragment shader pair (precompiled SPIR-V) and draw **one static triangle**. snake then reuses that pipeline and only adds the loop.

## Why the cube is the tail, not the lead

A textured, lit, spinning cube is a typical engine's *first 3D milestone* — leading with it here would just pre-build a renderer. So the ladder stays **2D (quads + ortho)** through rung 7, exercising the adapters (window, surface, buffers, shaders, input) without turning into an engine.

`hello-cube` (rung 8) is the one deliberate exception, placed **last**: once the 2D ladder is green, a single **untextured** cube is a cheap, honest 3D smoke test. It adds exactly two things over `life` — a **perspective MVP** (a uniform buffer feeding a vertex shader) and a **depth attachment** — and nothing more (no textures, no lighting, no scene). That proves the adapters survive 3D without the repo becoming a renderer.
