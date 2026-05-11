const std = @import("std");
const asset_io = @import("io.zig");

path: []const u8,
last_mtime: i96,
assets: *const asset_io.AssetIo,
allocator: std.mem.Allocator,
debounce_seconds: f64,
dirty: bool = false,
dirty_elapsed: f64 = 0,

pub fn init(
    allocator: std.mem.Allocator,
    source_assets: *const asset_io.AssetIo,
    watch_path: []const u8,
    debounce_seconds: f64,
) !@This() {
    return .{
        .path = watch_path,
        .last_mtime = try source_assets.statMtime(allocator, watch_path),
        .assets = source_assets,
        .allocator = allocator,
        .debounce_seconds = debounce_seconds,
    };
}

pub fn update(self: *@This(), dt: f64) !bool {
    const current_mtime = try self.assets.statMtime(self.allocator, self.path);
    if (current_mtime != self.last_mtime) {
        self.last_mtime = current_mtime;
        self.dirty = true;
        self.dirty_elapsed = 0;
        return false;
    }

    if (!self.dirty) return false;
    self.dirty_elapsed += dt;
    if (self.dirty_elapsed < self.debounce_seconds) return false;

    self.dirty = false;
    return true;
}
