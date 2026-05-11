const std = @import("std");
const runtime_texture = @import("engine").images.texture;

pub fn buildRgba8Chain(
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    pixels: []const u8,
    generate_mips: bool,
) !runtime_texture.MipChain {
    var levels = std.ArrayList(runtime_texture.MipLevel).empty;
    defer levels.deinit(allocator);
    var data = std.ArrayList(u8).empty;
    defer data.deinit(allocator);

    try appendLevel(allocator, &levels, &data, width, height, pixels);
    if (generate_mips) {
        var current_width = width;
        var current_height = height;
        var current_pixels = try allocator.dupe(u8, pixels);
        defer allocator.free(current_pixels);

        while (current_width > 1 or current_height > 1) {
            const next_width = @max(@as(u32, 1), current_width / 2);
            const next_height = @max(@as(u32, 1), current_height / 2);
            const next_pixels = try downsampleRgba2x2(allocator, current_pixels, current_width, current_height, next_width, next_height);

            try appendLevel(allocator, &levels, &data, next_width, next_height, next_pixels);

            allocator.free(current_pixels);
            current_pixels = next_pixels;
            current_width = next_width;
            current_height = next_height;
        }
    }

    return .{
        .pixels = try data.toOwnedSlice(allocator),
        .levels = try levels.toOwnedSlice(allocator),
    };
}

fn appendLevel(
    allocator: std.mem.Allocator,
    levels: *std.ArrayList(runtime_texture.MipLevel),
    data: *std.ArrayList(u8),
    width: u32,
    height: u32,
    rgba: []const u8,
) !void {
    const expected_len = @as(usize, width) * @as(usize, height) * 4;
    if (rgba.len != expected_len) return error.TextureMipInvalidByteLength;
    const offset = data.items.len;
    try data.appendSlice(allocator, rgba);
    try levels.append(allocator, .{ .width = width, .height = height, .offset = offset, .len = expected_len });
}

fn downsampleRgba2x2(
    allocator: std.mem.Allocator,
    src: []const u8,
    src_width: u32,
    src_height: u32,
    dst_width: u32,
    dst_height: u32,
) ![]u8 {
    const dst = try allocator.alloc(u8, @as(usize, dst_width) * @as(usize, dst_height) * 4);
    errdefer allocator.free(dst);

    for (0..dst_height) |dy| {
        for (0..dst_width) |dx| {
            var sum: [4]u32 = .{ 0, 0, 0, 0 };
            var count: u32 = 0;
            for (0..2) |oy| {
                for (0..2) |ox| {
                    const sx = @min(src_width - 1, @as(u32, @intCast(dx * 2 + ox)));
                    const sy = @min(src_height - 1, @as(u32, @intCast(dy * 2 + oy)));
                    const src_index = (@as(usize, sy) * src_width + sx) * 4;
                    sum[0] += src[src_index + 0];
                    sum[1] += src[src_index + 1];
                    sum[2] += src[src_index + 2];
                    sum[3] += src[src_index + 3];
                    count += 1;
                }
            }

            const dst_index = (@as(usize, dy) * dst_width + dx) * 4;
            dst[dst_index + 0] = @intCast(sum[0] / count);
            dst[dst_index + 1] = @intCast(sum[1] / count);
            dst[dst_index + 2] = @intCast(sum[2] / count);
            dst[dst_index + 3] = @intCast(sum[3] / count);
        }
    }

    return dst;
}
