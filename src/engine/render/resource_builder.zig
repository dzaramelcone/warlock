const std = @import("std");
const asset_io = @import("../asset/io.zig");
const config = @import("../config.zig");
const images = @import("../images/mod.zig");
const gpu_scene = @import("gpu_scene.zig");
const resources = @import("resources.zig");
const scene_mod = @import("scene.zig");
const shaders = @import("shaders.zig");

pub const SceneInputs = struct {
    packet: gpu_scene.Packet,
    shaders: shaders.ShaderSet,
    texture: images.texture.Prepared,

    pub fn deinit(self: *SceneInputs, allocator: std.mem.Allocator) void {
        self.texture.deinit(allocator);
        self.shaders.deinit();
        self.packet.deinit(allocator);
    }

    pub fn textureBytes(self: *const SceneInputs) resources.TextureBytes {
        return .{
            .width = self.texture.width,
            .height = self.texture.height,
            .rgba = self.texture.pixels,
            .levels = self.texture.levels,
            .mag_filter = filter(self.texture.sampler.mag_filter),
            .min_filter = filter(self.texture.sampler.min_filter),
            .mipmap_mode = mipmapMode(self.texture.sampler.mipmap_mode),
            .address_mode = addressMode(self.texture.sampler.address_mode),
        };
    }
};

pub fn buildSceneInputs(
    allocator: std.mem.Allocator,
    assets: *const asset_io.AssetIo,
    scene: *const scene_mod.Scene,
) !SceneInputs {
    var packet = try gpu_scene.buildPacket(allocator, scene, config.WIDTH, config.HEIGHT);
    errdefer packet.deinit(allocator);

    var shader_set = try shaders.ShaderSet.load(allocator, assets, scene, &packet);
    errdefer shader_set.deinit();

    var texture = try loadSceneTexture(allocator, assets, scene);
    errdefer texture.deinit(allocator);

    return .{
        .packet = packet,
        .shaders = shader_set,
        .texture = texture,
    };
}

fn loadSceneTexture(
    allocator: std.mem.Allocator,
    assets: *const asset_io.AssetIo,
    scene: *const scene_mod.Scene,
) !images.texture.Prepared {
    for (scene.objects) |object| {
        if (object.material.texture) |texture_ref| {
            const source = try assets.readFile(allocator, texture_ref.path);
            defer allocator.free(source);
            return try images.cooked.decode(allocator, source, texture_ref.sampler);
        }
    }
    return error.SceneMissingTexture;
}

fn filter(value: images.sampler.Filter) resources.TextureBytes.Filter {
    return switch (value) {
        .nearest => .nearest,
        .linear => .linear,
    };
}

fn mipmapMode(value: images.sampler.MipmapMode) resources.TextureBytes.MipmapMode {
    return switch (value) {
        .nearest => .nearest,
        .linear => .linear,
    };
}

fn addressMode(value: images.sampler.AddressMode) resources.TextureBytes.AddressMode {
    return switch (value) {
        .repeat => .repeat,
        .clamp_to_edge => .clamp_to_edge,
    };
}
