const std = @import("std");

pub const Vertex = extern struct {
    position: [3]f32,
    uv: [2]f32,
    barycentric: [3]f32,
    edge_mask: [3]f32,
    color: u32,
};

pub const Draw = extern struct {
    vertex_offset: u32,
    index_offset: u32,
    index_count: u32,
    material_index: u32,
};

pub const VertexDrawData = extern struct {
    mvp: [16]f32,
};

pub const PixelDrawData = extern struct {
    base_color: u32,
    shader_id: u32,
    wire_strength_bits: u32 = 0,
    _pad1: u32 = 0,
};

pub const Packet = struct {
    vertices: []Vertex,
    indices: []u32,
    draws: []Draw,
    vertex_draws: []VertexDrawData,
    pixel_draws: []PixelDrawData,

    pub fn deinit(self: Packet, allocator: std.mem.Allocator) void {
        allocator.free(self.pixel_draws);
        allocator.free(self.vertex_draws);
        allocator.free(self.draws);
        allocator.free(self.indices);
        allocator.free(self.vertices);
    }
};
