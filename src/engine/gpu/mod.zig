const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");

pub const api = @import("api.zig");
pub const fake = @import("fake.zig");
pub const metal = @import("metal/mod.zig");
pub const typed = @import("typed.zig");
pub const vulkan = @import("vulkan/mod.zig");

pub const Backend = if (builtin.is_test)
    fake
else if (std.mem.eql(u8, build_options.graphics_backend, "vulkan"))
    vulkan
else if (std.mem.eql(u8, build_options.graphics_backend, "metal"))
    metal
else
    @compileError("unsupported graphics backend: " ++ build_options.graphics_backend);

pub const Api = api.For(Backend);
pub const Graphics = Api.Graphics;

pub const allocBytes = typed.allocBytes;
pub const allocSlice = typed.allocSlice;
pub const allocValue = typed.allocValue;
pub const allocAndWriteBytes = typed.allocAndWriteBytes;
pub const allocAndWriteSlice = typed.allocAndWriteSlice;
pub const allocAndWriteValue = typed.allocAndWriteValue;
pub const writeBytes = typed.writeBytes;
pub const writeSlice = typed.writeSlice;
pub const writeValue = typed.writeValue;
pub const free = typed.free;
