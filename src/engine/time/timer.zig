const Seconds = @import("types.zig").Seconds;

extern "kernel32" fn QueryPerformanceCounter(lpPerformanceCount: *i64) callconv(.winapi) i32;
extern "kernel32" fn QueryPerformanceFrequency(lpFrequency: *i64) callconv(.winapi) i32;

pub const Timer = struct {
    last: i64,
    frequency: i64,

    pub fn start() !Timer {
        var frequency: i64 = 0;
        var now: i64 = 0;
        if (QueryPerformanceFrequency(&frequency) == 0) return error.TimerUnavailable;
        if (QueryPerformanceCounter(&now) == 0) return error.TimerUnavailable;
        return .{ .last = now, .frequency = frequency };
    }

    pub fn lap(self: *Timer) Seconds {
        var now: i64 = 0;
        _ = QueryPerformanceCounter(&now);
        const dt = @as(Seconds, @floatFromInt(now - self.last)) / @as(Seconds, @floatFromInt(self.frequency));
        self.last = now;
        return dt;
    }
};
