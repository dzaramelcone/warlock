const std = @import("std");
pub const Api = @import("../api.zig");
const platform = @import("../../platform/mod.zig");
const commands = @import("commands.zig");
const memory_core = @import("core/memory.zig");
const queue_core = @import("core/queues.zig");
const swapchain_info = @import("core/swapchain_info.zig");

pub const MemoryTypeInfo = memory_core.TypeInfo;
pub const QueueFamilySelection = queue_core.Selection;
pub const SwapchainInfo = swapchain_info.Info;

pub const Context = @import("core/Context.zig");
pub const Surface = @import("core/Surface.zig");

pub const Device = @import("core/Device.zig");
pub const GraphicsCommands = commands.Commands;

pub const HostBuffer = @import("core/HostBuffer.zig");

pub const Presenter = @import("present/Presenter.zig");

pub const Graphics = struct {
    allocator: std.mem.Allocator,
    context: *Context,
    surface: Surface,
    device: Device,
    presenter_impl: Presenter,

    pub fn init(allocator: std.mem.Allocator, window: platform.Window) !Graphics {
        const context = try allocator.create(Context);
        errdefer allocator.destroy(context);
        context.* = try Context.init(allocator);
        errdefer context.deinit();

        const surface = try createSurface(context, window);
        errdefer surface.deinit();

        const queues = try context.findQueueFamilies(surface);
        const device = try Device.create(context, queues);
        errdefer device.deinit();

        var initial_swapchain = try device.createSwapchain(surface);
        errdefer initial_swapchain.deinit();
        const initial_frame_resources = try device.createFrameResources(initial_swapchain.info.image_count);
        var initial_presenter = Presenter{ .swapchain = initial_swapchain, .frame_resources = initial_frame_resources };
        errdefer initial_presenter.deinit();

        return .{
            .allocator = allocator,
            .context = context,
            .surface = surface,
            .device = device,
            .presenter_impl = initial_presenter,
        };
    }

    pub fn deinit(self: *Graphics) void {
        self.presenter_impl.deinit();
        self.device.deinit();
        self.surface.deinit();
        self.context.deinit();
        self.allocator.destroy(self.context);
    }

    pub fn waitIdle(self: *Graphics) !void {
        try self.device.waitIdle();
    }

    pub fn deviceName(self: *Graphics) []const u8 {
        return self.context.device_name;
    }

    pub fn presenter(self: *Graphics) *Presenter {
        return &self.presenter_impl;
    }

    pub fn recreatePresentation(self: *Graphics) !void {
        try self.device.waitIdle();
        var next_swapchain = try self.device.createSwapchainReplacing(self.surface, self.presenter_impl.swapchain.swapchain);
        errdefer next_swapchain.deinit();
        const next_frame_resources = try self.device.createFrameResources(next_swapchain.info.image_count);
        var next_presenter = Presenter{ .swapchain = next_swapchain, .frame_resources = next_frame_resources };
        errdefer next_presenter.deinit();
        self.presenter_impl.deinit();
        self.presenter_impl = next_presenter;
    }

    fn createSurface(context: *Context, window: platform.Window) !Surface {
        const handle = window.nativeHandle();
        return try context.createWin32Surface(handle.hinstance, handle.hwnd);
    }
};

pub const Swapchain = @import("present/Swapchain.zig");
pub const FrameResources = @import("present/FrameResources.zig");
pub const FrameResource = FrameResources.Resource;
pub const Frame = FrameResources.Frame;
pub const ClearPresentResult = FrameResources.PresentResult;
