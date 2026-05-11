const Seconds = @import("types.zig").Seconds;

pub const FixedStep = struct {
    accumulator: Seconds = 0,
    step_seconds: Seconds,
    max_frame_seconds: Seconds = 0.25,

    pub fn init(step_seconds: Seconds) FixedStep {
        return .{ .step_seconds = step_seconds };
    }

    pub fn beginFrame(self: *FixedStep, frame_seconds: Seconds) void {
        self.accumulator += @min(frame_seconds, self.max_frame_seconds);
    }

    pub fn consumeUpdate(self: *FixedStep) bool {
        if (self.accumulator < self.step_seconds) return false;
        self.accumulator -= self.step_seconds;
        return true;
    }

    pub fn step(self: FixedStep) Seconds {
        return self.step_seconds;
    }
};
