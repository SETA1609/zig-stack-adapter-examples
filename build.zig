//! Build script for zig-stack-adapter-examples.
//!
//! Intentionally a SCAFFOLD. The shell is here; the per-example wiring is left
//! for you (wiring the Zig build system is part of this learning repo). Fill in
//! the TODO blocks — then `zig build clear-color` builds + runs the example.
//!
//! Model: build each adapter lib once (its own build.zig produces a static-
//! library artifact) and LINK that artifact; import the lib's module for the
//! Zig API. See libs/README.md.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1) Pull the adapters (after you uncomment them in build.zig.zon):
    //      const platform_dep = b.dependency("platform", .{ .target = target, .optimize = optimize });
    //      const vulkan_dep   = b.dependency("vulkan_stack", .{ .target = target, .optimize = optimize });

    // 2) Shared comptime surface bridge (shared/surface.zig — you write it),
    //    importing both adapters' modules:
    //      const surface_mod = b.createModule(.{
    //          .root_source_file = b.path("shared/surface.zig"),
    //          .target = target, .optimize = optimize,
    //      });
    //      surface_mod.addImport("platform", platform_dep.module("platform"));
    //      surface_mod.addImport("vulkan_stack", vulkan_dep.module("vulkan_stack"));

    // 3) One executable + run step per examples/<name>/main.zig. For clear-color:
    //      const exe = b.addExecutable(.{ .name = "clear-color", .root_module = b.createModule(.{
    //          .root_source_file = b.path("examples/clear-color/main.zig"),
    //          .target = target, .optimize = optimize,
    //      }) });
    //      // import the Zig APIs:
    //      exe.root_module.addImport("platform", platform_dep.module("platform"));
    //      exe.root_module.addImport("vulkan_stack", vulkan_dep.module("vulkan_stack"));
    //      exe.root_module.addImport("surface", surface_mod);
    //      // link the COMPILED lib artifacts (not their sources):
    //      exe.linkLibrary(platform_dep.artifact("platform"));
    //      exe.linkLibrary(vulkan_dep.artifact("vulkan_stack"));
    //      b.installArtifact(exe);
    //      const run = b.addRunArtifact(exe);
    //      if (b.args) |args| run.addArgs(args);
    //      b.step("clear-color", "Build + run the reactive clear-color example").dependOn(&run.step);

    // Remove these two once the wiring above is live.
    _ = target;
    _ = optimize;
}
