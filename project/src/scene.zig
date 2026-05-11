const std = @import("std");
const engine = @import("engine");
const game = @import("game.zig");
const project_assets = @import("assets.zig");
const asset_io = engine.asset.io;
const math = engine.math;
const render_scene = engine.render.scene;

const Quat = math.Quat;
const Transform = math.Transform;
const Vec3 = math.Vec3;

const SceneDesc = struct {
    entities: []const EntityDesc,
};

const EntityDesc = struct {
    name: []const u8,
    components: []const ComponentDesc,
};

const ComponentDesc = union(enum) {
    transform: TransformDesc,
    camera: CameraDesc,
    mesh: MeshDesc,
    material: MaterialComponentDesc,
};

const TransformDesc = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    rotation: [4]f32 = .{ 0, 0, 0, 1 },
    scale: [3]f32 = .{ 1, 1, 1 },
};

const CameraDesc = struct {
    fov_y_degrees: f32,
    near: f32,
    far: f32,
};

const MeshDesc = struct {
    id: []const u8,
};

const MaterialComponentDesc = struct {
    id: []const u8,
};

const Entity = struct {
    transform: Transform = .{},
    camera: ?CameraDesc = null,
    mesh: ?[]const u8 = null,
    material: ?[]const u8 = null,
};

pub const Scene = struct {
    allocator: std.mem.Allocator,
    assets: project_assets.Assets,
    entities: []Entity,
    objects: []render_scene.Object,
    render: render_scene.Scene,

    pub fn init(allocator: std.mem.Allocator, io: *const asset_io.AssetIo) !Scene {
        var assets = try project_assets.Assets.load(allocator, io);
        errdefer assets.deinit();

        const desc = try loadSceneDesc(allocator, io, "assets/scene/default.zon");
        defer std.zon.parse.free(allocator, desc);

        const entities = try allocator.alloc(Entity, desc.entities.len);
        errdefer allocator.free(entities);

        var object_count: usize = 0;
        var camera: ?render_scene.Camera = null;

        for (desc.entities, 0..) |entity_desc, i| {
            entities[i] = entityFromDesc(entity_desc);
            if (entities[i].mesh != null) object_count += 1;
            if (entities[i].camera) |camera_desc| {
                camera = cameraFromEntity(entities[i], camera_desc);
            }
        }

        const objects = try allocator.alloc(render_scene.Object, object_count);
        errdefer allocator.free(objects);

        var object_index: usize = 0;
        for (entities) |entity| {
            if (entity.mesh) |mesh_id| {
                objects[object_index] = .{
                    .mesh = (try assets.findMesh(mesh_id)).mesh.mesh(),
                    .material = (try assets.findMaterial(entity.material orelse "default_surface")).material,
                    .transform = entity.transform,
                };
                object_index += 1;
            }
        }

        return .{
            .allocator = allocator,
            .assets = assets,
            .entities = entities,
            .objects = objects,
            .render = .{
                .camera = camera orelse return error.SceneMissingCamera,
                .objects = objects,
            },
        };
    }

    pub fn deinit(self: *Scene) void {
        self.allocator.free(self.objects);
        self.allocator.free(self.entities);
        self.assets.deinit();
    }

    pub fn syncFromGame(self: *Scene, state: *const game.State) void {
        const t: f32 = @floatCast(state.t);
        const cube_angle: f32 = @floatCast(state.cube_angle);
        const pyramid_angle: f32 = @floatCast(state.pyramid_angle);

        self.render.time = t;
        self.render.camera = orbitCamera(self.entities[0], t);

        self.objects[0].transform = self.entities[1].transform;
        self.objects[0].transform.position = Vec3.add(
            self.entities[1].transform.position,
            .{
                .x = @sin(t * 0.9) * 0.9,
                .y = @sin(t * 1.7) * 0.35,
                .z = @cos(t * 0.9) * 1.4,
            },
        );
        self.objects[0].transform.rotation = Quat.mul(
            Quat.axisAngle(Vec3.up, cube_angle),
            Quat.axisAngle(.{ .x = 1, .y = 0, .z = 0 }, cube_angle * 0.6),
        );

        self.objects[1].transform = self.entities[2].transform;
        self.objects[1].transform.position = Vec3.add(
            self.entities[2].transform.position,
            .{
                .x = @cos(t * 0.7) * 1.1,
                .y = @sin(t * 1.1 + 1.2) * 0.25,
                .z = @sin(t * 0.7) * 1.8,
            },
        );
        self.objects[1].transform.rotation = Quat.mul(
            Quat.axisAngle(Vec3.up, pyramid_angle),
            Quat.axisAngle(.{ .x = 1, .y = 0, .z = 0 }, 0.25),
        );
    }
};

fn orbitCamera(entity: Entity, t: f32) render_scene.Camera {
    const desc = entity.camera orelse unreachable;
    const target: Vec3 = .{ .x = 0.0, .y = 0.15, .z = -0.45 };
    const horizontal_radius: f32 = 7.25;
    const down_angle = math.radians(35.0);
    const height = @tan(down_angle) * horizontal_radius;
    const angle = t * 0.28 + std.math.pi;

    return .{
        .eye = .{
            .x = target.x + @sin(angle) * horizontal_radius,
            .y = target.y + height,
            .z = target.z + @cos(angle) * horizontal_radius,
        },
        .target = target,
        .up = Vec3.up,
        .fov_y_radians = math.radians(desc.fov_y_degrees),
        .near = desc.near,
        .far = desc.far,
    };
}

fn loadSceneDesc(allocator: std.mem.Allocator, assets: *const asset_io.AssetIo, path: []const u8) !SceneDesc {
    const source = try assets.readFileSentinel(allocator, path);
    defer allocator.free(source);

    var diag: std.zon.parse.Diagnostics = .{};
    defer diag.deinit(allocator);

    return std.zon.parse.fromSliceAlloc(SceneDesc, allocator, source, &diag, .{}) catch |err| {
        if (err == error.ParseZon) std.debug.print("Failed to parse scene ZON '{s}':\n{f}", .{ path, &diag });
        return err;
    };
}

fn entityFromDesc(desc: EntityDesc) Entity {
    var entity = Entity{};
    for (desc.components) |component| {
        switch (component) {
            .transform => |transform| entity.transform = transformFromDesc(transform),
            .camera => |camera| entity.camera = camera,
            .mesh => |mesh| entity.mesh = mesh.id,
            .material => |material| entity.material = material.id,
        }
    }
    return entity;
}

fn cameraFromEntity(entity: Entity, camera: CameraDesc) render_scene.Camera {
    const forward = Quat.rotateVec3(entity.transform.rotation, Vec3.forward);
    return .{
        .eye = entity.transform.position,
        .target = Vec3.add(entity.transform.position, forward),
        .up = Quat.rotateVec3(entity.transform.rotation, Vec3.up),
        .fov_y_radians = math.radians(camera.fov_y_degrees),
        .near = camera.near,
        .far = camera.far,
    };
}

fn transformFromDesc(desc: TransformDesc) Transform {
    return .{
        .position = vec3FromArray(desc.position),
        .rotation = quatFromArray(desc.rotation),
        .scale = vec3FromArray(desc.scale),
    };
}

fn vec3FromArray(values: [3]f32) Vec3 {
    return .{ .x = values[0], .y = values[1], .z = values[2] };
}

fn quatFromArray(values: [4]f32) Quat {
    return .{ .x = values[0], .y = values[1], .z = values[2], .w = values[3] };
}

test "load default project scene" {
    var threaded = std.Io.Threaded.init(std.testing.allocator, .{});
    defer threaded.deinit();
    const assets = asset_io.AssetIo{ .io = threaded.io(), .root = "project" };

    var scene = try Scene.init(std.testing.allocator, &assets);
    defer scene.deinit();

    try std.testing.expectEqual(@as(usize, 9), scene.render.objects.len);
    try std.testing.expectEqual(@as(usize, 10), scene.entities.len);
}

test "project camera orbits scene target from above" {
    var threaded = std.Io.Threaded.init(std.testing.allocator, .{});
    defer threaded.deinit();
    const assets = asset_io.AssetIo{ .io = threaded.io(), .root = "project" };

    var scene = try Scene.init(std.testing.allocator, &assets);
    defer scene.deinit();

    var state = game.State{ .t = 0 };
    scene.syncFromGame(&state);
    const first = scene.render.camera;

    state.t = 3.0;
    scene.syncFromGame(&state);
    const second = scene.render.camera;

    try std.testing.expect(first.eye.y > first.target.y);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), first.target.x, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.15), first.target.y, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, -0.45), first.target.z, 0.001);
    try std.testing.expect(@abs(first.eye.x - second.eye.x) > 0.5 or @abs(first.eye.z - second.eye.z) > 0.5);

    const horizontal = @sqrt(
        std.math.pow(f32, first.eye.x - first.target.x, 2) +
            std.math.pow(f32, first.eye.z - first.target.z, 2),
    );
    const down_angle = std.math.atan2(first.eye.y - first.target.y, horizontal);
    try std.testing.expectApproxEqAbs(math.radians(35.0), down_angle, 0.001);
}
