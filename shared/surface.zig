//! Comptime platform↔vulkan surface bridge, reused by every example.
//!
//! Pairs the platform adapter's per-OS native-handle getter with the vulkan
//! adapter's matching surface creator, branching on the target OS at comptime.
//! Design + the exact calls: ../docs/clear-color.md § The surface bridge.
//!
//! Intentionally a stub — write the bridge by hand.

// const builtin = @import("builtin");
// const platform = @import("platform");
// const vulkan_stack = @import("vulkan_stack");
// const vk = vulkan_stack.vk;

// TODO(you): implement, e.g.
//   pub fn createSurface(instance: vk.Instance, window: *platform.Window) !vk.SurfaceKHR {
//       return switch (comptime builtin.target.os.tag) { ... };
//   }
