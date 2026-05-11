const std = @import("std");
const config = @import("../config.zig");
const scene_data = @import("../gpu/scene_data.zig");
const math = @import("../math/mod.zig");
const mesh_mod = @import("../asset/mesh.zig");
const scene_mod = @import("scene.zig");

const Mat4 = math.Mat4;
const color = math.color;
pub const Vertex = scene_data.Vertex;
pub const Draw = scene_data.Draw;
pub const VertexDrawData = scene_data.VertexDrawData;
pub const PixelDrawData = scene_data.PixelDrawData;
pub const Packet = scene_data.Packet;

pub fn buildPacket(allocator: std.mem.Allocator, scene: *const scene_mod.Scene, width: u32, height: u32) !Packet {
    var vertex_count: usize = 0;
    var index_count: usize = 0;
    for (scene.objects) |object| {
        const object_index_count = object.mesh.triangles.len * 3;
        vertex_count += object_index_count;
        index_count += object_index_count;
    }
    const vertices = try allocator.alloc(Vertex, vertex_count);
    errdefer allocator.free(vertices);
    const indices = try allocator.alloc(u32, index_count);
    errdefer allocator.free(indices);
    const draws = try allocator.alloc(Draw, scene.objects.len);
    errdefer allocator.free(draws);
    const vertex_draws = try allocator.alloc(VertexDrawData, scene.objects.len);
    errdefer allocator.free(vertex_draws);
    const pixel_draws = try allocator.alloc(PixelDrawData, scene.objects.len);
    errdefer allocator.free(pixel_draws);

    const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    const view = scene.camera.view();
    const projection = scene.camera.projection(aspect);

    var vertex_offset: usize = 0;
    var index_offset: usize = 0;
    for (scene.objects, 0..) |object, draw_index| {
        const object_vertex_offset = vertex_offset;
        const object_index_offset = index_offset;
        for (object.mesh.triangles) |triangle| {
            const tri_vertices = [_]usize{ triangle.a, triangle.b, triangle.c };
            const barycentrics = [_][3]f32{
                .{ 1, 0, 0 },
                .{ 0, 1, 0 },
                .{ 0, 0, 1 },
            };
            const edge_mask = triangleEdgeMask(object.mesh, triangle);
            const face_color = coplanarFaceColor(object.mesh, triangle);
            for (tri_vertices, barycentrics, 0..) |source_vertex_index, barycentric, i| {
                const vertex = object.mesh.vertices[source_vertex_index];
                vertices[vertex_offset + i] = .{
                    .position = .{ vertex.pos.x, vertex.pos.y, vertex.pos.z },
                    .uv = vertex.uv,
                    .barycentric = barycentric,
                    .edge_mask = edge_mask,
                    .color = face_color,
                };
                indices[index_offset + i] = @intCast(vertex_offset + i - object_vertex_offset);
            }
            vertex_offset += 3;
            index_offset += 3;
        }

        const mvp = Mat4.mul(projection, Mat4.mul(view, object.transform.matrix()));
        draws[draw_index] = .{
            .vertex_offset = @intCast(object_vertex_offset),
            .index_offset = @intCast(object_index_offset),
            .index_count = @intCast(object.mesh.triangles.len * 3),
            .material_index = 0,
        };
        vertex_draws[draw_index] = .{
            .mvp = mvp.m,
        };
        pixel_draws[draw_index] = .{
            .base_color = object.material.base_color,
            .shader_id = shaderId(object.material.shader),
            .wire_strength_bits = @bitCast(wireStrength(object.mesh)),
        };
    }

    return .{
        .vertices = vertices,
        .indices = indices,
        .draws = draws,
        .vertex_draws = vertex_draws,
        .pixel_draws = pixel_draws,
    };
}

fn coplanarFaceColor(mesh: mesh_mod.Mesh, triangle: mesh_mod.Triangle) u32 {
    if (mesh.triangles.len > 256) return color.averagePackedRgb(
        mesh.vertices[triangle.a].color,
        mesh.vertices[triangle.b].color,
        mesh.vertices[triangle.c].color,
    );

    const plane = trianglePlane(mesh, triangle);
    var r: u32 = 0;
    var g: u32 = 0;
    var b: u32 = 0;
    var count: u32 = 0;

    for (mesh.triangles) |other| {
        if (!samePlane(mesh, plane, trianglePlane(mesh, other))) continue;
        const indices = [_]usize{ other.a, other.b, other.c };
        for (indices) |index| {
            const packed_color = mesh.vertices[index].color;
            r += (packed_color >> 16) & 0xff;
            g += (packed_color >> 8) & 0xff;
            b += packed_color & 0xff;
            count += 1;
        }
    }

    if (count == 0) return color.averagePackedRgb(
        mesh.vertices[triangle.a].color,
        mesh.vertices[triangle.b].color,
        mesh.vertices[triangle.c].color,
    );
    return color.averageAccumulatedPackedRgb(r, g, b, count);
}

const Plane = struct {
    normal: math.Vec3,
    d: f32,
};

fn trianglePlane(mesh: mesh_mod.Mesh, triangle: mesh_mod.Triangle) Plane {
    const a = mesh.vertices[triangle.a].pos;
    const b = mesh.vertices[triangle.b].pos;
    const c = mesh.vertices[triangle.c].pos;
    const normal = math.Vec3.normalize(math.Vec3.cross(b.sub(a), c.sub(a)));
    return .{
        .normal = normal,
        .d = math.Vec3.dot(normal, a),
    };
}

fn samePlane(mesh: mesh_mod.Mesh, a: Plane, b: Plane) bool {
    _ = mesh;
    const parallel = math.Vec3.dot(a.normal, b.normal) > 0.999;
    return parallel and @abs(a.d - b.d) < 0.001;
}

fn triangleEdgeMask(mesh: mesh_mod.Mesh, triangle: mesh_mod.Triangle) [3]f32 {
    if (mesh.triangles.len > 256) return .{ 1, 1, 1 };

    const plane = trianglePlane(mesh, triangle);
    const edge_indices = [_][2]usize{
        .{ triangle.b, triangle.c },
        .{ triangle.a, triangle.c },
        .{ triangle.a, triangle.b },
    };
    var mask = [3]f32{ 1, 1, 1 };

    for (edge_indices, 0..) |edge, component| {
        for (mesh.triangles) |other| {
            if (other.a == triangle.a and other.b == triangle.b and other.c == triangle.c) continue;
            if (!samePlane(mesh, plane, trianglePlane(mesh, other))) continue;
            if (triangleHasEdge(other, edge[0], edge[1])) {
                mask[component] = 0;
                break;
            }
        }
    }
    return mask;
}

fn triangleHasEdge(triangle: mesh_mod.Triangle, a: usize, b: usize) bool {
    return (triangle.a == a or triangle.b == a or triangle.c == a) and
        (triangle.a == b or triangle.b == b or triangle.c == b);
}

pub fn updateFrameData(scene: *const scene_mod.Scene, width: u32, height: u32, vertex_draws: []VertexDrawData, pixel_draws: []PixelDrawData) !void {
    if (vertex_draws.len != scene.objects.len or pixel_draws.len != scene.objects.len) return error.DrawCountMismatch;

    const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    const view = scene.camera.view();
    const projection = scene.camera.projection(aspect);

    for (scene.objects, 0..) |object, draw_index| {
        const mvp = Mat4.mul(projection, Mat4.mul(view, object.transform.matrix()));
        vertex_draws[draw_index] = .{
            .mvp = mvp.m,
        };
        pixel_draws[draw_index] = .{
            .base_color = object.material.base_color,
            .shader_id = shaderId(object.material.shader),
            .wire_strength_bits = @bitCast(wireStrength(object.mesh)),
        };
    }
}

fn shaderId(shader: scene_mod.Shader) u32 {
    return shader.id;
}

fn wireStrength(mesh: mesh_mod.Mesh) f32 {
    return if (mesh.triangles.len > 256) 0.04 else 0.38;
}
