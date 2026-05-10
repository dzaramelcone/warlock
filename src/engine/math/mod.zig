const std = @import("std");

pub const Vec3 = @import("vec3.zig").Vec3;
pub const Mat4 = @import("mat4.zig").Mat4;
pub const Vec4 = @import("mat4.zig").Vec4;
pub const Quat = @import("quat.zig").Quat;
pub const Transform = @import("transform.zig").Transform;

pub fn radians(degrees: f32) f32 {
    return std.math.degreesToRadians(degrees);
}
