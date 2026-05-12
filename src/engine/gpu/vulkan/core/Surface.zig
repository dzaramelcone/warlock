const vk = @import("../c.zig");

instance: vk.Instance,
surface: vk.SurfaceKHR,
destroy_surface: ?vk.PfnDestroySurfaceKHR,

pub fn deinit(self: @This()) void {
    if (self.destroy_surface) |destroy_surface| {
        destroy_surface(self.instance, self.surface, null);
    }
}
