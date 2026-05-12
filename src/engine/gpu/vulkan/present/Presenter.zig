const commands = @import("../commands.zig");
const Context = @import("../core/Context.zig");
const FrameResources = @import("FrameResources.zig");
const Swapchain = @import("Swapchain.zig");
const vk = @import("../c.zig");

swapchain: Swapchain,
frame_resources: FrameResources,
frame_index: usize = 0,

const Self = @This();

pub const Result = enum {
    presented,
    suboptimal,
    out_of_date,
};

pub const PresentedFrame = struct {
    frame: FrameResources.Frame,
    context: *Context,
    device: vk.Device,
    swapchain: *Swapchain,
    commands: commands.Commands = undefined,
    width: u32,
    height: u32,

    pub fn commandBuffer(self: *PresentedFrame) *commands.Commands {
        self.commands = .{ .context = self.context, .device = self.device, .frame = &self.frame, .swapchain = self.swapchain };
        return &self.commands;
    }
};

pub fn deinit(self: Self) void {
    self.frame_resources.deinit();
    self.swapchain.deinit();
}

pub fn beginFrame(self: *Self) !PresentedFrame {
    const frame = self.frame_resources.beginFrame(&self.swapchain, self.frame_index) catch |err| switch (err) {
        error.VulkanSwapchainOutOfDate => return error.PresentationOutOfDate,
        else => return err,
    };
    return .{
        .frame = frame,
        .context = self.frame_resources.context,
        .device = self.frame_resources.device,
        .swapchain = &self.swapchain,
        .width = self.swapchain.info.extent.width,
        .height = self.swapchain.info.extent.height,
    };
}

pub fn endFrame(self: *Self, frame: PresentedFrame) !Result {
    const result = try self.frame_resources.endFrame(&self.swapchain, frame.frame, vk.colorAttachmentOutputStage());
    self.frame_index += 1;
    return switch (result) {
        .presented => .presented,
        .suboptimal => .suboptimal,
        .out_of_date => .out_of_date,
    };
}
