# Getting started — examples repo

This repo consumes the two adapters **together** the way a real engine would:
each lib builds once into a static artifact, the apps link the artifacts. It
doubles as the integration-test bed for the platform↔vulkan hand-off.

**Requires Zig 0.16+** (a display server + a Vulkan loader for the windowed/
integration bits).

## 1. Clone with submodules

The adapters live under `libs/` as git submodules:

```sh
git clone https://github.com/SETA1609/zig-stack-adapter-examples.git
cd zig-stack-adapter-examples
git submodule update --init --recursive
```

## 2. What you can build today

```sh
zig build --help              # list steps
zig build event-logger        # rung 0 — platform-only example (once its main.zig is written)
zig build test-integration    # cross-lib tests: platform handles → vulkan instance + surface
```

- `event-logger` is **rung 0** (platform-only; the `nm` decoupling baseline). Its
  `main.zig` is a stub you hand-write — see [`event-logger.md`](event-logger.md)
  and the platform lib's `docs/getting-started.md`.
- `test-integration` today: **all 5 pass** — instance from the platform's
  extensions, the surface hand-off, and the full stack (window → instance →
  surface → device → VMA allocator).

## 3. The build model — libs first, link the artifact

`build.zig.zon` references the libs by **local path** (no git fetch); `build.zig`
imports each lib's **module** and links its **static-library artifact**, so the
heavy C/C++ (SDL3, the Vulkan stack) compiles once inside the lib and is reused
across apps. Full rationale: [`../libs/README.md`](../libs/README.md).

## 4. The cross-lib hand-off (the whole point)

The two libs share **no type** — they meet only at raw OS primitives:

```
platform.Window.create(.{ .renderer = .vulkan })
  ├─ requiredVulkanInstanceExtensions()  ─┐
  └─ getX11Handle(win) → { display, window } ─┐
                                              ▼
   vulkan: volk.loadBase() → vk.BaseWrapper.load(volk.getInstanceProcAddr())
           → createInstance(exts) → createX11Surface(instance, display, window)
                                              │
                                              ▼
                                   a non-null VkSurfaceKHR
```

`tests/integration_test.zig` is this handshake, end to end — read it as the
canonical "two libs together" example. The `shared/surface.zig` stub is where a
real app would put the comptime, per-OS bridge that picks the right
`get*Handle` → `create*Surface` pair.

## 5. The ladder

Apps are built in a fixed order; each pulls a specific lib milestone into
existence. See [`ladder.md`](ladder.md) for all rungs and
[`ROADMAP.md`](ROADMAP.md) for the release sequence. Rung 0 (event-logger) and
rung 1 (clear-color) are the Foundation phase — both unblocked on the lib side
now (window + events + surface), so the remaining work there is the example code.

## 6. The decoupling checks (`nm`)

Two gates the apps exist to prove (see [`ladder.md`](ladder.md)):

- a platform-only binary (`renderer = .none`) shows **zero `vk*` / `VK_`** symbols;
- a headless-Vulkan binary shows **zero `SDL_` / `x11` / `wayland`** symbols.

## Next

- [`../libs/zig-cpp-platform-stack-adapter/docs/getting-started.md`](../libs/zig-cpp-platform-stack-adapter/docs/getting-started.md) — the windowing/input half
- [`../libs/zig-cpp-vulkan-stack-adapter/docs/getting-started.md`](../libs/zig-cpp-vulkan-stack-adapter/docs/getting-started.md) — the Vulkan half
- [`clear-color.md`](clear-color.md) — the first windowed app, designed end-to-end · [`cheat_sheet.md`](cheat_sheet.md) — Zig/C/C++ field guide
