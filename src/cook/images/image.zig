const std = @import("std");
const zigimg = @import("zigimg");

pub const Image = struct {
    width: u32,
    height: u32,
    pixels: []u8,

    pub fn deinit(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }
};

pub fn decodeRgba8(allocator: std.mem.Allocator, bytes: []const u8) !Image {
    var source = try zigimg.Image.fromMemory(allocator, bytes);
    defer source.deinit(allocator);

    try source.convert(allocator, .rgba32);

    const width = std.math.cast(u32, source.width) orelse return error.ImageTooWide;
    const height = std.math.cast(u32, source.height) orelse return error.ImageTooTall;
    const pixels = try allocator.dupe(u8, source.rawBytes());
    errdefer allocator.free(pixels);

    return .{
        .width = width,
        .height = height,
        .pixels = pixels,
    };
}
