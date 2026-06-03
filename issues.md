# Candidate issues — examples monorepo

Each section is a standalone, real-world task. The reusable swapchain helper is
`shared/swapchain.zig` (renderer policy lives here, not in the vulkan lib — see
`CLAUDE.md`). Today its format / present-mode / image-count selection is
hardcoded inside `Swapchain.build` and the private `chooseFormat` /
`choosePresentMode` / `chooseExtent` helpers. These tasks make selection
**configurable and deterministic**, and require the selection logic to be
exposed as **pure functions** so it can be unit-tested without a GPU.

For each, expose the function with the exact signature given (so it can be
called directly from a test) and route `Swapchain.build` through it. Add a
`zig build test-swapchain` step that runs `test` blocks in `shared/swapchain.zig`,
and wire it in `build.zig` (mirror the existing module wiring).

---

## Issue 1 — Let consumers pick a preferred surface format

`chooseFormat` (`shared/swapchain.zig` ~line 95) always wants `b8g8r8a8_srgb` +
`srgb_nonlinear_khr` and otherwise returns `formats[0]`. A consumer (e.g. an HDR
or UNORM path) can't ask for a different format. Add a preference, exposed as a
pure function:

```zig
pub fn pickSurfaceFormat(
    available: []const vk.SurfaceFormatKHR,
    preferred: ?vk.SurfaceFormatKHR,
) vk.SurfaceFormatKHR;
```

**Requirements** (unit-tested over synthetic `available` slices):

1. If `preferred` is non-null **and present in `available`**, return it.
2. Else if the sRGB default (`b8g8r8a8_srgb` / `srgb_nonlinear_khr`) is in
   `available`, return that.
3. Else return `available[0]`.
4. The returned format is **always an element of `available`** — never a
   `preferred` value that the surface doesn't actually support.

**Notes.** Requirement 4 is the easy miss: returning `preferred` without
checking membership hands back an unsupported format. Compare both `.format`
*and* `.color_space`.

---

## Issue 2 — Add a vsync preference for the present mode

`choosePresentMode` (~line 104) hardcodes `mailbox` → `fifo`. Add a vsync toggle,
exposed as a pure function:

```zig
pub fn pickPresentMode(
    available: []const vk.PresentModeKHR,
    vsync: bool,
) vk.PresentModeKHR;
```

**Requirements:**

1. `vsync = true` → always returns `.fifo_khr`, regardless of `available`
   (FIFO is guaranteed present by the Vulkan spec, and is the vsync mode).
2. `vsync = false` and `.mailbox_khr` in `available` → `.mailbox_khr`.
3. `vsync = false`, no mailbox but `.immediate_khr` in `available` →
   `.immediate_khr`.
4. `vsync = false` and neither present → `.fifo_khr` (guaranteed fallback).

**Notes.** Two easy misses: returning `.mailbox_khr` when `vsync = true` (it
isn't vsync), and treating "nothing matched" as an error — the function must
never fail, because FIFO is always available.

---

## Issue 3 — Honor the `maxImageCount == 0` "unlimited" sentinel

`build` computes the image count inline as `minImageCount + 1` clamped to
`maxImageCount`. Generalize it to a requested count (default 3, for triple
buffering) clamped into the device's allowed range, exposed as a pure function:

```zig
pub fn pickImageCount(caps: vk.SurfaceCapabilitiesKHR, desired: u32) u32;
```

**Requirements:**

1. `minImageCount = 2`, `maxImageCount = 0`, `desired = 3` → `3`.
2. `minImageCount = 2`, `maxImageCount = 2`, `desired = 3` → `2` (clamped to max).
3. `minImageCount = 3`, `maxImageCount = 8`, `desired = 2` → `3` (raised to min).
4. The result is **never `0`** and never below `minImageCount`.

**Notes.** In Vulkan, `maxImageCount == 0` means **no upper limit** — the easy
miss is clamping `desired` to `maxImageCount` unconditionally, which yields `0`
(an invalid swapchain) on every mainstream driver that reports `0`.
