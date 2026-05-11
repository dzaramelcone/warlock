const std = @import("std");
const image = @import("image.zig");
const mip = @import("mip.zig");
const runtime_texture = @import("engine").images.texture;

pub fn prepareFromBytes(
    allocator: std.mem.Allocator,
    bytes: []const u8,
    sampler: runtime_texture.sampler.Sampler,
) !runtime_texture.Prepared {
    var decoded = try image.decodeRgba8(allocator, bytes);
    defer decoded.deinit(allocator);

    const chain = try mip.buildRgba8Chain(allocator, decoded.width, decoded.height, decoded.pixels, true);
    errdefer chain.deinit(allocator);

    return .{
        .width = decoded.width,
        .height = decoded.height,
        .pixels = chain.pixels,
        .levels = chain.levels,
        .sampler = sampler,
    };
}
