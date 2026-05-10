const config = @import("../config.zig");
const game = @import("../game.zig");

pub const cpu = @import("cpu.zig");
pub const opencl = @import("opencl.zig");

pub const Frame = struct {
    pixels: *[config.WIDTH * config.HEIGHT]u32,
    width: u32 = config.WIDTH,
    height: u32 = config.HEIGHT,
};

pub const Backend = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        name: []const u8,
        deinit: *const fn (*anyopaque) void,
        render: *const fn (*anyopaque, *Frame, *const game.State) anyerror!void,
    };

    pub fn name(self: Backend) []const u8 {
        return self.vtable.name;
    }

    pub fn deinit(self: Backend) void {
        self.vtable.deinit(self.ptr);
    }

    pub fn render(self: Backend, frame: *Frame, state: *const game.State) !void {
        try self.vtable.render(self.ptr, frame, state);
    }
};
