const std = @import("std");
const build_options = @import("build_options");

pub const api = @import("api.zig");
pub const scene_data = @import("scene_data.zig");
pub const vulkan = @import("vulkan/mod.zig");

pub const Backend = if (std.mem.eql(u8, build_options.graphics_backend, "vulkan"))
    vulkan
else
    @compileError("unsupported graphics backend: " ++ build_options.graphics_backend);

pub const Api = api.Api(Backend);
pub const Graphics = Api.Graphics;
pub const SceneResources = Api.SceneResources;
pub const Commands = Api.Commands;
