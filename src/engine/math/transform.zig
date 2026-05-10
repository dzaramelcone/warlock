const Vec3 = @import("vec3.zig").Vec3;
const Quat = @import("quat.zig").Quat;
const Mat4 = @import("mat4.zig").Mat4;

pub const Transform = struct {
    position: Vec3 = Vec3.zero,
    rotation: Quat = Quat.identity(),
    scale: Vec3 = Vec3.one,

    pub fn matrix(self: Transform) Mat4 {
        return Mat4.mul(Mat4.translation(self.position), Mat4.mul(self.rotation.toMat4(), Mat4.scale(self.scale)));
    }
};
