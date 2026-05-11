const std = @import("std");
const build_options = @import("build_options");

pub const win32 = @import("win32.zig");

pub const Window = if (std.mem.eql(u8, build_options.platform_backend, "win32"))
    win32.Window
else
    @compileError("unsupported platform backend: " ++ build_options.platform_backend);

pub fn createWindow() !Window {
    if (comptime std.mem.eql(u8, build_options.platform_backend, "win32")) {
        return try win32.Window.create();
    }

    @compileError("unsupported platform backend: " ++ build_options.platform_backend);
}
