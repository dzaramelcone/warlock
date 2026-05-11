const std = @import("std");
pub const sampler = @import("sampler.zig");

pub const Ref = struct {
    path: []const u8,
    sampler: sampler.Sampler = .{},
};

pub const MipLevel = struct {
    width: u32,
    height: u32,
    offset: usize,
    len: usize,
};

pub const MipChain = struct {
    pixels: []u8,
    levels: []MipLevel,

    pub fn deinit(self: MipChain, allocator: std.mem.Allocator) void {
        allocator.free(self.levels);
        allocator.free(self.pixels);
    }
};

pub const Prepared = struct {
    width: u32,
    height: u32,
    pixels: []u8,
    levels: []MipLevel,
    sampler: sampler.Sampler,

    pub fn deinit(self: Prepared, allocator: std.mem.Allocator) void {
        allocator.free(self.levels);
        allocator.free(self.pixels);
    }
};
