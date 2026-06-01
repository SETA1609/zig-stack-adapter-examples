//! Integration tests — the two adapters working **together**.
//!
//! The platform adapter opens a window and hands back **raw OS primitives** +
//! the required Vulkan instance extensions; the vulkan adapter turns those into
//! an instance + surface (+ device + allocator) — with **no shared type**
//! crossing between the libraries. That handshake is the whole reason the two
//! repos exist, and it can only be exercised here, with both linked.
//!
//! Gated: the platform side is already real, so these skip until the vulkan
//! adapter's volk + surface bridges land — flip the `done` flags then. Needs a
//! display server **and** a Vulkan loader.

const std = @import("std");
const builtin = @import("builtin");
const platform = @import("platform");
const vk_stack = @import("vulkan_stack");

const vk = vk_stack.vk;
const volk = vk_stack.volk;
const vma = vk_stack.vma;

fn gate(implemented: bool) error{SkipZigTest}!void {
    if (!implemented) return error.SkipZigTest;
}

/// Flip as the vulkan-stack bridges are implemented (the platform side is done).
const done = .{
    .instance_from_platform_extensions = true,
    .surface_handoff = true,
    .full_stack = true,
};

/// A platform `.vulkan` window + a Vulkan instance built from the platform's
/// **required extensions** — the cross-lib bootstrap shared by the tests.
const Bootstrap = struct {
    win: *platform.Window,
    instance: vk.Instance,
    vki: vk.InstanceWrapper,

    fn init() !Bootstrap {
        try platform.init(.{});
        const win = try platform.Window.create(.{ .title = "integration", .renderer = .vulkan });
        const exts = platform.requiredVulkanInstanceExtensions();

        try volk.loadBase();
        const gipa = volk.getInstanceProcAddr();
        const vkb = vk.BaseWrapper.load(gipa);
        // Request Vulkan 1.3 so the device promotes the 1.1+ core entry points VMA needs.
        const app_info = vk.ApplicationInfo{
            .application_version = 0,
            .engine_version = 0,
            .api_version = @bitCast(vk.API_VERSION_1_3),
        };
        const instance = try vkb.createInstance(&.{
            .p_application_info = &app_info,
            .enabled_extension_count = @intCast(exts.len),
            .pp_enabled_extension_names = exts.ptr,
        }, null);
        volk.loadInstance(instance);
        const vki = vk.InstanceWrapper.load(instance, gipa);
        return .{ .win = win, .instance = instance, .vki = vki };
    }

    fn deinit(self: *Bootstrap) void {
        self.vki.destroyInstance(self.instance, null);
        self.win.destroy();
        platform.deinit();
    }

    /// The cross-lib hand-off: turn this window's native handle into a surface,
    /// or `null` on a display server we don't cover here.
    fn surface(self: *Bootstrap) !?vk.SurfaceKHR {
        if (platform.getX11Handle(self.win)) |hnd| {
            return try vk_stack.createX11Surface(self.instance, hnd.display, hnd.window);
        } else if (platform.getWaylandHandle(self.win)) |hnd| {
            return try vk_stack.createWaylandSurface(self.instance, hnd.display, hnd.surface);
        }
        return null;
    }
};

test "instance: builds from the platform's required Vulkan extensions" {
    try gate(done.instance_from_platform_extensions);
    var bs = try Bootstrap.init();
    defer bs.deinit();
    try std.testing.expect(@intFromEnum(bs.instance) != 0);
}

test "instance: the platform requires at least a surface extension" {
    try gate(done.instance_from_platform_extensions);
    try platform.init(.{});
    defer platform.deinit();
    try std.testing.expect(platform.requiredVulkanInstanceExtensions().len > 0);
}

test "surface: a platform window's native handle becomes a non-null Vulkan surface" {
    try gate(done.surface_handoff);
    var bs = try Bootstrap.init();
    defer bs.deinit();
    const surface = (try bs.surface()) orelse return error.SkipZigTest;
    defer bs.vki.destroySurfaceKHR(bs.instance, surface, null);
    try std.testing.expect(surface != .null_handle);
}

test "surface: hand-off works for a second freshly created window" {
    try gate(done.surface_handoff);
    var bs = try Bootstrap.init();
    defer bs.deinit();
    const a = (try bs.surface()) orelse return error.SkipZigTest;
    bs.vki.destroySurfaceKHR(bs.instance, a, null);
    const b = (try bs.surface()) orelse return error.SkipZigTest;
    defer bs.vki.destroySurfaceKHR(bs.instance, b, null);
    try std.testing.expect(b != .null_handle);
}

test "full stack: window → instance → surface → device → VMA allocator" {
    try gate(done.full_stack);
    var bs = try Bootstrap.init();
    defer bs.deinit();

    const surface = (try bs.surface()) orelse return error.SkipZigTest;
    defer bs.vki.destroySurfaceKHR(bs.instance, surface, null);

    var n: u32 = 1;
    var physical: vk.PhysicalDevice = undefined;
    _ = try bs.vki.enumeratePhysicalDevices(bs.instance, &n, @ptrCast(&physical));

    const prio = [_]f32{1.0};
    const qci = [_]vk.DeviceQueueCreateInfo{.{
        .queue_family_index = 0,
        .queue_count = 1,
        .p_queue_priorities = &prio,
    }};
    const device = try bs.vki.createDevice(physical, &.{
        .queue_create_info_count = 1,
        .p_queue_create_infos = &qci,
    }, null);
    volk.loadDevice(device);
    const vkd = vk.DeviceWrapper.load(device, bs.vki.dispatch.vkGetDeviceProcAddr.?);
    defer vkd.destroyDevice(device, null);

    const allocator = try vma.createAllocator(.{ .physical_device = physical, .device = device, .instance = bs.instance });
    defer vma.destroyAllocator(allocator);
    try std.testing.expect(@intFromPtr(allocator) != 0);
}
