# zig-stack-adapter-examples

Tiny standalone apps that exercise the [platform-stack](https://github.com/SETA1609/zig-cpp-platform-stack-adapter) and [vulkan-stack](https://github.com/SETA1609/zig-cpp-vulkan-stack-adapter) Zig adapters **together** — starting with an event logger and a reactive clear-color, building toward Snake and friends.

Each app consumes the adapters the way a real engine would — the libs live under `libs/`, get **built once into static artifacts**, and the apps **link the compiled artifacts** (not the source). So these double as **integration tests** and **usage examples**.

**License:** MIT · **Requires:** Zig 0.16+

## Why this exists

The two adapters are decoupled by design (the platform side drags no Vulkan; the vulkan side drags no windowing). These apps prove the decoupling works *and* that the two halves interoperate through the surface bridge — something the standalone unit tests can't show. Each toy is also a milestone driver: building it justifies the next slice of each library.

## Layout

```
zig-stack-adapter-examples/
├── README.md
├── LICENSE                       # MIT
├── build.zig                     # wires example run-steps + test-integration (links both lib artifacts)
├── build.zig.zon                 # local-path deps into libs/ (no git fetch)
├── libs/                         # YOUR adapter sub-repos live here (git submodules)
│   ├── README.md                 # the build-then-link model + how to add the submodules
│   ├── zig-cpp-platform-stack-adapter/   # add as submodule
│   └── zig-cpp-vulkan-stack-adapter/     # add as submodule
├── shared/
│   └── surface.zig               # stub — the comptime platform↔vulkan bridge (you write it)
├── examples/
│   ├── event-logger/main.zig     # rung 0 — platform-only (stub: hand-write it)
│   └── clear-color/main.zig      # rung 1 — platform + vulkan (stub)
├── tests/
│   └── integration_test.zig      # cross-lib tests (gated) — `zig build test-integration`
├── docs/
│   ├── clear-color.md            # design of the first app (frame loop + lib calls)
│   ├── ladder.md                 # the full app ladder + the nm decoupling checks
│   └── cheat_sheet.md            # Zig/C/C++ cross-language field guide
└── .github/workflows/build.yml
```

## Build model — libs first, then link the compiled artifact

The adapters live under [`libs/`](libs/) as git submodules. `build.zig.zon` references them by **local path**, and `build.zig` **links each lib's static-library artifact** (`linkLibrary`) instead of inlining its sources into every example. The heavy C/C++ (SDL3, VMA, glslang) is therefore compiled **once, inside the lib**, and reused as a binary across every app. Full rationale + the one Zig caveat: [`libs/README.md`](libs/README.md).

## The ladder

Each app pulls a specific adapter milestone into existence — see [`docs/ladder.md`](docs/ladder.md) for the full per-rung ladder (17 rungs) + ordering rationale. Grouped here by lib-milestone phase:

| Phase | Apps | platform → | vulkan → |
| --- | --- | --- | --- |
| Foundation | event-logger, clear-color | v0.6.0 | v0.2.0 |
| First pipeline | hello-triangle | (v0.6.0) | v0.3.0 |
| Games & texturing | snake, asteroids, breakout, space-invaders, image-viewer | v0.6.0 | v0.3.0 |
| Input depth | tetris, replay-demo | v0.7.0 | v0.3.0 |
| Devices & persistence | pong, 2048, typing-game | v0.8.0 | v0.3.0 |
| Shaders & compute | life, particles, shader-playground | (v0.6.0) | v0.4.0 |
| 3D smoke *(tail)* | hello-cube | (v0.6.0) | v0.4.0 + depth |

## Status & how to run

The build is wired and the libraries are partway up the ladder:

- **platform adapter** — v0.6.0 core implemented (window, events, time, action-mapped input, Vulkan hand-off).
- **vulkan adapter** — `vk` re-export + pure-Zig `volk` loader + X11/Wayland surface creators implemented; VMA + shaderc still stubbed.
- **cross-lib hand-off works** — a platform `.vulkan` window's native handle becomes a Vulkan surface (proven by the integration tests below).

Clone with submodules, then:

```sh
git submodule update --init --recursive

zig build event-logger        # rung 0 — build + run the platform-only example (once you write its main.zig)
zig build test-integration    # cross-lib tests: platform handles → vulkan instance + surface
zig build --help              # list available steps
```

`zig build test-integration` today: **instance + surface hand-off pass; `full_stack` skips until VMA lands.** The integration tests are gated and un-skip as the vulkan bridges are implemented.

The example **app code is still hand-written on purpose** (this is a learning project): `examples/event-logger/main.zig` and `examples/clear-color/main.zig` are stubs you fill in — `docs/clear-color.md` designs the first windowed app end-to-end, and the platform README's quick-start shows the input/window API. The libraries underneath them are real (above).

## Docs

- [`docs/getting-started.md`](docs/getting-started.md) — **start here**: clone, build, run the tests, and the two-lib hand-off walkthrough
- [`docs/vision.md`](docs/vision.md) — what this repo is for; the decoupled-but-interoperating north star
- [`docs/mission.md`](docs/mission.md) — the concrete build/bridge/decoupling commitments
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — the release sequence (one ladder rung per release) + lib version gates
- [`docs/sprint.md`](docs/sprint.md) — the current sprint (Foundation + clear-color → v0.1.0)
- [`docs/clear-color.md`](docs/clear-color.md) — the first app, designed end-to-end
- [`docs/ladder.md`](docs/ladder.md) — the validation-app ladder + the `nm` decoupling checks
- [`libs/README.md`](libs/README.md) — the libs-first / link-the-artifact build model
- [`docs/cheat_sheet.md`](docs/cheat_sheet.md) — Zig/C/C++ cross-language field guide
