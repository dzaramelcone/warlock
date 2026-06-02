const Context = @import("core/Context.zig");
const FrameResources = @import("present/FrameResources.zig");
const Swapchain = @import("present/Swapchain.zig");
const vk = @import("c.zig");

pub const Commands = @This();
const Frame = FrameResources.Frame;

context: *Context,
device: vk.Device,
frame: *Frame,
swapchain: *Swapchain,

const Self = @This();
