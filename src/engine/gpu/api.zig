const std = @import("std");
const scene_data = @import("scene_data.zig");

pub const GpuPipeline = opaque {};
pub const GpuRenderPass = opaque {};
pub const GpuTexture = opaque {};
pub const GpuIndexedVertexData = opaque {};
pub const GpuVertexDrawData = opaque {};
pub const GpuPixelDrawData = opaque {};
pub const GpuDepthStencilState = opaque {};
pub const GpuBlendState = opaque {};
pub const GpuQueue = opaque {};
pub const GpuCommandBuffer = opaque {};
pub const GpuSemaphore = opaque {};

pub const Memory = enum(u32) {
    default,
    gpu,
    readback,
};

pub const Cull = enum(u32) {
    ccw,
    cw,
    all,
    none,
};

pub const DepthFlags = packed struct(u32) {
    read: bool = false,
    write: bool = false,
    _reserved: u30 = 0,
};

pub const Op = enum(u32) {
    never,
    less,
    equal,
    less_equal,
    greater,
    not_equal,
    greater_equal,
    always,
};

pub const Blend = enum(u32) {
    add,
    subtract,
    reverse_subtract,
    min,
    max,
};

pub const Factor = enum(u32) {
    zero,
    one,
    src_color,
    dst_color,
    src_alpha,
    dst_alpha,
    one_minus_src_color,
    one_minus_dst_color,
    one_minus_src_alpha,
    one_minus_dst_alpha,
};

pub const Topology = enum(u32) {
    triangle_list,
    triangle_strip,
    triangle_fan,
};

pub const TextureType = enum(u32) {
    @"1d",
    @"2d",
    @"3d",
    cube,
    @"2d_array",
    cube_array,
};

pub const Format = enum(u32) {
    none,
    rgba8_unorm,
    d32_float,
    rg11b10_float,
    rgb10_a2_unorm,
    bgra8_unorm,
};

pub const UsageFlags = packed struct(u32) {
    sampled: bool = false,
    storage: bool = false,
    color_attachment: bool = false,
    depth_stencil_attachment: bool = false,
    transfer_src: bool = false,
    transfer_dst: bool = false,
    _reserved: u26 = 0,
};

pub const Stage = enum(u32) {
    transfer,
    compute,
    raster_color_out,
    pixel_shader,
    vertex_shader,
};

pub const HazardFlags = packed struct(u32) {
    draw_arguments: bool = false,
    descriptors: bool = false,
    depth_stencil: bool = false,
    _reserved: u29 = 0,
};

pub const Signal = enum(u32) {
    atomic_set,
    atomic_max,
    atomic_or,
};

pub const UVec3 = extern struct {
    x: u32 = 1,
    y: u32 = 1,
    z: u32 = 1,
};

pub const Stencil = extern struct {
    test_op: Op = .always,
    fail_op: Op = .always,
    pass_op: Op = .always,
    depth_fail_op: Op = .always,
    reference: u8 = 0,
};

pub const GpuDepthStencilDesc = extern struct {
    depth_mode: DepthFlags = .{},
    depth_test: Op = .always,
    depth_bias: f32 = 0.0,
    depth_bias_slope_factor: f32 = 0.0,
    depth_bias_clamp: f32 = 0.0,
    stencil_read_mask: u8 = 0xff,
    stencil_write_mask: u8 = 0xff,
    stencil_front: Stencil = .{},
    stencil_back: Stencil = .{},
};

pub const GpuBlendDesc = extern struct {
    color_op: Blend = .add,
    src_color_factor: Factor = .one,
    dst_color_factor: Factor = .zero,
    alpha_op: Blend = .add,
    src_alpha_factor: Factor = .one,
    dst_alpha_factor: Factor = .zero,
    color_write_mask: u8 = 0xf,
};

pub const ColorTarget = extern struct {
    format: Format = .none,
    write_mask: u8 = 0xf,
};

pub const ColorTargetSpan = extern struct {
    ptr: ?[*]const ColorTarget = null,
    len: usize = 0,
};

pub const GpuRasterDesc = extern struct {
    topology: Topology = .triangle_list,
    cull: Cull = .none,
    alpha_to_coverage: bool = false,
    support_dual_source_blending: bool = false,
    sample_count: u8 = 1,
    depth_format: Format = .none,
    stencil_format: Format = .none,
    color_targets: ColorTargetSpan = .{},
    blend_state: ?*const GpuBlendDesc = null,
};

pub const GpuTextureDesc = extern struct {
    type: TextureType = .@"2d",
    dimensions: UVec3 = .{},
    mip_count: u32 = 1,
    layer_count: u32 = 1,
    sample_count: u32 = 1,
    format: Format = .none,
    usage: UsageFlags = .{},
};

pub const GpuViewDesc = extern struct {
    format: Format = .none,
    base_mip: u8 = 0,
    mip_count: u8 = all_mips,
    base_layer: u16 = 0,
    layer_count: u16 = all_layers,
};

pub const GpuTextureSizeAlign = extern struct {
    size: usize,
    alignment: usize,
};

pub const GpuTextureDescriptor = extern struct {
    data: [4]u64,
};

pub const GpuRenderPassDesc = extern struct {
    color_targets: ColorTargetSpan = .{},
    depth_target: Format = .none,
    clear_color: [4]f32 = .{ 0, 0, 0, 1 },
    clear_depth: f32 = 1,
    render_pass: ?*GpuRenderPass = null,
};

pub const ByteSpan = []const u8;

pub const all_mips: u8 = std.math.maxInt(u8);
pub const all_layers: u16 = std.math.maxInt(u16);

pub fn Api(comptime Backend: type) type {
    return struct {
        pub const Graphics = Backend.Graphics;
        pub const Commands = Backend.GraphicsCommands;
        pub const SceneResources = Backend.SceneResources;
        pub const RenderPass = Backend.ScenePipeline;
        pub const Pipeline = Backend.ScenePipeline;
        pub const IndexedVertexData = Backend.SceneBuffers;
        pub const VertexDrawData = scene_data.VertexDrawData;
        pub const PixelDrawData = scene_data.PixelDrawData;

        pub fn beginRenderPass(commands: *Commands, render_pass: *RenderPass, clear_color: [4]f32) !void {
            try commands.beginRenderPass(render_pass, clear_color);
        }

        pub fn endRenderPass(commands: *Commands) !void {
            try commands.endRenderPass();
        }

        pub fn setPipeline(commands: *Commands, pipeline: *Pipeline) !void {
            try commands.setPipeline(pipeline);
        }

        pub fn setIndexedVertexData(commands: *Commands, vertex_data: *IndexedVertexData) !void {
            try commands.setIndexedVertexData(vertex_data);
        }

        pub fn setVertexDrawData(commands: *Commands, data: *VertexDrawData) !void {
            try commands.setVertexDrawData(data);
        }

        pub fn setPixelDrawData(commands: *Commands, data: *PixelDrawData) !void {
            try commands.setPixelDrawData(data);
        }

        pub fn drawIndexedInstanced(commands: *Commands, first_index: u32, index_count: u32, vertex_offset: i32, instance_count: u32) !void {
            try commands.drawIndexedInstanced(first_index, index_count, vertex_offset, instance_count);
        }
    };
}
