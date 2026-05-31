//! Build script for zig-stack-adapter-examples.
//!
//! Model: each adapter lib builds itself once (its own build.zig produces a
//! static-library artifact) and we LINK that artifact; we import the lib's
//! module for the Zig API. See libs/README.md.
//!
//! Today wires only the **platform** side — enough to build the rung-0
//! `event-logger` example, which is platform-only (PLATFORM ONLY per
//! docs/event-logger.md). The vulkan_stack + surface wiring lights up once
//! the vulkan-stack lib starts exposing its module/artifact; the commented
//! blocks below mark the exact spots to uncomment.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const platform_dep = b.dependency("platform", .{
        .target = target,
        .optimize = optimize,
    });
    // const vulkan_dep = b.dependency("vulkan_stack", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    // Shared comptime surface bridge. Stays inert until vulkan_stack lands —
    // shared/surface.zig is currently a stub with both imports commented out.
    // const surface_mod = b.createModule(.{
    //     .root_source_file = b.path("shared/surface.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // surface_mod.addImport("platform", platform_dep.module("platform"));
    // surface_mod.addImport("vulkan_stack", vulkan_dep.module("vulkan_stack"));

    // --- Rung 0: event-logger (platform-only) -----------------------------
    addExample(b, .{
        .name = "event-logger",
        .source = "examples/event-logger/main.zig",
        .description = "Build + run the platform-only event logger (rung 0)",
        .target = target,
        .optimize = optimize,
        .platform_dep = platform_dep,
    });

    // --- Rung 1: clear-color (platform + vulkan_stack + surface) ---------
    // Enable once vulkan_stack ships its `vulkan_stack` module + artifact.
    // const clear_color = b.addExecutable(.{
    //     .name = "clear-color",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("examples/clear-color/main.zig"),
    //         .target = target, .optimize = optimize,
    //     }),
    // });
    // clear_color.root_module.addImport("platform", platform_dep.module("platform"));
    // clear_color.root_module.addImport("vulkan_stack", vulkan_dep.module("vulkan_stack"));
    // clear_color.root_module.addImport("surface", surface_mod);
    // clear_color.root_module.linkLibrary(platform_dep.artifact("platform"));
    // clear_color.root_module.linkLibrary(vulkan_dep.artifact("vulkan_stack"));
    // b.installArtifact(clear_color);
    // const run_cc = b.addRunArtifact(clear_color);
    // if (b.args) |args| run_cc.addArgs(args);
    // b.step("clear-color", "Build + run the reactive clear-color example")
    //     .dependOn(&run_cc.step);
}

const ExampleOpts = struct {
    name: []const u8,
    source: []const u8,
    description: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    platform_dep: *std.Build.Dependency,
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
    exe.root_module.addImport("platform", opts.platform_dep.module("platform"));
    exe.root_module.linkLibrary(opts.platform_dep.artifact("platform"));
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    if (b.args) |args| run.addArgs(args);
    b.step(opts.name, opts.description).dependOn(&run.step);
}
