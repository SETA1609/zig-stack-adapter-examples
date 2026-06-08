//! Build script for zig-stack-adapter-examples.
//!
//! Model: this repo reaches the adapter libs (windowing/input + the vulkan
//! stack) **only through zGameLib** — never directly. zGameLib owns the adapter
//! submodules, compiles them once into static-library artifacts, and re-exports
//! two flavours of itself as importable modules:
//!
//!   - `zgame`           — the full framework (platform + vulkan + the surface
//!                         bridge + swapchain); links BOTH adapter artifacts.
//!   - `zgame_platform`  — platform-only (windowing/input); links ONLY the
//!                         platform artifact, so it drags no vulkan. This is the
//!                         import path for any binary that must show zero
//!                         vk*/VK_ symbols (the rung-0 decoupling gate, the
//!                         OpenGL hand-off) while still going *through* the
//!                         framework.
//!
//! Importing a module propagates its linked artifacts, so a single
//! `addImport("zgame", …)` is all a target needs. Wires rung 0 (`event-logger`,
//! platform-only) and rung 1 (`clear-color`); `-Dshaderc` is passed through to
//! the vulkan stack. Rungs ≥ 2 land here. The cross-lib behavioural test suite
//! lives in zGameLib (`cd libs/zGameLib && zig build test-tdd`), not here.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Passed through to zGameLib → the vulkan stack: build it with runtime
    // GLSL→SPIR-V (shaderc). Off by default (the shaderc integration tests then
    // skip); `-Dshaderc` turns it on, which fetches+builds shaderc from source.
    const enable_shaderc = b.option(bool, "shaderc", "Build the vulkan stack with runtime shaderc (GLSL→SPIR-V)") orelse false;

    const zgame_dep = b.dependency("zgame", .{
        .target = target,
        .optimize = optimize,
        .shaderc = enable_shaderc,
    });
    const zgame_mod = zgame_dep.module("zgame"); // full framework (platform + vulkan)
    const zgame_platform_mod = zgame_dep.module("zgame_platform"); // platform-only (no vulkan)

    // --- Rung 0: event-logger (platform-only) ------------------------------
    // Goes through the framework's platform-only flavour: it links no vulkan, so
    // the binary stays clean for rung 0's `nm` decoupling gate (zero vk*/VK_) —
    // and `zgame.vk` & friends literally don't exist on this module, so the
    // decoupling is enforced by the type system, not just by the gate.
    addExample(b, .{
        .name = "event-logger",
        .source = "examples/event-logger/main.zig",
        .description = "Build + run the platform-only event logger (rung 0)",
        .target = target,
        .optimize = optimize,
        .zgame_mod = zgame_platform_mod,
    });

    // --- Rung 1: clear-color (the full `zgame` framework) ------------------
    const clear_color = b.addExecutable(.{
        .name = "clear-color",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/clear-color/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    clear_color.root_module.addImport("zgame", zgame_mod);
    b.installArtifact(clear_color);
    const run_cc = b.addRunArtifact(clear_color);
    if (b.args) |args| run_cc.addArgs(args);
    b.step("clear-color", "Build + run the reactive clear-color example")
        .dependOn(&run_cc.step);

    // NOTE: the cross-lib behavioural suite (the integration + OpenGL hand-off
    // tests) lives **inside zGameLib**, not here — it's part of the framework's
    // own contract. Run it from the submodule:
    //   cd libs/zGameLib && zig build test-tdd   (add -Dshaderc for the GLSL test)
    // This repo only builds + runs the example rungs.
}

const ExampleOpts = struct {
    name: []const u8,
    source: []const u8,
    description: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    /// The zGameLib module this example imports as `zgame` (full or platform-only).
    zgame_mod: *std.Build.Module,
};

fn addExample(b: *std.Build, opts: ExampleOpts) void {
    const exe = b.addExecutable(.{
        .name = opts.name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(opts.source),
            .target = opts.target,
            .optimize = opts.optimize,
        }),
    });
    // Single import: `zgame` carries the API and propagates the linked artifacts.
    exe.root_module.addImport("zgame", opts.zgame_mod);
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    if (b.args) |args| run.addArgs(args);
    b.step(opts.name, opts.description).dependOn(&run.step);
}
