# zig-stack-adapter-examples

Tiny standalone apps that exercise the [platform-stack](https://github.com/SETA1609/zig-cpp-platform-stack-adapter) and [vulkan-stack](https://github.com/SETA1609/zig-cpp-vulkan-stack-adapter) Zig adapters **together** — starting with a reactive clear-color, building toward Snake and friends.

Each app consumes the adapters the way a real engine would — the libs live under `libs/`, get **built once into static artifacts**, and the apps **link the compiled artifacts** (not the source). So these double as **integration tests** and **usage examples**.

**License:** MIT · **Requires:** Zig 0.16+

## Why this exists

The two adapters are decoupled by design (the platform side drags no Vulkan; the vulkan side drags no windowing). These apps prove the decoupling works *and* that the two halves interoperate through the surface bridge — something the standalone unit tests can't show. Each toy is also a milestone driver: building it justifies the next slice of each library.

## Layout

```
zig-stack-adapter-examples/
├── README.md
├── LICENSE                       # MIT
├── build.zig                     # SCAFFOLD — build each lib, link its artifact (TODOs inside)
├── build.zig.zon                 # local-path deps into libs/ (no git fetch)
├── libs/                         # YOUR adapter sub-repos live here (git submodules)
│   ├── README.md                 # the build-then-link model + how to add the submodules
│   ├── zig-cpp-platform-stack-adapter/   # add as submodule
│   └── zig-cpp-vulkan-stack-adapter/     # add as submodule
├── shared/
│   └── surface.zig               # stub — the comptime platform↔vulkan bridge (you write it)
├── examples/
│   └── clear-color/
│       └── main.zig              # stub — the first app (you write it)
├── docs/
│   ├── clear-color.md            # design of the first app (frame loop + lib calls)
│   ├── ladder.md                 # the full app ladder + the nm decoupling checks
│   └── cheat_sheet.md            # Zig/C/C++ cross-language field guide
└── .github/workflows/build.yml
```

## Build model — libs first, then link the compiled artifact

The adapters live under [`libs/`](libs/) as git submodules. `build.zig.zon` references them by **local path**, and `build.zig` **links each lib's static-library artifact** (`linkLibrary`) instead of inlining its sources into every example. The heavy C/C++ (SDL3, VMA, glslang) is therefore compiled **once, inside the lib**, and reused as a binary across every app. Full rationale + the one Zig caveat: [`libs/README.md`](libs/README.md).

## The ladder

Each app pulls a specific adapter milestone into existence — see [`docs/ladder.md`](docs/ladder.md).

| App | platform → | vulkan → |
| --- | --- | --- |
| **clear-color** ← *first* | v0.6.0 | v0.2.0 |
| snake | (v0.6.0) | v0.3.0 (VMA) |
| breakout | (v0.6.0) | v0.3.0 |
| tetris | v0.7.0 (input contexts) | v0.3.0 |
| pong | v0.8.0 (gamepads) | v0.3.0 |
| life | (v0.6.0) | v0.4.0 (shaders) |

## Status & how to run

Freshly scaffolded. `build.zig`, the `libs/` submodules, and the `shared/` + `examples/` source are **stubs/TODOs** — the app code is hand-written on purpose (this is a learning project; the scaffolding is here, the implementation is yours).

To get going:

1. Add the adapter sub-repos under `libs/` as submodules — see [`libs/README.md`](libs/README.md).
2. Wire the build in [`build.zig`](build.zig): build each lib, `linkLibrary` its artifact, `addImport` its module (follow the commented pattern).
3. Implement [`shared/surface.zig`](shared/surface.zig) and [`examples/clear-color/main.zig`](examples/clear-color/main.zig) per [`docs/clear-color.md`](docs/clear-color.md).
4. `zig build clear-color`

## Docs

- [`docs/clear-color.md`](docs/clear-color.md) — the first app, designed end-to-end
- [`docs/ladder.md`](docs/ladder.md) — the validation-app ladder + the `nm` decoupling checks
- [`libs/README.md`](libs/README.md) — the libs-first / link-the-artifact build model
- [`docs/cheat_sheet.md`](docs/cheat_sheet.md) — Zig/C/C++ cross-language field guide
