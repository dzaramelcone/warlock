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

pub const Sampler = struct {
    mag_filter: Filter = .linear,
    min_filter: Filter = .linear,
    mipmap_mode: MipmapMode = .linear,
    address_mode: AddressMode = .repeat,
};
