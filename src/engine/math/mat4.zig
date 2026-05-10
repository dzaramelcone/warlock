const Vec3 = @import("vec3.zig").Vec3;

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Mat4 = struct {
    m: [16]f32,

    pub fn identity() Mat4 {
        return .{ .m = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        } };
    }

    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var out: [16]f32 = undefined;
        for (0..4) |row| {
            for (0..4) |col| {
                out[row * 4 + col] =
                    a.m[row * 4 + 0] * b.m[col + 0] +
                    a.m[row * 4 + 1] * b.m[col + 4] +
                    a.m[row * 4 + 2] * b.m[col + 8] +
                    a.m[row * 4 + 3] * b.m[col + 12];
            }
        }
        return .{ .m = out };
    }

    pub fn transform(m: Mat4, v: Vec4) Vec4 {
        return .{
            .x = m.m[0] * v.x + m.m[1] * v.y + m.m[2] * v.z + m.m[3] * v.w,
            .y = m.m[4] * v.x + m.m[5] * v.y + m.m[6] * v.z + m.m[7] * v.w,
            .z = m.m[8] * v.x + m.m[9] * v.y + m.m[10] * v.z + m.m[11] * v.w,
            .w = m.m[12] * v.x + m.m[13] * v.y + m.m[14] * v.z + m.m[15] * v.w,
        };
    }

    pub fn translation(v: Vec3) Mat4 {
        var out = identity();
        out.m[3] = v.x;
        out.m[7] = v.y;
        out.m[11] = v.z;
        return out;
    }

    pub fn scale(v: Vec3) Mat4 {
        return .{ .m = .{
            v.x, 0, 0, 0,
            0, v.y, 0, 0,
            0, 0, v.z, 0,
            0, 0, 0, 1,
        } };
    }

    pub fn perspective(fov_y: f32, aspect: f32, near: f32, far: f32) Mat4 {
        const f = 1.0 / @tan(fov_y * 0.5);
        return .{ .m = .{
            f / aspect, 0, 0, 0,
            0, f, 0, 0,
            0, 0, far / (far - near), (-near * far) / (far - near),
            0, 0, 1, 0,
        } };
    }

    pub fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
        const zaxis = Vec3.normalize(target.sub(eye));
        const xaxis = Vec3.normalize(Vec3.cross(up, zaxis));
        const yaxis = Vec3.cross(zaxis, xaxis);

        return .{ .m = .{
            xaxis.x, xaxis.y, xaxis.z, -Vec3.dot(xaxis, eye),
            yaxis.x, yaxis.y, yaxis.z, -Vec3.dot(yaxis, eye),
            zaxis.x, zaxis.y, zaxis.z, -Vec3.dot(zaxis, eye),
            0, 0, 0, 1,
        } };
    }
};
