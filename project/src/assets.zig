const std = @import("std");
const engine = @import("engine");

const asset_io = engine.asset.io;
const images = engine.images;
const mesh_mod = engine.asset.mesh;
const render_scene = engine.render.scene;

const OwnedMesh = mesh_mod.OwnedMesh;

pub const Assets = struct {
    allocator: std.mem.Allocator,
    meshes: []MeshAsset,
    materials: []MaterialAsset,

    pub fn load(allocator: std.mem.Allocator, io: *const asset_io.AssetIo) !Assets {
        const meshes = try loadMeshes(allocator, io, "assets/mesh");
        errdefer deinitMeshes(allocator, meshes);

        const materials = try loadMaterials(allocator, io, "assets/material");
        errdefer deinitMaterials(allocator, materials);

        return .{
            .allocator = allocator,
            .meshes = meshes,
            .materials = materials,
        };
    }

    pub fn deinit(self: *Assets) void {
        deinitMaterials(self.allocator, self.materials);
        deinitMeshes(self.allocator, self.meshes);
    }

    pub fn findMesh(self: Assets, id: []const u8) !*MeshAsset {
        for (self.meshes) |*asset| {
            if (std.mem.eql(u8, asset.id, id)) return asset;
        }
        return error.SceneUnknownMesh;
    }

    pub fn findMaterial(self: Assets, id: []const u8) !*MaterialAsset {
        for (self.materials) |*asset| {
            if (std.mem.eql(u8, asset.id, id)) return asset;
        }
        return error.SceneUnknownMaterial;
    }
};

pub const MeshAsset = struct {
    id: []const u8,
    mesh: OwnedMesh,
};

pub const MaterialAsset = struct {
    id: []const u8,
    material: render_scene.Material,
};

const MaterialDesc = struct {
    shader: ShaderDesc,
    base_color: u32,
    texture: ?TextureDesc = null,
};

const ShaderDesc = struct {
    vertex: []const u8,
    fragment: []const u8,
    id: u32 = 0,
};

const TextureDesc = struct {
    path: []const u8,
    sampler: TextureSamplerDesc = .{},
};

const TextureSamplerDesc = struct {
    mag_filter: images.sampler.Filter = .linear,
    min_filter: images.sampler.Filter = .linear,
    mipmap_mode: images.sampler.MipmapMode = .linear,
    address_mode: images.sampler.AddressMode = .repeat,
};

fn loadMeshes(allocator: std.mem.Allocator, io: *const asset_io.AssetIo, path: []const u8) ![]MeshAsset {
    var dir = try io.openDir(allocator, path, .{ .iterate = true });
    defer dir.close(io.io);

    var mesh_assets = std.ArrayList(MeshAsset).empty;
    defer mesh_assets.deinit(allocator);

    var iter = dir.iterate();
    while (try iter.next(io.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zon")) continue;

        const id = try allocator.dupe(u8, entry.name[0 .. entry.name.len - ".zon".len]);
        errdefer allocator.free(id);

        const mesh_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ path, entry.name });
        defer allocator.free(mesh_path);

        var mesh = try mesh_mod.load(allocator, io, mesh_path);
        errdefer mesh.deinit();

        try mesh_assets.append(allocator, .{
            .id = id,
            .mesh = mesh,
        });
    }

    if (mesh_assets.items.len == 0) return error.NoMeshesLoaded;
    return try mesh_assets.toOwnedSlice(allocator);
}

fn deinitMeshes(allocator: std.mem.Allocator, meshes: []MeshAsset) void {
    for (meshes) |*asset| {
        allocator.free(asset.id);
        asset.mesh.deinit();
    }
    allocator.free(meshes);
}

fn loadMaterials(allocator: std.mem.Allocator, io: *const asset_io.AssetIo, path: []const u8) ![]MaterialAsset {
    var dir = try io.openDir(allocator, path, .{ .iterate = true });
    defer dir.close(io.io);

    var materials = std.ArrayList(MaterialAsset).empty;
    defer materials.deinit(allocator);

    var iter = dir.iterate();
    while (try iter.next(io.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zon")) continue;

        const id = try allocator.dupe(u8, entry.name[0 .. entry.name.len - ".zon".len]);
        errdefer allocator.free(id);

        const material_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ path, entry.name });
        defer allocator.free(material_path);

        const material = try loadMaterial(allocator, io, material_path);
        errdefer deinitMaterial(allocator, material);

        try materials.append(allocator, .{
            .id = id,
            .material = material,
        });
    }

    if (materials.items.len == 0) return error.NoMaterialsLoaded;
    return try materials.toOwnedSlice(allocator);
}

fn deinitMaterials(allocator: std.mem.Allocator, materials: []MaterialAsset) void {
    for (materials) |*asset| {
        allocator.free(asset.id);
        deinitMaterial(allocator, asset.material);
    }
    allocator.free(materials);
}

fn deinitMaterial(allocator: std.mem.Allocator, material: render_scene.Material) void {
    if (material.texture) |texture| allocator.free(texture.path);
    allocator.free(material.shader.vertex_path);
    allocator.free(material.shader.fragment_path);
}

fn loadMaterial(allocator: std.mem.Allocator, io: *const asset_io.AssetIo, path: []const u8) !render_scene.Material {
    const source = try io.readFileSentinel(allocator, path);
    defer allocator.free(source);

    var diag: std.zon.parse.Diagnostics = .{};
    defer diag.deinit(allocator);

    const desc = std.zon.parse.fromSliceAlloc(MaterialDesc, allocator, source, &diag, .{}) catch |err| {
        if (err == error.ParseZon) std.debug.print("Failed to parse material ZON '{s}':\n{f}", .{ path, &diag });
        return err;
    };
    defer std.zon.parse.free(allocator, desc);

    const vertex_path = try allocator.dupe(u8, desc.shader.vertex);
    errdefer allocator.free(vertex_path);
    const fragment_path = try allocator.dupe(u8, desc.shader.fragment);
    errdefer allocator.free(fragment_path);
    const texture = if (desc.texture) |texture_desc| blk: {
        const texture_path = try allocator.dupe(u8, texture_desc.path);
        errdefer allocator.free(texture_path);
        break :blk images.texture.Ref{
            .path = texture_path,
            .sampler = .{
                .mag_filter = texture_desc.sampler.mag_filter,
                .min_filter = texture_desc.sampler.min_filter,
                .mipmap_mode = texture_desc.sampler.mipmap_mode,
                .address_mode = texture_desc.sampler.address_mode,
            },
        };
    } else null;
    errdefer if (texture) |owned_texture| allocator.free(owned_texture.path);

    return .{
        .shader = .{
            .vertex_path = vertex_path,
            .fragment_path = fragment_path,
            .id = desc.shader.id,
        },
        .base_color = desc.base_color,
        .texture = texture,
    };
}
