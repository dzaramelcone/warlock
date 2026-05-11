const images = @import("../images/mod.zig");

pub const ShaderBytes = struct {
    vertex: []const u8,
    fragment: []const u8,
};

pub const TextureBytes = struct {
    pub const Level = images.texture.MipLevel;

    pub const Filter = enum {
        nearest,
        linear,
    };

    pub const MipmapMode = enum {
        nearest,
        linear,
    };

    pub const AddressMode = enum {
        repeat,
        clamp_to_edge,
    };

    width: u32,
    height: u32,
    rgba: []const u8,
    levels: []const Level,
    mag_filter: Filter = .linear,
    min_filter: Filter = .linear,
    mipmap_mode: MipmapMode = .linear,
    address_mode: AddressMode = .repeat,
};
