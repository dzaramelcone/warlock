const std = @import("std");
const engine = @import("engine");
const texture_import = @import("images/texture_import.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next() orelse return error.CookUsageSourceAndOutputRequired;
    const source_path = args.next() orelse return error.CookUsageSourceRequired;
    const output_path = args.next() orelse return error.CookUsageOutputRequired;
    if (args.next() != null) return error.CookUsageSourceAndOutputRequired;

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const source = try std.Io.Dir.cwd().readFileAlloc(io, source_path, allocator, .limited(256 * 1024 * 1024));
    defer allocator.free(source);

    var prepared = try texture_import.prepareFromBytes(allocator, source, .{});
    defer prepared.deinit(allocator);

    const cooked = try engine.images.cooked.encode(allocator, prepared);
    defer allocator.free(cooked);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = cooked });
}
