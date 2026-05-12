const Context = @import("../core/Context.zig");
const SwapchainInfo = @import("../core/swapchain_info.zig").Info;
const vk = @import("../c.zig");

context: *Context,
device: vk.Device,
swapchain: vk.SwapchainKHR,
images: []vk.Image,
image_views: []vk.ImageView,
image_layouts: []vk.ImageLayout,
info: SwapchainInfo,

const Self = @This();

pub fn deinit(self: Self) void {
    if (self.context.fns.vkDestroyImageView) |destroy_image_view| {
        for (self.image_views) |image_view| {
            destroy_image_view(self.device, image_view, null);
        }
    }
    self.context.allocator.free(self.image_views);
    self.context.allocator.free(self.image_layouts);
    self.context.allocator.free(self.images);
    if (self.context.fns.vkDestroySwapchainKHR) |destroy_swapchain| {
        destroy_swapchain(self.device, self.swapchain, null);
    }
}
