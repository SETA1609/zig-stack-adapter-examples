//! Reactive clear-color — the first example that drives BOTH adapters together.
//!
//! Opens a window (platform), builds a Vulkan surface + swapchain (vulkan_stack
//! via shared/surface.zig), and clears the screen each frame to a colour that
//! reacts to input. Quits on ESC; recreates the swapchain on resize.
//!
//! Full design — frame loop, exact lib calls, success criteria:
//!   ../../docs/clear-color.md
//!
//! Intentionally a stub — write the implementation by hand.

// const platform = @import("platform");
// const vulkan_stack = @import("vulkan_stack");
// const surface = @import("surface");

pub fn main() !void {
    // TODO(you): implement per ../../docs/clear-color.md
}
