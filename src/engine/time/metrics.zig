const std = @import("std");
const Seconds = @import("types.zig").Seconds;

pub const FrameMetrics = struct {
    elapsed_seconds: Seconds = 0,
    frames: u32 = 0,
    updates: u32 = 0,

    pub fn recordUpdate(self: *FrameMetrics) void {
        self.updates += 1;
    }

    pub fn recordFrame(self: *FrameMetrics, dt: Seconds) void {
        self.elapsed_seconds += dt;
        self.frames += 1;
    }

    pub fn reportIfDue(self: *FrameMetrics) void {
        if (self.elapsed_seconds < 1.0) return;

        const fps = @as(Seconds, @floatFromInt(self.frames)) / self.elapsed_seconds;
        const update_hz = @as(Seconds, @floatFromInt(self.updates)) / self.elapsed_seconds;
        const frame_ms = (self.elapsed_seconds / @as(Seconds, @floatFromInt(self.frames))) * 1000.0;
        std.debug.print("fps {d:.1}, updates {d:.1}/s, frame {d:.2} ms\n", .{ fps, update_hz, frame_ms });
        self.* = .{};
    }
};
