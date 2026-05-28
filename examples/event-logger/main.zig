//! Event logger — rung 0 warm-up, PLATFORM ONLY.
//!
//! Opens a window with `renderer = .none`, pumps events, prints each `Event`
//! to stdout, and quits on ESC. **Imports no `vulkan_stack`** — this binary
//! is the gate for the first `nm` decoupling check (no `vk*` / `VK_` symbols).
//!
//! Full design — frame loop, exact lib calls, success criteria:
//!   ../../docs/event-logger.md
//! Definition of done + todo list:
//!   ./README.md
//!
//! Intentionally a stub — write the implementation by hand.

// const platform = @import("platform");

pub fn main() !void {
    // TODO(you): implement per ../../docs/event-logger.md
}
