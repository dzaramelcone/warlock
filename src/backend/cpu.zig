const std = @import("std");
const backend_mod = @import("mod.zig");
const config = @import("../config.zig");
const game = @import("../game.zig");
const math = @import("../math.zig");

const Mat4 = math.Mat4;
const Vec3 = math.Vec3;

const Vertex = struct {
    pos: Vec3,
    color: u32,
};

const Triangle = struct {
    a: usize,
    b: usize,
    c: usize,
};

const ScreenVertex = struct {
    x: f32,
    y: f32,
    z: f32,
    color: u32,
};

const Mesh = struct {
    vertices: []const Vertex,
    triangles: []const Triangle,
};

const cube_vertices = [_]Vertex{
    .{ .pos = .{ .x = -1, .y = -1, .z = -1 }, .color = 0x00D85A4F },
    .{ .pos = .{ .x = 1, .y = -1, .z = -1 }, .color = 0x00E6A13A },
    .{ .pos = .{ .x = 1, .y = 1, .z = -1 }, .color = 0x00F4D35E },
    .{ .pos = .{ .x = -1, .y = 1, .z = -1 }, .color = 0x0074B3CE },
    .{ .pos = .{ .x = -1, .y = -1, .z = 1 }, .color = 0x004A8FE7 },
    .{ .pos = .{ .x = 1, .y = -1, .z = 1 }, .color = 0x0060D394 },
    .{ .pos = .{ .x = 1, .y = 1, .z = 1 }, .color = 0x00D66BA0 },
    .{ .pos = .{ .x = -1, .y = 1, .z = 1 }, .color = 0x008E7DBE },
};

const cube_tris = [_]Triangle{
    .{ .a = 0, .b = 2, .c = 1 }, .{ .a = 0, .b = 3, .c = 2 },
    .{ .a = 4, .b = 5, .c = 6 }, .{ .a = 4, .b = 6, .c = 7 },
    .{ .a = 0, .b = 1, .c = 5 }, .{ .a = 0, .b = 5, .c = 4 },
    .{ .a = 2, .b = 3, .c = 7 }, .{ .a = 2, .b = 7, .c = 6 },
    .{ .a = 1, .b = 2, .c = 6 }, .{ .a = 1, .b = 6, .c = 5 },
    .{ .a = 3, .b = 0, .c = 4 }, .{ .a = 3, .b = 4, .c = 7 },
};

const pyramid_vertices = [_]Vertex{
    .{ .pos = .{ .x = -1, .y = -1, .z = -1 }, .color = 0x00DB5461 },
    .{ .pos = .{ .x = 1, .y = -1, .z = -1 }, .color = 0x00FFD166 },
    .{ .pos = .{ .x = 1, .y = -1, .z = 1 }, .color = 0x0006D6A0 },
    .{ .pos = .{ .x = -1, .y = -1, .z = 1 }, .color = 0x00118AB2 },
    .{ .pos = .{ .x = 0, .y = 1, .z = 0 }, .color = 0x00FFFFFF },
};

const pyramid_tris = [_]Triangle{
    .{ .a = 0, .b = 1, .c = 2 }, .{ .a = 0, .b = 2, .c = 3 },
    .{ .a = 0, .b = 4, .c = 1 },
    .{ .a = 1, .b = 4, .c = 2 },
    .{ .a = 2, .b = 4, .c = 3 },
    .{ .a = 3, .b = 4, .c = 0 },
};

pub const Renderer = struct {
    depth: [config.WIDTH * config.HEIGHT]f32 = undefined,

    pub fn backend(self: *Renderer) backend_mod.Backend {
        return .{ .ptr = self, .vtable = &vtable };
    }

    pub fn render(self: *Renderer, pixels: *[config.WIDTH * config.HEIGHT]u32, state: *const game.State) void {
        self.clear(pixels, 0x00101418);

        const view = Mat4.lookAt(.{ .x = 0, .y = 1.7, .z = -7.0 }, .{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 1, .z = 0 });
        const proj = Mat4.perspective(math.radians(65.0), @as(f32, @floatFromInt(config.WIDTH)) / @as(f32, @floatFromInt(config.HEIGHT)), 0.1, 100.0);

        const cube = Mesh{ .vertices = &cube_vertices, .triangles = &cube_tris };
        const pyramid = Mesh{ .vertices = &pyramid_vertices, .triangles = &pyramid_tris };

        const cube_model = Mat4.mul(Mat4.translation(.{ .x = -1.6, .y = 0, .z = 0 }), Mat4.mul(Mat4.rotationY(state.cube_angle), Mat4.rotationX(state.cube_angle * 0.6)));
        const pyramid_model = Mat4.mul(Mat4.translation(.{ .x = 1.7, .y = 0.1, .z = 0.4 }), Mat4.mul(Mat4.rotationY(state.pyramid_angle), Mat4.rotationX(0.25)));

        self.drawMesh(pixels, cube, Mat4.mul(proj, Mat4.mul(view, cube_model)));
        self.drawMesh(pixels, pyramid, Mat4.mul(proj, Mat4.mul(view, pyramid_model)));
    }

    fn drawMesh(self: *Renderer, pixels: *[config.WIDTH * config.HEIGHT]u32, mesh: Mesh, mvp: Mat4) void {
        var transformed: [16]ScreenVertex = undefined;
        for (mesh.vertices, 0..) |vertex, i| {
            const clip = mvp.transform(.{ .x = vertex.pos.x, .y = vertex.pos.y, .z = vertex.pos.z, .w = 1 });
            if (clip.w <= 0.001) {
                transformed[i] = .{ .x = -10000, .y = -10000, .z = 1, .color = vertex.color };
                continue;
            }
            const inv_w = 1.0 / clip.w;
            const ndc_x = clip.x * inv_w;
            const ndc_y = clip.y * inv_w;
            const ndc_z = clip.z * inv_w;
            transformed[i] = .{
                .x = (ndc_x * 0.5 + 0.5) * @as(f32, @floatFromInt(config.WIDTH)),
                .y = (1.0 - (ndc_y * 0.5 + 0.5)) * @as(f32, @floatFromInt(config.HEIGHT)),
                .z = ndc_z,
                .color = vertex.color,
            };
        }

        for (mesh.triangles) |tri| {
            self.drawTriangle(pixels, transformed[tri.a], transformed[tri.b], transformed[tri.c]);
        }
    }

    fn drawTriangle(self: *Renderer, pixels: *[config.WIDTH * config.HEIGHT]u32, a: ScreenVertex, b: ScreenVertex, c: ScreenVertex) void {
        const area = edge(a.x, a.y, b.x, b.y, c.x, c.y);
        if (area <= 0.0) return;

        const min_x = clampInt(@intFromFloat(@floor(@min(a.x, @min(b.x, c.x)))), 0, config.WIDTH - 1);
        const max_x = clampInt(@intFromFloat(@ceil(@max(a.x, @max(b.x, c.x)))), 0, config.WIDTH - 1);
        const min_y = clampInt(@intFromFloat(@floor(@min(a.y, @min(b.y, c.y)))), 0, config.HEIGHT - 1);
        const max_y = clampInt(@intFromFloat(@ceil(@max(a.y, @max(b.y, c.y)))), 0, config.HEIGHT - 1);

        var y = min_y;
        while (y <= max_y) : (y += 1) {
            var x = min_x;
            while (x <= max_x) : (x += 1) {
                const px = @as(f32, @floatFromInt(x)) + 0.5;
                const py = @as(f32, @floatFromInt(y)) + 0.5;
                const w0 = edge(b.x, b.y, c.x, c.y, px, py);
                const w1 = edge(c.x, c.y, a.x, a.y, px, py);
                const w2 = edge(a.x, a.y, b.x, b.y, px, py);
                if (w0 >= 0 and w1 >= 0 and w2 >= 0) {
                    const inv_area = 1.0 / area;
                    const z = (w0 * a.z + w1 * b.z + w2 * c.z) * inv_area;
                    const idx = @as(usize, @intCast(y * config.WIDTH + x));
                    if (z < self.depth[idx]) {
                        self.depth[idx] = z;
                        pixels[idx] = mixColor(a.color, b.color, c.color, w0 * inv_area, w1 * inv_area, w2 * inv_area);
                    }
                }
            }
        }
    }

    fn clear(self: *Renderer, pixels: *[config.WIDTH * config.HEIGHT]u32, color: u32) void {
        @memset(pixels, color);
        @memset(&self.depth, std.math.inf(f32));
    }
};

const vtable = backend_mod.Backend.VTable{
    .name = "CPU software rasterizer",
    .deinit = deinitBackend,
    .render = renderBackend,
};

fn deinitBackend(_: *anyopaque) void {}

fn renderBackend(ptr: *anyopaque, frame: *backend_mod.Frame, state: *const game.State) !void {
    const self: *Renderer = @ptrCast(@alignCast(ptr));
    self.render(frame.pixels, state);
}

fn edge(ax: f32, ay: f32, bx: f32, by: f32, px: f32, py: f32) f32 {
    return (px - ax) * (by - ay) - (py - ay) * (bx - ax);
}

fn mixColor(a: u32, b: u32, c: u32, wa: f32, wb: f32, wc: f32) u32 {
    const ar: f32 = @floatFromInt((a >> 16) & 0xff);
    const ag: f32 = @floatFromInt((a >> 8) & 0xff);
    const ab: f32 = @floatFromInt(a & 0xff);
    const br: f32 = @floatFromInt((b >> 16) & 0xff);
    const bg: f32 = @floatFromInt((b >> 8) & 0xff);
    const bb: f32 = @floatFromInt(b & 0xff);
    const cr: f32 = @floatFromInt((c >> 16) & 0xff);
    const cg: f32 = @floatFromInt((c >> 8) & 0xff);
    const cb: f32 = @floatFromInt(c & 0xff);
    const r: u32 = @intFromFloat(ar * wa + br * wb + cr * wc);
    const g: u32 = @intFromFloat(ag * wa + bg * wb + cg * wc);
    const bl: u32 = @intFromFloat(ab * wa + bb * wb + cb * wc);
    return (r << 16) | (g << 8) | bl;
}

fn clampInt(value: i32, low: i32, high: i32) i32 {
    return @max(low, @min(high, value));
}
