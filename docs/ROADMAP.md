# Roadmap — zig-stack-adapter-examples

> The release sequence for this examples repo: which app lands when, and the adapter milestones each one gates on. Per-app validation detail: [`ladder.md`](ladder.md). Current sprint: [`sprint.md`](sprint.md).

## How releases map to the ladder

Each ladder rung is one example-repo release. A release is cut when its app **builds and runs correctly** and the relevant `nm` decoupling check is green. The adapter columns are the *minimum* lib versions an app builds against — earlier rungs unblock later ones.

| Release | App | platform → | vulkan → | Delivers |
| --- | --- | --- | --- | --- |
| **v0.1.0** ← *next* | **event-logger** + **clear-color** | v0.6.0 | v0.2.0 | the surface bridge end-to-end (window → surface → swapchain → clear → present); both `nm` checks green |
| **v0.2.0** | hello-triangle | (v0.6.0) | v0.3.0 (VMA) | first graphics pipeline + first vertex buffer + (precompiled) shaders — one static triangle |
| **v0.3.0** | snake | (v0.6.0) | v0.3.0 | a real fixed-timestep game loop + action input (reuses the triangle's pipeline for its quads) |
| **v0.4.0** | breakout | (v0.6.0) | v0.3.0 | instancing / batching throughput through VMA |
| **v0.5.0** | tetris | v0.7.0 (input contexts) | v0.3.0 | the input-context stack (pause pushes `ui_menu`, masks gameplay) |
| **v0.6.0** | pong | v0.8.0 (gamepads) | v0.3.0 | multi-gamepad + analog axis modifiers |
| **v0.7.0** | life | (v0.6.0) | v0.4.0 (shaders) | runtime GLSL→SPIR-V (shaderc) + compute + large dynamic buffer churn |
| **v0.8.0** | hello-cube *(tail / 3D smoke)* | (v0.6.0) | v0.4.0 (shaders) + depth | perspective MVP + a depth attachment — the stack survives 3D |
| **v1.0.0** | — | — | — | every rung green; both `nm` checks pass; CI matrix green. The set is the engine's reference consumer. |

Rungs beyond v0.1.0 may resequence as the libs' own roadmaps firm up.

## Gates that apply to every release

- **Builds *and* runs in CI** on the supported target matrix (Linux X11 + Wayland, Windows). macOS deferred in lockstep with the platform lib.
- **Decoupling holds** — the relevant `nm` check (platform-drags-no-Vulkan / vulkan-drags-no-windowing) prints nothing.
- **Pinned submodule SHAs** — each release pins `libs/*` to the lib commits it was validated against, so the build is reproducible.

## Out of scope / deferred

- macOS target — deferred (tracks the platform lib).
- Audio-driven or networked toys — not part of the adapter-validation story.
- Textured / lit / multi-object 3D — `hello-cube` is the 3D ceiling here by design.

## See also

[`vision.md`](vision.md) · [`mission.md`](mission.md) · [`ladder.md`](ladder.md) — what each app validates + the `nm` checks · [`sprint.md`](sprint.md).
