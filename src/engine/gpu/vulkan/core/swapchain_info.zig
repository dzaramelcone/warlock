const vk = @import("../c.zig");

pub const Info = struct {
    format: u32,
    color_space: u32,
    present_mode: u32,
    extent: vk.Extent2D,
    image_count: u32,
};
