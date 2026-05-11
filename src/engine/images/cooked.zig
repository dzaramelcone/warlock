const std = @import("std");
const texture = @import("texture.zig");

const magic = [_]u8{ 'W', 'T', 'X', '1' };

pub fn decode(allocator: std.mem.Allocator, bytes: []const u8, sampler: texture.sampler.Sampler) !texture.Prepared {
    var offset: usize = 0;
    if (bytes.len < magic.len or !std.mem.eql(u8, bytes[0..magic.len], &magic)) return error.CookedTextureInvalidMagic;
    offset += magic.len;

    const width = try readU32(bytes, &offset);
    const height = try readU32(bytes, &offset);
    const level_count = try readU32(bytes, &offset);
    if (width == 0 or height == 0 or level_count == 0) return error.CookedTextureInvalidHeader;

    const levels = try allocator.alloc(texture.MipLevel, level_count);
    errdefer allocator.free(levels);
    var pixel_len: usize = 0;
    for (levels) |*level| {
        level.* = .{
            .width = try readU32(bytes, &offset),
            .height = try readU32(bytes, &offset),
            .offset = pixel_len,
            .len = @intCast(try readU32(bytes, &offset)),
        };
        if (level.width == 0 or level.height == 0) return error.CookedTextureInvalidMip;
        if (level.len != @as(usize, level.width) * @as(usize, level.height) * 4) return error.CookedTextureInvalidMip;
        pixel_len += level.len;
    }
    if (offset > bytes.len or pixel_len > bytes.len - offset) return error.CookedTextureTruncatedPixels;

    const pixels = try allocator.dupe(u8, bytes[offset..][0..pixel_len]);
    errdefer allocator.free(pixels);

    return .{
        .width = width,
        .height = height,
        .pixels = pixels,
        .levels = levels,
        .sampler = sampler,
    };
}

pub fn encode(allocator: std.mem.Allocator, prepared: texture.Prepared) ![]u8 {
    var out = std.ArrayList(u8).empty;
    errdefer out.deinit(allocator);

    try out.appendSlice(allocator, &magic);
    try appendU32(allocator, &out, prepared.width);
    try appendU32(allocator, &out, prepared.height);
    try appendU32(allocator, &out, @intCast(prepared.levels.len));
    for (prepared.levels) |level| {
        try appendU32(allocator, &out, level.width);
        try appendU32(allocator, &out, level.height);
        try appendU32(allocator, &out, @intCast(level.len));
    }
    try out.appendSlice(allocator, prepared.pixels);
    return try out.toOwnedSlice(allocator);
}

fn readU32(bytes: []const u8, offset: *usize) !u32 {
    if (offset.* + 4 > bytes.len) return error.CookedTextureTruncatedHeader;
    const value = std.mem.readInt(u32, bytes[offset.*..][0..4], .little);
    offset.* += 4;
    return value;
}

fn appendU32(allocator: std.mem.Allocator, out: *std.ArrayList(u8), value: u32) !void {
    var encoded: [4]u8 = undefined;
    std.mem.writeInt(u32, &encoded, value, .little);
    try out.appendSlice(allocator, &encoded);
}
