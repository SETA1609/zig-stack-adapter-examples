# libs/ — adapter sub-repos (built first, linked as artifacts)

This folder holds the adapter libraries **as git submodules**. The examples build each lib once into a static-library artifact and **link the compiled artifact**, rather than inlining the lib's sources into every app.

## Add the submodules

```sh
git submodule add git@github.com:SETA1609/zig-cpp-platform-stack-adapter.git libs/zig-cpp-platform-stack-adapter
git submodule add git@github.com:SETA1609/zig-cpp-vulkan-stack-adapter.git   libs/zig-cpp-vulkan-stack-adapter
git submodule update --init --recursive
```

Pin each submodule to a released tag (`platform` → `v0.6.0`, `vulkan` → `v0.2.0`+) so example builds are reproducible:

```sh
cd libs/zig-cpp-platform-stack-adapter && git checkout v0.6.0 && cd ../..
git add libs/zig-cpp-platform-stack-adapter
```

`build.zig.zon` then references them by **local path** (already wired):

```zig
.dependencies = .{
    .platform = .{ .path = "libs/zig-cpp-platform-stack-adapter" },
    .vulkan_stack = .{ .path = "libs/zig-cpp-vulkan-stack-adapter" },
},
```

## Build-then-link, in `build.zig`

Each adapter's `build.zig` exposes two things:

- a **module** — the importable Zig API (`dep.module("platform")`)
- a **static-library artifact** — the compiled code, incl. the heavy C/C++ (`dep.artifact("platform")`)

An example imports the module for the API and **links the artifact** for the compiled code:

```zig
const platform_dep = b.dependency("platform", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("platform", platform_dep.module("platform"));
exe.linkLibrary(platform_dep.artifact("platform"));   // ← link the compiled lib, not its sources
```

So SDL3 / VMA / glslang are compiled **once, inside each lib**, and reused as a binary by every example — exactly how the engine will consume these adapters.

## The one honest caveat

Zig has **no compiled-module format** — there's no `.a` you can import to get a Zig API without its source. So:

- The **heavy C/C++** (SDL3, VMA, shaderc/glslang) genuinely *is* compiled-once-and-linked as a binary artifact. ✅
- The **thin Zig wrapper** on top (the few hundred lines of `root.zig`/`vma.zig`/etc.) is always consumed from the lib's **source** when you `addImport` its module. Zig's incremental cache means it isn't *recompiled* every build, but it isn't a prebuilt binary either.

If you ever want a *fully* source-free link (prebuilt `.a` + a C header, no Zig source at all), the lib would have to expose a **C ABI** and you'd `@cImport` it — but then you lose the idiomatic Zig API. The adapters deliberately expose a Zig API, so the module-import-plus-artifact-link model above is the right one here.

## Why submodules under `libs/` (not git-URL fetches)

- The libs are **your own repos under active development** — a local checkout lets you edit a lib and rebuild an example in one loop, no publish-fetch cycle.
- Pinned submodule SHAs keep example builds reproducible.
- It mirrors the engine's own `libs/` layout, so the consumption shape you validate here is the shape the engine uses.
