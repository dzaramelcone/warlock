const std = @import("std");
const asset_io = @import("../asset/io.zig");
const gpu_scene = @import("gpu_scene.zig");
const resources = @import("resources.zig");
const scene_mod = @import("scene.zig");

pub const ShaderSet = struct {
    allocator: std.mem.Allocator,
    shaders: []resources.ShaderBytes,

    pub fn load(
        allocator: std.mem.Allocator,
        assets: *const asset_io.AssetIo,
        scene: *const scene_mod.Scene,
        packet: *gpu_scene.Packet,
    ) !ShaderSet {
        if (scene.objects.len == 0) return error.SceneMissingDrawableObject;

        var shaders = std.ArrayList(resources.ShaderBytes).empty;
        var keys = std.ArrayList(ShaderKey).empty;
        defer keys.deinit(allocator);
        errdefer {
            for (shaders.items) |shader| {
                allocator.free(shader.vertex);
                allocator.free(shader.fragment);
            }
            shaders.deinit(allocator);
        }

        for (scene.objects, 0..) |object, draw_index| {
            const pipeline_index = try findOrLoadShader(allocator, assets, &shaders, &keys, object.material.shader);
            packet.draws[draw_index].material_index = @intCast(pipeline_index);
        }

        return .{
            .allocator = allocator,
            .shaders = try shaders.toOwnedSlice(allocator),
        };
    }

    pub fn deinit(self: *ShaderSet) void {
        for (self.shaders) |shader| {
            self.allocator.free(shader.vertex);
            self.allocator.free(shader.fragment);
        }
        self.allocator.free(self.shaders);
    }

    const ShaderKey = struct {
        vertex_path: []const u8,
        fragment_path: []const u8,
    };

    fn findOrLoadShader(
        allocator: std.mem.Allocator,
        assets: *const asset_io.AssetIo,
        shaders: *std.ArrayList(resources.ShaderBytes),
        keys: *std.ArrayList(ShaderKey),
        shader: scene_mod.Shader,
    ) !usize {
        for (keys.items, 0..) |key, i| {
            if (std.mem.eql(u8, key.vertex_path, shader.vertex_path) and std.mem.eql(u8, key.fragment_path, shader.fragment_path)) {
                return i;
            }
        }

        const vertex = try assets.readFile(allocator, shader.vertex_path);
        errdefer allocator.free(vertex);
        const fragment = try assets.readFile(allocator, shader.fragment_path);
        errdefer allocator.free(fragment);

        try shaders.append(allocator, .{
            .vertex = vertex,
            .fragment = fragment,
        });
        errdefer _ = shaders.pop();
        try keys.append(allocator, .{
            .vertex_path = shader.vertex_path,
            .fragment_path = shader.fragment_path,
        });
        return shaders.items.len - 1;
    }
};

