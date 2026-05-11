const std = @import("std");

pub const AssetIo = struct {
    io: std.Io,
    root: []const u8 = ".",

    pub fn readFile(self: *const AssetIo, allocator: std.mem.Allocator, path: []const u8) ![]u8 {
        const resolved = try self.resolvePath(allocator, path);
        defer if (resolved.owned) |owned| allocator.free(owned);
        return std.Io.Dir.cwd().readFileAlloc(self.io, resolved.path, allocator, .limited(32 * 1024 * 1024));
    }

    pub fn readFileSentinel(self: *const AssetIo, allocator: std.mem.Allocator, path: []const u8) ![:0]u8 {
        const resolved = try self.resolvePath(allocator, path);
        defer if (resolved.owned) |owned| allocator.free(owned);
        return std.Io.Dir.cwd().readFileAllocOptions(self.io, resolved.path, allocator, .limited(32 * 1024 * 1024), .of(u8), 0);
    }

    pub fn openDir(self: *const AssetIo, allocator: std.mem.Allocator, path: []const u8, flags: std.Io.Dir.OpenOptions) !std.Io.Dir {
        const resolved = try self.resolvePath(allocator, path);
        defer if (resolved.owned) |owned| allocator.free(owned);
        return std.Io.Dir.cwd().openDir(self.io, resolved.path, flags);
    }

    pub fn statMtime(self: *const AssetIo, allocator: std.mem.Allocator, path: []const u8) !i96 {
        const resolved = try self.resolvePath(allocator, path);
        defer if (resolved.owned) |owned| allocator.free(owned);
        return (try std.Io.Dir.cwd().statFile(self.io, resolved.path, .{})).mtime.nanoseconds;
    }

    const ResolvedPath = struct {
        path: []const u8,
        owned: ?[]u8 = null,
    };

    fn resolvePath(self: *const AssetIo, allocator: std.mem.Allocator, path: []const u8) !ResolvedPath {
        if (self.root.len == 0 or std.mem.eql(u8, self.root, ".")) {
            return .{ .path = path };
        }
        const joined = try std.fs.path.join(allocator, &.{ self.root, path });
        return .{ .path = joined, .owned = joined };
    }
};
