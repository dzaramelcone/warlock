const math = @import("../math/mod.zig");
const mesh_mod = @import("../asset/mesh.zig");
const images = @import("../images/mod.zig");

const Mat4 = math.Mat4;
const Mesh = mesh_mod.Mesh;
const Transform = math.Transform;
const Vec3 = math.Vec3;

pub const Camera = struct {
    eye: Vec3,
    target: Vec3,
    up: Vec3 = Vec3.up,
    fov_y_radians: f32,
    near: f32,
    far: f32,

    pub fn view(self: Camera) Mat4 {
        return Mat4.lookAt(self.eye, self.target, self.up);
    }

    pub fn projection(self: Camera, aspect: f32) Mat4 {
        return Mat4.perspective(self.fov_y_radians, aspect, self.near, self.far);
    }
};

pub const Object = struct {
    mesh: Mesh,
    material: Material,
    transform: Transform,
};

pub const Material = struct {
    shader: Shader,
    base_color: u32 = 0x00ffffff,
    texture: ?images.texture.Ref = null,
};

pub const Shader = struct {
    vertex_path: []const u8,
    fragment_path: []const u8,
    id: u32 = 0,
};

pub const Scene = struct {
    camera: Camera,
    objects: []const Object,
    time: f32 = 0,
};
