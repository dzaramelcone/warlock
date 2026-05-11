pub const asset = struct {
    pub const io = @import("asset/io.zig");
    pub const mesh = @import("asset/mesh.zig");
};

pub const images = @import("images/mod.zig");

pub const gpu = @import("gpu/mod.zig");

pub const platform = struct {
    pub const timer = @import("platform/timer.zig");
    pub const win32 = @import("platform/win32.zig");
};

pub const config = @import("config.zig");
pub const math = @import("math/mod.zig");

pub const render = struct {
    pub const gpu_scene = @import("render/gpu_scene.zig");
    pub const resource_builder = @import("render/resource_builder.zig");
    pub const resources = @import("render/resources.zig");
    pub const renderer = @import("render/renderer.zig");
    pub const scene = @import("render/scene.zig");
    pub const shaders = @import("render/shaders.zig");
};
