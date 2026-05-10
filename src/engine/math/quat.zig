const Vec3 = @import("vec3.zig").Vec3;
const Mat4 = @import("mat4.zig").Mat4;

pub const Quat = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn identity() Quat {
        return .{ .x = 0, .y = 0, .z = 0, .w = 1 };
    }

    pub fn axisAngle(axis: Vec3, angle: f32) Quat {
        const unit_axis = Vec3.normalize(axis);
        const half = angle * 0.5;
        const s = @sin(half);
        return normalize(.{
            .x = unit_axis.x * s,
            .y = unit_axis.y * s,
            .z = unit_axis.z * s,
            .w = @cos(half),
        });
    }

    pub fn mul(a: Quat, b: Quat) Quat {
        return .{
            .x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            .y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            .z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
            .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
        };
    }

    pub fn normalize(q: Quat) Quat {
        const len = @sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
        if (len == 0.0) return identity();
        const inv_len = 1.0 / len;
        return .{ .x = q.x * inv_len, .y = q.y * inv_len, .z = q.z * inv_len, .w = q.w * inv_len };
    }

    pub fn rotateVec3(q_unnormalized: Quat, v: Vec3) Vec3 {
        const q = normalize(q_unnormalized);
        const u: Vec3 = .{ .x = q.x, .y = q.y, .z = q.z };
        return Vec3.add(
            Vec3.add(
                Vec3.scale(u, 2.0 * Vec3.dot(u, v)),
                Vec3.scale(v, q.w * q.w - Vec3.dot(u, u)),
            ),
            Vec3.scale(Vec3.cross(u, v), 2.0 * q.w),
        );
    }

    pub fn toMat4(q_unnormalized: Quat) Mat4 {
        const q = normalize(q_unnormalized);
        const xx = q.x * q.x;
        const yy = q.y * q.y;
        const zz = q.z * q.z;
        const xy = q.x * q.y;
        const xz = q.x * q.z;
        const yz = q.y * q.z;
        const wx = q.w * q.x;
        const wy = q.w * q.y;
        const wz = q.w * q.z;

        return .{ .m = .{
            1.0 - 2.0 * (yy + zz), 2.0 * (xy - wz), 2.0 * (xz + wy), 0,
            2.0 * (xy + wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz - wx), 0,
            2.0 * (xz - wy), 2.0 * (yz + wx), 1.0 - 2.0 * (xx + yy), 0,
            0, 0, 0, 1,
        } };
    }
};
