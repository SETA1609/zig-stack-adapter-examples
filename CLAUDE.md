# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A monorepo of tiny standalone Zig apps that exercise two sibling adapter libraries **together** — to serve as integration tests, usage examples, and milestone drivers for those libs. It is **not** an engine or a library; the apps are throwaway toys.

The two libs are git submodules under `libs/` and are **the user's own repos under active development**:

- `libs/zig-cpp-platform-stack-adapter` — windowing + input (SDL3 backend), renderer-agnostic, drags **no Vulkan**. Exposes Zig module `platform`.
- `libs/zig-cpp-vulkan-stack-adapter` — the Vulkan stack (vulkan-zig `vk` + volk + VMA + shaderc), drags **no windowing**. Exposes Zig module `vulkan_stack`.

> **The app code is hand-written by design** (this is a learning project) — read `docs/<app>.md` for the intended implementation before filling in any remaining stub. Rungs 0–1 are now implemented: `build.zig` is wired, `shared/surface.zig` + `shared/swapchain.zig` are real, and both `examples/event-logger/main.zig` and `examples/clear-color/main.zig` build and run. Rungs ≥ 2 are still stubs/TODOs — empty function bodies and commented-out wiring there are by design, not bugs.

## Core architecture: libs-first, link-the-artifact

This is the one big idea that requires reading multiple files (`build.zig`, `build.zig.zon`, `libs/README.md`) to grasp:

- Each adapter's own `build.zig` exposes **two things**: a **module** (the importable Zig API) and a **static-library artifact** (the compiled code, including the heavy C/C++ — SDL3, VMA, glslang).
- An example **imports the module** for the API and **links the artifact** for the compiled code. So SDL3/VMA/glslang compile **once, inside each lib**, and are reused as a binary across every app — the exact shape the downstream zVoxRealms engine consumes them.
- `build.zig.zon` references the libs by **local path** (`.path = "libs/..."`), not a git-URL fetch — editing a lib and rebuilding an example is one loop.

Wiring names you need when editing `build.zig` (these are not interchangeable):

| `build.zig.zon` dep key | `dep.module(...)` | `dep.artifact(...)` |
| --- | --- | --- |
| `platform` | `"platform"` | `"platform"` |
| `vulkan_stack` | `"vulkan_stack"` | `"vulkan_stack"` |

`shared/surface.zig` is compiled into a local module imported as `surface`, and `shared/swapchain.zig` into one imported as `swapchain`. Follow the pattern already in `build.zig`.

## The surface bridge + the decoupling invariant

The two adapters are decoupled by design and meet at **exactly one place**: `shared/surface.zig`. It is a `comptime`-branched (on target OS) bridge that pairs a platform native-handle *getter* with a vulkan surface *creator*, passing **raw OS primitives** — **no shared type crosses the boundary**. Reused unchanged by every app. Design + exact calls: `docs/clear-color.md` § The surface bridge.

Two `nm` decoupling checks are **required gates** (see `docs/ladder.md` § Decoupling checks), and protecting them constrains how you write apps:

- A platform-only binary (`renderer = .none`) must pull in **none of our Vulkan stack** — `nm` shows no vulkan-zig `vk.`-namespaced wrappers and no `volk`/`vma`/`shaderc_` symbols. (Bare `vk*` C symbols are *expected* and ignored: SDL3, the platform backend, ships its own Vulkan loader, so they appear in every SDL3-linked binary. The check matches what's unique to our stack — see `docs/ladder.md` § Decoupling checks; `scripts/ci.sh decoupling` is the source of truth.)
- A headless-vulkan binary (no window) must show **zero `SDL_`/`x11`/`wayland`** symbols.

A symbol leaking across that boundary is a bug to fix immediately, not to work around.

The swapchain (`shared/swapchain.zig`) deliberately lives here too — it is **renderer policy** (format/present-mode choice, recreation, image views), which the vulkan lib leaves to the consumer. It is reused by every rung from `clear-color` up; it is **not** in the vulkan lib.

## The ladder (build order)

Apps are built in a fixed sequence; each rung pulls a specific lib milestone into existence and unblocks the next. Rungs 0 (`event-logger`) and 1 (`clear-color`) are implemented and build/run; the next target is rung 2 (`hello-triangle`). Authoritative tables: `docs/ROADMAP.md` (release sequence + lib version gates) and `docs/ladder.md` (what each rung validates). Sprint 1 plan: `docs/sprint.md`.

Constraints from the ladder: apps stay **2D (quads + ortho)** to exercise the adapters without becoming a renderer; `hello-cube` (the tail rung) is the **only** 3D app and is a single untextured smoke test.

## Commands

Requires **Zig 0.16+**.

```sh
# After cloning (submodules are how the libs are present):
git submodule update --init --recursive

zig build                 # build everything (event-logger + clear-color)
zig build <example>       # build + run one example, e.g. `zig build clear-color` (named run steps, one per example)
zig build test-integration         # cross-lib integration tests (add `-Dshaderc` to include the shaderc GLSL→SPIR-V test)
zig build --help          # list the available example steps
zig fmt --check .         # formatting check (CI runs this)
```

There is no test runner yet; "done" for an app means it **builds and runs correctly** (not merely compiles) and the relevant `nm` decoupling check is empty.

## Conventions

- **Commits:** Conventional Commits, subject ≤ 72 chars; each `[ ]` item in `docs/sprint.md` is one atomic commit. Do **not** add a `Co-Authored-By: Claude` trailer (user preference). The user commits with author `seta1609 <sebastian.stp16@gmail.com>`.
- **Submodules** should be pinned to released lib tags for reproducibility (`platform` → v0.6.0, `vulkan` → v0.2.0+); they are currently pinned to `main` HEAD commits.
- **Zig 0.16 + C/C++ FFI traps** (Io/ArrayList/`main` stdlib changes, slices vs. strings, linking C++ across the ABI): `docs/cheat_sheet.md` is the field guide — consult it before debugging cross-language build errors.

## Key docs

- `README.md` — overview + the ladder table
- `docs/vision.md`, `docs/mission.md` — what the repo is for; the concrete commitments
- `docs/ROADMAP.md`, `docs/sprint.md`, `docs/ladder.md` — release sequence, current sprint, per-app validation
- `docs/clear-color.md` — the first app designed end-to-end (frame loop + exact lib calls)
- `libs/README.md` — the libs-first / link-the-artifact build model, in depth
- Each submodule's own `docs/` (vision/mission/ROADMAP/sprint/api) — the libs' internal plans
