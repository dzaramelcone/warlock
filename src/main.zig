const std = @import("std");
const backend = @import("backend/mod.zig");
const config = @import("config.zig");
const game = @import("game.zig");
const timer = @import("timer.zig");
const win32 = @import("win32.zig");

var pixels: [config.WIDTH * config.HEIGHT]u32 = undefined;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const window = try win32.Window.create();
    defer window.deinit();

    var cpu_renderer = backend.cpu.Renderer{};
    var opencl_renderer = backend.opencl.Renderer.init(allocator) catch |err| blk: {
        std.debug.print("OpenCL init failed: {}. Falling back to CPU rasterizer.\n", .{err});
        break :blk null;
    };
    defer if (opencl_renderer) |*renderer| renderer.deinit();

    var active_backend = if (opencl_renderer) |*renderer| renderer.backend() else cpu_renderer.backend();
    std.debug.print("Active backend: {s}\n", .{active_backend.name()});

    var frame = backend.Frame{ .pixels = &pixels };
    var state = game.State{};
    var frame_timer = try timer.Timer.start();
    var accumulator: f64 = 0;

    while (state.running) {
        state.running = win32.pumpMessages();

        const frame_dt = frame_timer.lap();
        accumulator += @min(frame_dt, 0.25);
        while (accumulator >= config.FIXED_DT) {
            game.update(&state, @floatCast(config.FIXED_DT));
            accumulator -= config.FIXED_DT;
        }

        active_backend.render(&frame, &state) catch |err| {
            std.debug.print("{s} backend failed: {}. Falling back to CPU rasterizer.\n", .{ active_backend.name(), err });
            if (opencl_renderer) |*renderer| {
                renderer.deinit();
                opencl_renderer = null;
            }
            active_backend = cpu_renderer.backend();
            try active_backend.render(&frame, &state);
            std.debug.print("Active backend: {s}\n", .{active_backend.name()});
        };

        window.present(&pixels);
    }
}
