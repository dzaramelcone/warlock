const std = @import("std");
const asset_io = @import("io.zig");
const math = @import("../math/mod.zig");

const Vec3 = math.Vec3;

pub const Vertex = struct {
    pos: Vec3,
    uv: [2]f32,
    color: u32,
};

pub const Triangle = struct {
    a: usize,
    b: usize,
    c: usize,
};

pub const Mesh = struct {
    vertices: []const Vertex,
    triangles: []const Triangle,
};

pub const OwnedMesh = struct {
    allocator: std.mem.Allocator,
    vertices: []Vertex,
    triangles: []Triangle,

    pub fn mesh(self: *const OwnedMesh) Mesh {
        return .{ .vertices = self.vertices, .triangles = self.triangles };
    }

    pub fn deinit(self: *OwnedMesh) void {
        self.allocator.free(self.vertices);
        self.allocator.free(self.triangles);
    }
};

const MeshDesc = struct {
    vertices: []const VertexDesc,
    triangles: []const [3]usize,
};

const VertexDesc = struct {
    pos: [3]f32,
    uv: [2]f32 = .{ 0, 0 },
    color: u32,
};

pub fn load(allocator: std.mem.Allocator, assets: *const asset_io.AssetIo, path: []const u8) !OwnedMesh {
    const source = try assets.readFileSentinel(allocator, path);
    defer allocator.free(source);

    var diag: std.zon.parse.Diagnostics = .{};
    defer diag.deinit(allocator);

    const desc = std.zon.parse.fromSliceAlloc(MeshDesc, allocator, source, &diag, .{}) catch |err| {
        if (err == error.ParseZon) std.debug.print("Failed to parse mesh ZON '{s}':\n{f}", .{ path, &diag });
        return err;
    };
    defer std.zon.parse.free(allocator, desc);

    var vertices = try allocator.alloc(Vertex, desc.vertices.len);
    errdefer allocator.free(vertices);
    var triangles = try allocator.alloc(Triangle, desc.triangles.len);
    errdefer allocator.free(triangles);

    for (desc.vertices, 0..) |vertex, i| {
        vertices[i] = .{
            .pos = .{ .x = vertex.pos[0], .y = vertex.pos[1], .z = vertex.pos[2] },
            .uv = vertex.uv,
            .color = vertex.color,
        };
    }

    for (desc.triangles, 0..) |tri, i| {
        if (tri[0] >= vertices.len or tri[1] >= vertices.len or tri[2] >= vertices.len) return error.MeshIndexOutOfBounds;
        triangles[i] = .{ .a = tri[0], .b = tri[1], .c = tri[2] };
    }

    return .{
        .allocator = allocator,
        .vertices = vertices,
        .triangles = triangles,
    };
}

test "load cube mesh asset" {
    var threaded = std.Io.Threaded.init(std.testing.allocator, .{});
    defer threaded.deinit();
    const assets = asset_io.AssetIo{ .io = threaded.io(), .root = "project" };

    var cube = try load(std.testing.allocator, &assets, "assets/mesh/cube.zon");
    defer cube.deinit();

    try std.testing.expectEqual(@as(usize, 24), cube.vertices.len);
    try std.testing.expectEqual(@as(usize, 12), cube.triangles.len);
}

test "cube mesh triangle indices form six axis-aligned faces" {
    var threaded = std.Io.Threaded.init(std.testing.allocator, .{});
    defer threaded.deinit();
    const assets = asset_io.AssetIo{ .io = threaded.io(), .root = "project" };

    var cube = try load(std.testing.allocator, &assets, "assets/mesh/cube.zon");
    defer cube.deinit();

    var negative_x: usize = 0;
    var positive_x: usize = 0;
    var negative_y: usize = 0;
    var positive_y: usize = 0;
    var negative_z: usize = 0;
    var positive_z: usize = 0;

    for (cube.triangles) |triangle| {
        const a = cube.vertices[triangle.a].pos;
        const b = cube.vertices[triangle.b].pos;
        const c = cube.vertices[triangle.c].pos;
        const ab = b.sub(a);
        const ac = c.sub(a);
        const normal = Vec3.cross(ab, ac);

        try std.testing.expect(normal.length() > 0.0);
        const ax = @abs(normal.x);
        const ay = @abs(normal.y);
        const az = @abs(normal.z);
        if (ax > ay and ax > az) {
            if (normal.x < 0) negative_x += 1 else positive_x += 1;
            try std.testing.expectEqual(@as(f32, 0), normal.y);
            try std.testing.expectEqual(@as(f32, 0), normal.z);
        } else if (ay > ax and ay > az) {
            if (normal.y < 0) negative_y += 1 else positive_y += 1;
            try std.testing.expectEqual(@as(f32, 0), normal.x);
            try std.testing.expectEqual(@as(f32, 0), normal.z);
        } else {
            if (normal.z < 0) negative_z += 1 else positive_z += 1;
            try std.testing.expectEqual(@as(f32, 0), normal.x);
            try std.testing.expectEqual(@as(f32, 0), normal.y);
        }
    }

    try std.testing.expectEqual(@as(usize, 2), negative_x);
    try std.testing.expectEqual(@as(usize, 2), positive_x);
    try std.testing.expectEqual(@as(usize, 2), negative_y);
    try std.testing.expectEqual(@as(usize, 2), positive_y);
    try std.testing.expectEqual(@as(usize, 2), negative_z);
    try std.testing.expectEqual(@as(usize, 2), positive_z);
}

test "load pyramid mesh asset" {
    var threaded = std.Io.Threaded.init(std.testing.allocator, .{});
    defer threaded.deinit();
    const assets = asset_io.AssetIo{ .io = threaded.io(), .root = "project" };

    var pyramid = try load(std.testing.allocator, &assets, "assets/mesh/pyramid.zon");
    defer pyramid.deinit();

    try std.testing.expectEqual(@as(usize, 16), pyramid.vertices.len);
    try std.testing.expectEqual(@as(usize, 6), pyramid.triangles.len);
}
