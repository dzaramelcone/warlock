const std = @import("std");
const engine = @import("engine");
const project_scene = @import("scene.zig");

const asset_io = engine.asset.io;
const gpu = engine.gpu;
const resource_builder = engine.render.resource_builder;

scene: project_scene.Scene,
resources: gpu.SceneResources,

pub fn load(
    allocator: std.mem.Allocator,
    assets: *const asset_io.AssetIo,
    graphics: *gpu.Graphics,
) !@This() {
    var scene = try project_scene.Scene.init(allocator, assets);
    errdefer scene.deinit();

    var inputs = try resource_builder.buildSceneInputs(allocator, assets, &scene.render);
    defer inputs.deinit(allocator);

    const resources = try graphics.createSceneResources(inputs.packet, inputs.shaders.shaders, inputs.textureBytes());
    errdefer {
        var cleanup = resources;
        cleanup.deinit();
    }

    return .{
        .scene = scene,
        .resources = resources,
    };
}

pub fn deinit(self: *@This()) void {
    self.resources.deinit();
    self.scene.deinit();
}
